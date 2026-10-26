#!/usr/bin/env bash
# spec-write self-check: one feature's spec.md, against its providers' spec.md and its contract.md.
#   bash self-check.sh <feature-folder>
# Exit 0 when every probe passes; 1 when any fails; 2 on a missing file.
set -uo pipefail
DIR="${1:?usage: self-check.sh <feature-folder>}"
[ -f "$DIR/spec.md" ] || { echo "FAIL: no spec.md in $DIR"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "SKIPPED: needs python3 on PATH"; exit 0; }

python3 - "$DIR" <<'PY'
import re, sys, pathlib

folder = pathlib.Path(sys.argv[1])
text = (folder / "spec.md").read_text(encoding="utf-8")
fails = []

def probe(title, problems):
    print(f"[{'ok  ' if not problems else 'FAIL'}] {title}")
    for p in problems[:8]:
        print(f"       {p}")
    if problems:
        fails.append(title)

def section(src, name):
    s = re.search(rf"^### {re.escape(name)}\s*$(.*?)(?=^### |\Z)", src, re.M | re.S)
    return s.group(1) if s else None

m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
front = m.group(1) if m else ""
probe("frontmatter has feature, prd, status", [f"missing `{k}`" for k in ("feature", "prd", "status") if not re.search(rf"^{k}:", front, re.M)])

consumes = section(text, "Consumes") or ""
rows = [r for r in re.findall(r"^\|(.+)\|\s*$", consumes, re.M) if not re.match(r"\s*(Item|-+)\s*\|", r)]
missing = []
for r in rows:
    cells = [c.strip() for c in r.split("|")]
    if len(cells) < 2 or not re.match(r"F\d+", cells[1]):
        missing.append(f"row `{r.strip()}` names no provider F<NN>")
        continue
    item = cells[0].strip("` ")
    provs = list(folder.parent.glob(f"{cells[1].split()[0]}-*/spec.md"))
    if not provs:
        missing.append(f"{item}: no spec.md for provider {cells[1]}")
    elif item.lower() not in (section(provs[0].read_text(encoding="utf-8"), "Provides") or "").lower():
        missing.append(f"{item}: not under Provides in {provs[0]}")
probe("every consumed item is provided by its provider's spec.md", missing)

provides = section(text, "Provides") or ""
items = re.split(r"^#### ", provides, flags=re.M)[1:]
shape_bad = []
for it in items:
    name = it.splitlines()[0].strip()
    for f in ("Shape", "Invariants", "Errors"):
        if not re.search(rf"\*\*{f}:\*\*\s*\S", it):
            shape_bad.append(f"{name}: no **{f}:**")
probe("every provided item has Shape, Invariants and Errors", ([] if items else ["no #### item under Provides"]) + shape_bad)

exists = section(text, "What already exists") or ""
facts = [l for l in exists.splitlines() if l.startswith("- ")]
probe("every repo fact carries file:line", [f"`{l[:60]}`" for l in facts if not re.search(r"\S+:\d+", l)])

contract = folder / "contract.md"
if contract.exists():
    c = contract.read_text(encoding="utf-8")
    d = re.search(r"^\s+design:\s*(\S.*)$", c, re.M)
    needs_ux = bool(d) and "none" not in d.group(1)
    has_ux = section(text, "UX") is not None
    probe("UX section present exactly when the design lane has work", [] if needs_ux == has_ux else [f"design lane {'has work' if needs_ux else 'is none'}, UX section {'missing' if needs_ux else 'present'}"])
    if has_ux:
        ux = section(text, "UX").lower()
        probe("UX lists the four states", [f"no `{s}` state" for s in ("loading", "empty", "error", "success") if s not in ux])
else:
    print("[skip] UX section vs design lane: no contract.md yet")

gaps = section(text, "Open gaps") or ""
if re.search(r"^status:\s*Approved", front, re.M):
    probe("Approved spec has no open gap", [l for l in gaps.splitlines() if l.startswith("- ") and "[" not in l])

sys.exit(1 if fails else 0)
PY
