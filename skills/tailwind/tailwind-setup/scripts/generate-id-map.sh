#!/usr/bin/env bash
# Regenerates references/rules.md in every Tailwind skill from the rule tables of the docs
# that each skill owns (<skill>/docs/tailwindcss*.md). Authoring only: the file is committed.
#   bash skills/tailwind/tailwind-setup/scripts/generate-id-map.sh
set -euo pipefail
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

FAMILY="$FAMILY" python3 <<'PY'
import datetime, os, pathlib, re

family = pathlib.Path(os.environ["FAMILY"])
docs = sorted(family.glob("tailwind-*/docs/tailwindcss*.md"))
skills = sorted(p.parent for p in family.glob("tailwind-*/SKILL.md"))

rules = {}
# satellites first: the hub's critical table repeats their rows, but the satellite owns the ID
for doc in sorted(docs, key=lambda d: d.name == "tailwindcss.md"):
    text = doc.read_text(encoding="utf-8")
    title = re.search(r"^title: (.+)$", text, re.M).group(1)
    section = ""
    for line in text.splitlines():
        if line.startswith("## "):
            section = line[3:].split(". ", 1)[0] if re.match(r"## \d", line) else line[3:]
        m = re.match(r"^\| `(TW-[A-Z0-9]+-\d+)` \| (.+?) \|", line)
        if m and m.group(1) not in rules:
            rules[m.group(1)] = (m.group(2), doc, title, section)

ORDER = ["CORE", "CFG", "SRC", "THEME", "UTIL", "VAR", "A11Y", "COMP", "TOOL", "MIG"]
key = lambda i: (ORDER.index(i.split("-")[1]), int(i.split("-")[2]))

for skill in skills:
    out = ["---",
           "generated-by: skills/tailwind/tailwind-setup/scripts/generate-id-map.sh",
           f"generated-at: {datetime.date.today()}",
           "---", "",
           "# `TW-*` rules", "",
           "> Grep, never load whole: `grep -h 'TW-SRC-01' references/rules.md` (or a family: `'TW-A11Y-'`).",
           "> `MUST`/`NEVER` are normative. `†` marks a house decision, debatable in review and never Blocking alone.",
           "> A project that stays on line 3: only `TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*` apply.", "",
           "| ID | Rule | Source |", "| --- | --- | --- |"]
    for rid in sorted(rules, key=key):
        rule, doc, title, section = rules[rid]
        src = (f"[{title}](../docs/{doc.name}) § {section}" if doc.parent.parent == skill
               else f"`{title}` § {section} ({doc.parent.parent.name})")
        out.append(f"| `{rid}` | {rule} | {src} |")
    out += ["", "## Pairs that look like aliases and are not", "",
            "- `TW-THEME-04` (arbitrary duplicating a token: use it) × `TW-UTIL-03` (repeated arbitrary, no token: create it).",
            "- `TW-SRC-02` (scanner: complete strings) × `TW-COMP-06` (API: design variation is a variant).",
            "- `TW-UTIL-01` (conflict on the element) × `TW-COMP-02` (merge hiding an internal conflict).",
            "- `TW-MIG-03` (rename `outline-none` → `outline-hidden`) × `TW-A11Y-01` (focus replacement, for both).", ""]
    (skill / "references" / "rules.md").write_text("\n".join(out), encoding="utf-8")

print(f"references/rules.md written into {len(skills)} skills ({len(rules)} rules)")
PY
