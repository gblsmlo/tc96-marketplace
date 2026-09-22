#!/usr/bin/env bash
# Regenerates references/mapa-de-ids.md for the three Playwright skills, from playwright*.
# An index, not a copy: ID -> satellite -> section. The rule's text stays in the note.
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
HUB="$DOCS/playwright.md"

scan() {
  for f in "$DOCS"/playwright*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="playwright" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /PW-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `PW-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `PW-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: skills/playwright/playwright-review/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`PW-*\`"
  echo
  echo "> An index, not a copy: it says **where** the rule is declared, never what it says."
  echo "> Regenerate with \`bash skills/playwright/playwright-review/scripts/gerar-mapa-de-ids.sh\` —"
  echo "> the same file is written into all three Playwright skills."
  echo
  echo "## Aliases and near-aliases"
  echo
  awk '/^### 6\.2/,/^### Famílias/' "$HUB" | grep -vE '^### ' | cat -s | links || true
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

for s in build review diagnose; do
  cp "$TMP" "$FAMILIA/playwright-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "written into 3 skills ($(grep -c '^| `PW' "$FAMILIA/playwright-build/references/mapa-de-ids.md") IDs)"
