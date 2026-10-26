#!/usr/bin/env bash
# story-write self-check: one feature's story.md against the PRD.
#   bash self-check.sh <feature-folder> [path/to/PRD.md]
# Exit 0 when every probe passes; 1 when any fails; 2 on a missing file.
set -uo pipefail
DIR="${1:?usage: self-check.sh <feature-folder> [PRD.md]}"
PRD="${2:-.specs/PRD.md}"
[ -f "$DIR/story.md" ] || { echo "FAIL: no story.md in $DIR"; exit 2; }
[ -f "$PRD" ] || { echo "FAIL: no PRD at $PRD"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "SKIPPED: needs python3 on PATH"; exit 0; }

python3 - "$DIR" "$PRD" <<'PY'
import re, sys, pathlib

folder, prd_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
story = (folder / "story.md").read_text(encoding="utf-8")
prd = prd_path.read_text(encoding="utf-8")
fails = []

def probe(title, problems):
    print(f"[{'ok  ' if not problems else 'FAIL'}] {title}")
    for p in problems[:8]:
        print(f"       {p}")
    if problems:
        fails.append(title)

m = re.match(r"^---\n(.*?)\n---\n", story, re.S)
front = m.group(1) if m else ""
body = story[m.end():] if m else story
feature = (re.search(r"^feature:\s*(\S+)", front, re.M) or [None, ""])[1]
fid = (re.match(r"(F\d+(?:\.\d+)?)", feature) or [None, ""])[1]

probe("frontmatter has feature, prd, status", [f"missing `{k}`" for k in ("feature", "prd", "status") if not re.search(rf"^{k}:", front, re.M)])
probe("status is Draft or Approved", [] if re.search(r"^status:\s*(Draft|Approved)\s*$", front, re.M) else ["status is not Draft or Approved"])
probe("feature matches the folder name", [] if feature and feature == folder.name else [f"feature `{feature}` vs folder `{folder.name}`"])
probe("one story sentence, As … I … so that …", [] if re.search(r"^>\s*As .+, I .+, so that .+", body, re.M | re.I) else ["no `> As [who], I [do what], so that [outcome].` line"])

acs = re.findall(r"^\|\s*(AC-\d+)\s*\|", body, re.M)
defect = re.search(r"^\|\s*—\s*defect:", body, re.M)
probe("lists at least one AC-*, or the fast-lane defect row", [] if acs or defect else ["no AC row in the table"])
probe("every AC-* exists in the PRD", [f"{a} is not in {prd_path}" for a in acs if not re.search(rf"\b{a}\b", prd)])

base = fid.split(".")[0]
row = [l for l in prd.splitlines() if re.search(rf"\b{base}\b", l) and "AC-" in l]
if row:
    assigned = set(re.findall(r"AC-\d+", " ".join(row)))
    probe(f"AC-* match what the PRD assigns to {base}", [f"{a} assigned in the PRD, missing here" for a in sorted(assigned - set(acs))] + [f"{a} listed here, not assigned to {base}" for a in sorted(set(acs) - assigned)])
else:
    print(f"[skip] AC-* match the PRD: no PRD line names {base} together with an AC-*")

gwt = re.findall(r"^(?!>).*\b(Given|When|Then)\b.*$", body, re.M)
probe("no Given / When / Then copied from the PRD (default D9)", [f"line uses `{w}`" for w in gwt])

sys.exit(1 if fails else 0)
PY
