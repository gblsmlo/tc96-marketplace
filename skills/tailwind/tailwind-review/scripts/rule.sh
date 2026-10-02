#!/usr/bin/env bash
# Prints the text of one or more TW-* rules, with their satellite and section, so a finding
# can cite the rule without loading the hub, the ID map or the whole satellite.
# Usage: bash rule.sh TW-SRC-01 TW-UTIL-01 ...   ·   bash rule.sh TW-A11Y      (a whole family)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# source layout: skills/tailwind/<skill>/scripts → the family's docs/
# built layout:  skills/<skill>/scripts        → the plugin's docs/tailwind/
for KB in "$HERE/../../docs" "$HERE/../../../docs/tailwind"; do
  [ -f "$KB/tailwindcss.md" ] && break
done
[ -f "$KB/tailwindcss.md" ] || { echo "the tailwind docs were not found next to this skill" >&2; exit 1; }
[ $# -gt 0 ] || { echo "usage: bash rule.sh TW-XXX-NN [TW-...]" >&2; exit 1; }

python3 - "$KB" "$@" <<'PY'
import glob, os, re, sys

kb, wanted = sys.argv[1], sys.argv[2:]
rules = {}
# satellites first: the hub's 6.1 table repeats their rules verbatim, but the satellite owns the ID
paths = sorted(glob.glob(os.path.join(kb, "tailwindcss-*.md"))) + [os.path.join(kb, "tailwindcss.md")]
for path in paths:
    text = open(path, encoding="utf-8").read()
    title = re.search(r"^titulo: (.+)$", text, re.M).group(1)
    section = "—"
    for line in text.splitlines():
        if line.startswith("## "):
            section = line[3:]
        m = re.match(r"^\| `(TW-[A-Z0-9]+-\d+)` \| (.+?) \|(?: \[.*)?$", line)
        if m and m.group(1) not in rules:
            rules[m.group(1)] = (m.group(2), title, os.path.basename(path), section)

missing = 0
for w in wanted:
    hits = [k for k in sorted(rules) if k == w or (not re.search(r"-\d+$", w) and k.startswith(w + "-"))]
    if not hits:
        print(f"{w}: no such rule — check the ID map"); missing += 1; continue
    for k in hits:
        rule, title, file, section = rules[k]
        print(f"{k} — {rule}\n    {title} ({file}) § {section}")
sys.exit(1 if missing else 0)
PY
