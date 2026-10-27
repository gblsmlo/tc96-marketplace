#!/usr/bin/env bash
# contract-write self-check: the structure of one feature's contract.md, against its story.md.
#   bash self-check.sh <feature-folder>
# Exit 0 when every probe passes; 1 when any fails; 2 on a missing file.
set -uo pipefail
DIR="${1:?usage: self-check.sh <feature-folder>}"
[ -f "$DIR/contract.md" ] || { echo "FAIL: no contract.md in $DIR"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "SKIPPED: needs python3 on PATH"; exit 0; }

python3 - "$DIR" <<'PY'
import re, sys, pathlib

folder = pathlib.Path(sys.argv[1])
text = (folder / "contract.md").read_text(encoding="utf-8")
LANES = ["design", "frontend", "backend", "ai", "devops", "tooling", "qa"]
GATES = ["static", "unit", "contract", "integration", "component", "e2e", "manual", "review"]
fails = []

def probe(title, problems):
    print(f"[{'ok  ' if not problems else 'FAIL'}] {title}")
    for p in problems[:8]:
        print(f"       {p}")
    if problems:
        fails.append(title)

m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
front = m.group(1) if m else ""
body = text[m.end():] if m else text

def field(name):
    f = re.search(rf"^{name}:\s*(.*)$", front, re.M)
    return f.group(1).strip() if f else None

required = ["feature", "traces", "risk", "base", "owner", "surface", "size", "lanes", "status"]
probe("frontmatter has every field", [f"missing `{k}`" for k in required if field(k) is None])
probe("status is Draft or Approved", [] if field("status") in ("Draft", "Approved") else [f"status: {field('status')}"])
probe("owner is one code role", [] if field("owner") in ("frontend-developer", "backend-developer") else [f"owner: {field('owner')}"])

traces = re.findall(r"AC-\d+", field("traces") or "")
probe("traces names at least one AC-*", [] if traces else ["traces is empty"])

surface = re.findall(r"^\s+-\s+(\S.*)$", front.split("surface:", 1)[1].split("\nsize:", 1)[0], re.M) if "surface:" in front else []
probe("surface lists at least one path", [] if surface or re.search(r"surface:\s*\[.+\]", front) else ["surface is empty"])

size = re.search(r"\d+", field("size") or "")
probe("size fits the 300-line budget", [] if size and int(size.group()) <= 300 else [f"size: {field('size')} — split the feature in the PRD by AC"])

lanes = {}
block = front.split("lanes:", 1)[1] if "lanes:" in front else ""
for line in block.splitlines()[1:]:
    lm = re.match(r"^\s+(\w+):\s*(.*?)\s*(#.*)?$", line)
    if not lm:
        break
    lanes[lm.group(1)] = lm.group(2)
probe("lane map names the seven lanes", [f"missing lane `{l}`" for l in LANES if l not in lanes] + [f"unknown lane `{l}`" for l in lanes if l not in LANES])

def kind(v):
    return "large" if "large" in v else "small" if "small" in v else "none" if "none" in v else "?"

bad = []
for l, v in lanes.items():
    k = kind(v)
    if k == "?":
        bad.append(f"{l}: `{v}` is not none, small or large")
    if k == "large":
        n = re.search(r"lines:\s*(\d+)", v)
        if l == "tooling":
            bad.append("tooling is never large (default D5)")
        elif not n or int(n.group(1)) <= 150:
            bad.append(f"{l} is large but its lines are not above 150 (default D4)")
probe("lane sizes follow D4 and D5", bad)

checks = re.findall(r"^- \[[ x]\] \*\*(C\d+)\*\* \((AC-\d+|—)\)(.*)$", body, re.M)
probe("at least one C-check", [] if checks else ["no line of the form `- [ ] **C1** (AC-NN) ...`"])

line_bad = []
for cid, ac, rest in checks:
    g = re.search(r"·\s*`(\w+)`\s*$", rest)
    ln = re.search(r"·\s*lane\s*`(\w+)`", rest)
    if not g or g.group(1) not in GATES:
        line_bad.append(f"{cid}: gate type missing or not last")
    if not ln or ln.group(1) not in LANES:
        line_bad.append(f"{cid}: lane tag missing or unknown")
    elif kind(lanes.get(ln.group(1), "none")) == "none":
        line_bad.append(f"{cid}: lane `{ln.group(1)}` is `none` in the lane map")
    if ac != "—" and ac not in traces:
        line_bad.append(f"{cid}: {ac} is not in traces")
probe("every check: traced AC, known lane, gate type last", line_bad)

used = {re.search(r"lane\s*`(\w+)`", r).group(1) for _, _, r in checks if re.search(r"lane\s*`(\w+)`", r)}
idle = [l for l, v in lanes.items() if kind(v) != "none" and l not in used and l != "design"]
probe("every code lane with work has a check", [f"{l} is {kind(lanes[l])} but no check is tagged with it" for l in idle])

proved = {ac for _, ac, _ in checks}
probe("every traced AC-* has a check", [f"{a} has no check" for a in traces if a not in proved])

gates = set(re.findall(r"^- \[[ x]\] \*\*(G\d)\*\*", body, re.M))
want = {"G1", "G2"} | ({"G3"} if field("risk") == "security" else set())
probe("non-functional gates match the risk", [f"missing {g}" for g in sorted(want - gates)] + (["G3 listed but risk is not security"] if "G3" in gates and field("risk") != "security" else []))

mw = re.search(r"^Met when:(.*)$", body, re.M)
mw_bad = []
if not mw:
    mw_bad.append("no `Met when:` line")
else:
    for a in traces:
        if a not in mw.group(1):
            mw_bad.append(f"{a} missing from Met when")
    ids = {c for c, _, _ in checks}
    for c in re.findall(r"\bC\d+\b", mw.group(1)):
        if c not in ids:
            mw_bad.append(f"Met when cites {c}, which is not a check")
probe("Met when names every traced AC-* and only real checks", mw_bad)

story = folder / "story.md"
if story.exists():
    acs = set(re.findall(r"^\|\s*(AC-\d+)\s*\|", story.read_text(encoding="utf-8"), re.M))
    probe("traces equals story.md's AC-*", [f"{a} in story.md, not in traces" for a in sorted(acs - set(traces))] + [f"{a} in traces, not in story.md" for a in sorted(set(traces) - acs)])
else:
    print("[skip] traces equals story.md's AC-*: no story.md yet")

sys.exit(1 if fails else 0)
PY
