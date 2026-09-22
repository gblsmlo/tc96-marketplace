#!/usr/bin/env bash
# Regenerates references/mapa-de-ids.md for the two React skills, from the knowledge base.
# The map is a router: ID -> satellite -> section. It never copies the rule's text,
# because a rule copied into a skill becomes a stale replica (skills/README.md).
#
# Declaration priority, when the same ID shows up in several places:
#   0  its own heading (`### `REACT-X-NN` — title`) — where the rule is defined
#   1  table row with MUST/NEVER in a satellite
#   2  table row with MUST/NEVER in the React.js hub (redeclaring § 6)
#   3  mention in a checklist or scan table
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# The map is generated at authoring time and committed: source and destination are
# both this repository (pass another knowledge-base path as $1 if you need to).
FAMILIA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$BASE/docs"

# Title of each note, from the `titulo:` field in the file itself — the link label.
titulos() {
  awk 'FNR == 1 { nome = FILENAME; sub(/.*\//, "", nome); sub(/\.md$/, "", nome) }
       /^titulo: / { print nome "\t" substr($0, 9); nextfile }' "$DOCS"/*.md
}

# Rewrites a note's own relative links to how they are seen from
# <family>/<skill>/references/ — nothing here points outside the project.
links() {
  sed -E -e 's#\]\(\.\./pages/#](../../../../knowledge-base/pages/#g' \
         -e 's#\]\(([^)/]+\.md)#](../../../../knowledge-base/docs/\1#g'
}
OUT_DEV="$FAMILIA/react-developer/references/mapa-de-ids.md"
OUT_REV="$FAMILIA/react-review/references/mapa-de-ids.md"
TMP="$(mktemp)"

scan() {
  for f in "$DOCS"/react*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="react-js" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /REACT-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `REACT-[A-Z0-9]+-[0-9]+`/)      rank = 0
        else if ($0 ~ /^\| `REACT-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: skills/react/react-review/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`REACT-*\` — where each rule lives"
  echo
  echo "> A router, not a copy: this file says **where** the rule is declared, never what it says."
  echo "> For the text, open the satellite. Regenerate with:"
  echo "> \`bash skills/react/react-review/scripts/gerar-mapa-de-ids.sh\`"
  echo
  echo "## Aliases — never cite one in a review"
  echo
  echo "From [React.js](../../../../knowledge-base/docs/react-js.md) § 6.2. Always cite the canonical ID; an alias in a finding is an invalid finding."
  echo
  awk '/^### 6\.2/,/^### Fam/' "$DOCS/react-js.md" | grep -E '^\|' | links || true
  echo
  echo "## Full index"
  echo
  echo "| ID | Satellite | Section |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' 'NR == FNR { titulo[$1] = $2; next }
                  !seen[$1]++ { printf "| `%s` | [%s](../../../../knowledge-base/docs/%s.md) | %s |\n", \
                                $1, ($3 in titulo ? titulo[$3] : $3), $3, $4 }' <(titulos) -
} > "$TMP"

cp "$TMP" "$OUT_DEV"
mv "$TMP" "$OUT_REV"
echo "written: $OUT_DEV ($(grep -c '^| `REACT' "$OUT_DEV") IDs)"
echo "written: $OUT_REV"
