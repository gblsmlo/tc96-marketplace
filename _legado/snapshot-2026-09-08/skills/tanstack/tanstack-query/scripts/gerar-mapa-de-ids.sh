#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md a partir de Docs/TanStack Query*.
set -euo pipefail
VAULT="${1:-$HOME/Sync/Vaults/Notes}"
DOCS="$VAULT/Docs"
OUT="$VAULT/Skills/tanstack/tanstack-query/references/mapa-de-ids.md"

scan() {
  PREFIXO="TanStack Query"
  for f in "$DOCS"/"$PREFIXO"*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="TanStack Query" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /TSQ-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `TSQ-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `TSQ-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: Skills/tanstack/tanstack-query/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`TSQ-*\`"
  echo
  echo "> Índice, não cópia: diz **onde** a regra está declarada, nunca o que ela diz."
  echo "> Regenerar com \`bash Skills/tanstack/tanstack-query/scripts/gerar-mapa-de-ids.sh\`."
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$OUT"
echo "gerado: $OUT ($(grep -c '^| `TSQ' "$OUT") IDs)"
