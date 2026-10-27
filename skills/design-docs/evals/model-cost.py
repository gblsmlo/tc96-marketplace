"""Cost per model vs result, for one iteration of the design-docs evals.

Usage: python3 model-cost.py <workspace>/iteration-N   (layout in README.md)

Prices: Claude API list prices per 1M tokens (claude-api skill, cached 2026-10-06).
The run's token count is the subagent's cumulative total (every turn's context plus output),
with no input/output split. Output tokens are estimated from the bytes the run wrote (~4 bytes
per token); everything else is billed as uncached input. Real runs cache the system prompt, so
these figures are an upper bound; the ratio between models is what to read.
"""
import json
import pathlib
import sys

PRICE = {  # $ per 1M tokens: input, output
    "sonnet": (2.00, 10.00),
    "haiku": (0.10, 0.50),
}
CONFIGS = {"with_skill": "sonnet", "haiku_skill": "haiku"}
SKILL = {
    "prd-quote-approval": "doc-prd", "adr-sessions-postgres": "doc-adr",
    "adr-no-decision-blocked": "doc-adr", "epic-quote-approval": "doc-epic",
    "feature-from-prd-row": "doc-feature", "story-approve-quote": "doc-story",
    "tasks-from-spec": "doc-tasks", "bug-safari-approve": "doc-bug",
    "spec-approval-route": "doc-spec", "pr-from-diff": "doc-pr",
}
TIER = {"alto": "opus", "medio": "sonnet", "rapido": "haiku"}  # build/modelos.json, claude-code


def declared(skill: str) -> str:
    """The tier the skill's own frontmatter declares (`model:`), in Claude Code terms."""
    md = pathlib.Path(__file__).resolve().parent.parent / skill / "SKILL.md"
    for line in md.read_text().splitlines() if md.exists() else []:
        if line.startswith("model:"):
            return TIER.get(line.split(":", 1)[1].strip(), "?")
    return "?"


EVALS = pathlib.Path(__file__).resolve().parent
NOT_OUTPUT = {"_files-read.txt"}


def written_bytes(run: pathlib.Path, case: str) -> int:
    """Bytes the run wrote: everything under outputs/ except what the case's files/ placed there."""
    outputs, placed = run / "outputs", EVALS / case / "files"
    total = 0
    for f in outputs.rglob("*"):
        rel = f.relative_to(outputs)
        if f.is_file() and f.name not in NOT_OUTPUT and not (placed / rel).exists():
            total += f.stat().st_size
    return total


def one_run(run: pathlib.Path, model: str, case: str):
    g = json.loads((run / "grading.json").read_text())["summary"]
    t = json.loads((run / "timing.json").read_text())
    out = written_bytes(run, case) / 4
    pin, pout = PRICE[model]
    cost = ((t["total_tokens"] - out) * pin + out * pout) / 1e6
    return {"passed": g["passed"], "total": g["total"], "tokens": t["total_tokens"],
            "seconds": t["total_duration_seconds"], "cost": cost}


def run_row(config_dir: pathlib.Path, model: str):
    """One configuration of one case: its single run, or the mean of its run-N folders."""
    runs = sorted(d for d in config_dir.glob("run-*") if (d / "grading.json").exists())
    runs = runs or ([config_dir] if (config_dir / "grading.json").exists() else [])
    if not runs:
        return None
    rows = [one_run(r, model, config_dir.parent.name) for r in runs]
    mean = {k: sum(r[k] for r in rows) / len(rows) for k in ("tokens", "seconds", "cost")}
    return {"passed": sum(r["passed"] for r in rows), "total": sum(r["total"] for r in rows),
            "runs": len(rows), **mean}


def main(iteration: pathlib.Path):
    rows, agg = [], {m: {"passed": 0, "total": 0, "per_run": 0.0, "cost": 0.0, "tokens": 0, "seconds": 0.0}
                     for m in PRICE}
    for case_dir in sorted(p for p in iteration.iterdir() if p.is_dir()):
        r = {"case": case_dir.name, "skill": SKILL.get(case_dir.name, "?")}
        for cfg, model in CONFIGS.items():
            row = run_row(case_dir / cfg, model)
            if not row:
                continue
            r[model] = row
            for k in ("passed", "total"):
                agg[model][k] += row[k]
            agg[model]["per_run"] += row["passed"] / row["runs"]  # passed assertions in one run
            for k in ("tokens", "seconds", "cost"):
                agg[model][k] += row[k]
        rows.append(r)

    lines = ["## Cost per model vs result (with the skill)", "",
             "Same skill, same prompt, two models. Cost is an uncached upper bound from list prices "
             "(Sonnet 5.5 $2/$10, Haiku 5.5 $0.10/$0.50 per 1M input/output tokens); read the ratio, "
             "not the dollars.", "",
             "| Case | Skill | Declared | Sonnet pass | Haiku pass | Sonnet cost | Haiku cost | Sonnet s | Haiku s |",
             "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
    for r in rows:
        s, h = r.get("sonnet"), r.get("haiku")
        if not s or not h:
            continue
        lines.append(f"| {r['case']} | `{r['skill']}` | {declared(r['skill'])} | "
                     f"{s['passed']}/{s['total']} | {h['passed']}/{h['total']}"
                     f"{' (' + str(h['runs']) + ' runs)' if h['runs'] > 1 else ''} | "
                     f"${s['cost']:.4f} | ${h['cost']:.4f} | {s['seconds']:.0f} | {h['seconds']:.0f} |")
    s, h = agg["sonnet"], agg["haiku"]
    if s["total"] and h["total"]:
        lines += ["", "| Model | Pass rate | Cost per run of every case | Cost per passed assertion | Mean tokens | Mean seconds |",
                  "| --- | --- | --- | --- | --- | --- |"]
        n = len([r for r in rows if "sonnet" in r and "haiku" in r])
        for name, a in (("Sonnet 5.5", s), ("Haiku 5.5", h)):
            lines.append(f"| {name} | {a['passed'] / a['total']:.0%} ({a['passed']}/{a['total']}) | "
                         f"${a['cost']:.4f} | ${a['cost'] / max(a['per_run'], 1):.5f} | "
                         f"{a['tokens'] / n:,.0f} | {a['seconds'] / n:.0f} |")
        lines += ["", f"Haiku costs {s['cost'] / h['cost']:.0f}x less than Sonnet across these runs, "
                      f"for a pass-rate difference of {(s['passed'] / s['total'] - h['passed'] / h['total']) * 100:+.0f} points (Sonnet minus Haiku)."]
    text = "\n".join(lines) + "\n"
    (iteration / "model-cost.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main(pathlib.Path(sys.argv[1]))
