#!/usr/bin/env bash
# Regenerates references/id-map.md in every drizzle skill from skills/drizzle/docs/.
# Authoring tool: it reads the family docs and writes into the sibling skills, so it does not ship
# in a .skill package. Each skill gets only the ID families it cites.
#   bash skills/drizzle/drizzle-review/scripts/generate-id-map.sh
set -euo pipefail
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAMILY="$FAMILY" python3 <<'PYEOF'
import os, re, pathlib, datetime
family = pathlib.Path(os.environ["FAMILY"])
docs = family / "docs"
HUB = "drizzle-orm.md"
SKILLS = {
    "drizzle-review":   lambda i: True,
    "drizzle-query":    lambda i: re.match(r"DRZ-(CORE|REL|RQB)-|DRZ-QUERY-0[1-3]$", i),
    "drizzle-mutation": lambda i: re.match(r"DRZ-(CORE|TX)-|DRZ-QUERY-0[4-9]$", i),
    "drizzle-zod":      lambda i: re.match(r"DRZ-(CORE|ZOD)-", i),
}
ROW = re.compile(r"^\| `(DRZ-[A-Z]+-\d+)` \| (.*)$")
decl, body, title = {}, {}, {}
for f in sorted(docs.glob("drizzle*.md"), key=lambda p: (p.name != HUB, p.name)):
    t = f.read_text(encoding="utf-8")
    title[f.name] = re.search(r"^titulo: (.+)$", t, re.M).group(1)
    section = "—"
    for line in t.splitlines():
        if line.startswith("## "):
            section = line[3:].strip()
        m = ROW.match(line)
        if not m or not re.search(r"\*\*(MUST|NEVER)\*\*", m.group(2)):
            continue
        rid = m.group(1)
        decl.setdefault(rid, f.name)
        if f.name != HUB:
            body.setdefault(rid, (f.name, section))
        elif rid not in body:
            body[rid] = (f.name, section)
order = lambda i: (i.split("-")[1], int(i.split("-")[2]))
ids = sorted(decl, key=order)
today = datetime.date.today().isoformat()
for skill, keep in SKILLS.items():
    rows = [i for i in ids if keep(i)]
    link = lambda n: f"[{title[n]}](../../../docs/drizzle/{n})"
    out = ["---", "generated-by: skills/drizzle/drizzle-review/scripts/generate-id-map.sh", f"generated-at: {today}", "---", "",
           f"# ID map — `{skill}`", "",
           "> An index, not a copy: open the satellite in the third column, at the section in the fourth, only when a finding needs the rule's body.",
           "> `DRZ-SCHEMA-01` is an alias of `DRZ-CORE-02`." if skill == "drizzle-review" else "> Only the ID families this skill cites; `drizzle-review` carries the full map.",
           "> Regenerate with `bash skills/drizzle/drizzle-review/scripts/generate-id-map.sh`.", "",
           "| ID | Declared in | Body in | Section of the body |", "| --- | --- | --- | --- |"]
    for i in rows:
        b, sec = body[i]
        out.append(f"| `{i}` | {link(decl[i])} | {link(b)} | {sec} |")
    (family / skill / "references" / "id-map.md").write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"written: {skill}/references/id-map.md ({len(rows)} IDs)")
PYEOF
