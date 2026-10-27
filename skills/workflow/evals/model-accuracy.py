"""Accuracy per model for the workflow evals: which main-session model can run each phase.

Usage: python3 model-accuracy.py [results-dir]   (default: results/ beside this file)

Reads every <results-dir>/<model>/result*.json that `run-evals.sh <model>` wrote (a tagged rerun's
cases replace the same cases of result.json) and writes
<results-dir>/model-accuracy.md: grader pass rate per case and per phase, cases fully passed,
mean cost and seconds per run, and the graders each model failed. Cost is what the eval run
reported for the agent under test (subagents included), apart from the judge's cost.
"""
import json
import pathlib
import sys

ORDER = ["haiku", "sonnet", "opus"]
PHASE = {"search": "workflow-search", "plan": "workflow-plan",
         "implementation": "workflow-implementation", "review": "workflow-review"}


def phase_of(case: str) -> str:
    return PHASE.get(case.split("-", 1)[0], "?")


def load(results: pathlib.Path) -> dict:
    """{model: {case: [run, ...]}}, each run with its graders."""
    out = {}
    # result.json first, then each tagged rerun by time: a later file's cases replace earlier ones
    for f in sorted(results.glob("*/result*.json"), key=lambda f: (f.name != "result.json", f.stat().st_mtime)):
        doc = json.loads(f.read_text())
        out.setdefault(f.parent.name, {}).update({c["name"]: c["arms"]["with"] for c in doc["cases"]})
    return out


def graders(runs: list) -> tuple[int, int]:
    passed = total = 0
    for r in runs:
        for g in r.get("graders", []):
            if g.get("scored", True):
                total += g.get("weight", 1)
                passed += g.get("weight", 1) if g.get("passed") else 0
    return passed, total


def mean(runs: list, key: str) -> float:
    vals = [r.get(key) or 0 for r in runs]
    return sum(vals) / len(vals) if vals else 0.0


def pct(p: int, t: int) -> str:
    return f"{p / t:.0%} ({p}/{t})" if t else "—"


def main(results: pathlib.Path) -> None:
    data = load(results)
    models = [m for m in ORDER if m in data] + sorted(m for m in data if m not in ORDER)
    if not models:
        sys.exit(f"no */result.json under {results}")
    cases = sorted({c for m in models for c in data[m]}, key=lambda c: (list(PHASE).index(c.split("-", 1)[0])
                                                                     if c.split("-", 1)[0] in PHASE else 9, c))
    lines = ["## Accuracy per main-session model", "",
             "Grader pass rate per case (passed graders / graders, summed over runs). The phase skill runs "
             "on the model named in the column; the agents it calls keep their own tier.", "",
             "| Case | Phase | " + " | ".join(models) + " |",
             "| --- | --- | " + " | ".join("---" for _ in models) + " |"]
    for c in cases:
        cells = [pct(*graders(data[m].get(c, []))) for m in models]
        lines.append(f"| {c} | `{phase_of(c)}` | " + " | ".join(cells) + " |")

    lines += ["", "| Phase | " + " | ".join(models) + " |", "| --- | " + " | ".join("---" for _ in models) + " |"]
    for ph in PHASE.values():
        cells = []
        for m in models:
            p = t = 0
            for c, runs in data[m].items():
                if phase_of(c) == ph:
                    a, b = graders(runs)
                    p, t = p + a, t + b
            cells.append(pct(p, t))
        lines.append(f"| `{ph}` | " + " | ".join(cells) + " |")

    lines += ["", "| Model | Graders passed | Runs with every grader passed | Mean cost per run | Mean judge cost per run | Mean seconds per run |",
              "| --- | --- | --- | --- | --- | --- |"]
    for m in models:
        runs = [r for rs in data[m].values() for r in rs]
        p = t = 0
        for rs in data[m].values():
            a, b = graders(rs)
            p, t = p + a, t + b
        full = sum(1 for r in runs if r.get("graders") and all(g.get("passed") for g in r["graders"] if g.get("scored", True)))
        lines.append(f"| {m} | {pct(p, t)} | {full}/{len(runs)} | ${mean(runs, 'costUsd'):.3f} | "
                     f"${mean(runs, 'judgeCostUsd'):.3f} | {mean(runs, 'durationSeconds'):.0f} |")

    lines += ["", "### Failed graders", ""]
    for m in models:
        fails = []
        for c in cases:
            for i, r in enumerate(data[m].get(c, []), 1):
                if r.get("error"):
                    fails.append(f"- `{c}` run {i}: error — {str(r['error'])[:160]}")
                for g in r.get("graders", []):
                    if g.get("scored", True) and not g.get("passed"):
                        fails.append(f"- `{c}` run {i}: `{g['name']}` — {(g.get('explanation') or '').splitlines()[0][:160]}")
        lines.append(f"**{m}**" + (": none" if not fails else ""))
        lines += fails + [""]
    text = "\n".join(lines).rstrip() + "\n"
    (results / "model-accuracy.md").write_text(text)
    print(text)


if __name__ == "__main__":
    here = pathlib.Path(__file__).resolve().parent
    main(pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else here / "results")
