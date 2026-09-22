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
# O mapa é gerado na autoria e vai versionado no plugin: o destino é o repo,
# a origem continua sendo o vault (passe outro caminho como $1 se preciso).
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS="$BASE/docs"
OUT_DEV="$PLUGIN/skills/react-developer/references/mapa-de-ids.md"
OUT_REV="$PLUGIN/skills/react-review/references/mapa-de-ids.md"
TMP="$(mktemp)"

scan() {
  for f in "$DOCS"/React*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="React.js" '
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
  echo "gerado-por: plugins/hermes-frontend/skills/react-review/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`REACT-*\` — onde cada regra mora"
  echo
  echo "> Roteador, não cópia: este arquivo diz **onde** a regra está declarada, nunca o que ela diz."
  echo "> Para o texto, abra o satélite. Regenerar com:"
  echo "> \`bash plugins/hermes-frontend/skills/react-review/scripts/gerar-mapa-de-ids.sh\`"
  echo
  echo "## Apelidos — nunca citar em revisão"
  echo
  echo "De \`Docs/React.js.md\` § 6.2. Cite sempre o canônico; apelido em achado é achado inválido."
  echo
  awk '/^### 6\.2/,/^### Fam/' "$DOCS/React.js.md" | grep -E '^\|' || true
  echo
  echo "## Índice completo"
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$TMP"

cp "$TMP" "$OUT_DEV"
mv "$TMP" "$OUT_REV"
echo "gerado: $OUT_DEV ($(grep -c '^| `REACT' "$OUT_DEV") IDs)"
echo "gerado: $OUT_REV"
