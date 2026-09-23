#!/usr/bin/env bash
# Regenerates references/mapa-de-ids.md for the three test skills, from teste-de-software*.
# An index, not a copy: ID -> satellite -> section. The rule's text stays in the note.
#
# Priority when the same ID shows up in several places:
#   0  its own heading   1  table with MUST/NEVER in the satellite
#   2  the same in the hub  3  mention in a checklist or antipattern table
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# The map is generated at authoring time and committed: source and destination are
# both this repository (pass another knowledge-base path as $1 if you need to).
FAMILIA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$BASE"

# Title of each note, from the `titulo:` field in the file itself — the link label.
titulos() {
  awk 'FNR == 1 { nome = FILENAME; sub(/.*\//, "", nome); sub(/\.md$/, "", nome) }
       /^titulo: / { print nome "\t" substr($0, 9); nextfile }' "$DOCS"/*.md
}

# Rewrites a note's own relative links to how they are seen from
# <family>/<skill>/references/ — nothing here points outside the project.
links() {
  sed -E -e 's#\]\(\.\./pages/#](../../../../knowledge-base/#g' \
         -e 's#\]\(([^)/]+\.md)#](../../../../knowledge-base/\1#g'
}
HUB="$DOCS/teste-de-software.md"

scan() {
  for f in "$DOCS"/teste-de-software*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="teste-de-software" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /TS-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `TS-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `TS-[A-Z0-9]+-[0-9]+`/) {
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

TMP="$(mktemp)"
{
  echo "---"
  echo "gerado-por: skills/test/test-design/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`TS-*\`"
  echo
  echo "> An index, not a copy: it says **where** the rule is declared, never what it says."
  echo "> Regenerate with \`bash skills/test/test-design/scripts/gerar-mapa-de-ids.sh\` —"
  echo "> the same file is written into all three test skills."
  echo
  echo "## Aliases — citing one is an invalid finding"
  echo
  awk '/^### 6\.2/,/^### Contagem/' "$HUB" | grep -vE '^#|^### Contagem' | cat -s | links || true
  echo
  echo "## Full index"
  echo
  echo "| ID | Satellite | Section |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' 'NR == FNR { titulo[$1] = $2; next }
                  !seen[$1]++ { printf "| `%s` | [%s](../../../../knowledge-base/%s.md) | %s |\n", \
                                $1, ($3 in titulo ? titulo[$3] : $3), $3, $4 }' <(titulos) -
} > "$TMP"

for s in design review diagnose; do
  cp "$TMP" "$FAMILIA/test-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "written into 3 skills ($(grep -c '^| `TS' "$FAMILIA/test-design/references/mapa-de-ids.md") IDs)"
