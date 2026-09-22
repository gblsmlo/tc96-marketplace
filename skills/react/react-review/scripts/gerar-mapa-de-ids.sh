#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md das duas skills de React a partir de Docs/.
# O mapa é um roteador: ID -> satélite -> seção. Ele nunca copia o texto da regra,
# porque cópia de regra dentro de skill vira réplica desatualizada (Skills/README.md).
#
# Prioridade de declaração, quando o mesmo ID aparece em vários lugares:
#   0  heading próprio (`### `REACT-X-NN` — título`) — é onde a regra é definida
#   1  linha de tabela com MUST/NEVER num satélite
#   2  linha de tabela com MUST/NEVER no hub React.js (redeclaração da § 6)
#   3  menção em checklist ou tabela de varredura
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
  echo "# Mapa de IDs \`REACT-*\` — onde cada regra mora"
  echo
  echo "> Roteador, não cópia: este arquivo diz **onde** a regra está declarada, nunca o que ela diz."
  echo "> Para o texto, abra o satélite. Regenerar com:"
  echo "> \`bash skills/react/react-review/scripts/gerar-mapa-de-ids.sh\`"
  echo
  echo "## Apelidos — nunca citar em revisão"
  echo
  echo "De \`Docs/React.js.md\` § 6.2. Cite sempre o canônico; apelido em achado é achado inválido."
  echo
  awk '/^### 6\.2/,/^### Fam/' "$DOCS/react-js.md" | grep -E '^\|' | links || true
  echo
  echo "## Índice completo"
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' 'NR == FNR { titulo[$1] = $2; next }
                  !seen[$1]++ { printf "| `%s` | [%s](../../../../knowledge-base/docs/%s.md) | %s |\n", \
                                $1, ($3 in titulo ? titulo[$3] : $3), $3, $4 }' <(titulos) -
} > "$TMP"

cp "$TMP" "$OUT_DEV"
mv "$TMP" "$OUT_REV"
echo "gerado: $OUT_DEV ($(grep -c '^| `REACT' "$OUT_DEV") IDs)"
echo "gerado: $OUT_REV"
