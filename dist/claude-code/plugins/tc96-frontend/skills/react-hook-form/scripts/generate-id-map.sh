#!/usr/bin/env bash
# Regenerates references/id-map.md from the family's docs/react-hook-form*.
# An index, not a copy: ID -> satellite -> section. The rule's text stays in the note.
#
# Priority when the same ID shows up in several places:
#   0  its own heading      1  table row with MUST/NEVER in the satellite
#   2  the same in the hub   3  mention in a checklist or diagnosis table
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/docs/react}"
# The map is generated at authoring time and committed: source and destination are
# both this family (pass another docs path as $1 if you need to).
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$BASE"

# Title of each note, from the `heading:` field in the file itself — the link label.
titles() {
  awk 'FNR == 1 { name = FILENAME; sub(/.*\//, "", name); sub(/\.md$/, "", name) }
       /^titulo: / { print name "\t" substr($0, 9); nextfile }' "$DOCS"/*.md
}

# Rewrites a note's own relative links to how they are seen from
# <family>/<skill>/references/ — nothing here points outside the project.
links() {
  sed -E -e 's#\]\(([^)/]+\.md)#](../../../docs/react/\1#g'
}
OUT="$FAMILY/react-hook-form/references/id-map.md"

scan() {
  for f in "$DOCS"/react-hook-form*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="react-hook-form" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /RHF-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `RHF-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `RHF-[A-Z0-9]+-[0-9]+`/) {
          if ($0 ~ /MUST|NEVER/) rank = (sat == hub ? 2 : 1)
          else                   rank = 3
        }
        if (rank < 0) next
        sec = (rank == 3 ? h : h2)
        printf "%s\t%d\t%s\t%s\n", id, rank, sat, (sec == "" ? "—" : sec)
      }
    ' "$f"
  done
}

{
  echo "---"
  echo "generated-by: skills/react/react-hook-form/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`RHF-*\`"
  echo
  echo "> An index, not a copy: it says **where** the rule is declared, never what it says."
  echo "> Regenerate with \`bash skills/react/react-hook-form/scripts/generate-id-map.sh\`."
  echo
  echo "## Citing across docs"
  echo
  echo "Inside a form review, the \`RHF-*\` ID is enough. **When citing across docs**"
  echo "— a React review that touches a form, or the other way round — use the canonical one,"
  echo "or whoever fixes it will not find the text. The tables below come from § 6.2 of the hub."
  echo
  awk '/^### 6\.2/,/^### (Fam|Full families)/' "$DOCS/react-hook-form.md" \
    | grep -vE '^#|^Two principles' | cat -s | links || true
  echo
  echo "## Full index"
  echo
  echo "| ID | Satellite | Section |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' 'NR == FNR { title[$1] = $2; next }
                  !seen[$1]++ { printf "| `%s` | [%s](../../../docs/react/%s.md) | %s |\n", \
                                $1, ($3 in title ? title[$3] : $3), $3, $4 }' <(titles) -
} > "$OUT"

echo "written: $OUT ($(grep -c '^| `RHF' "$OUT") IDs)"
