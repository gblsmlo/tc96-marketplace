#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md das três skills de runtime/pacote/migração do Bun.
# Cobre BUN-CORE-*, BUN-RT-*, BUN-PKG-* e BUN-SYS-*. A família BUN-TEST-* tem gerador
# próprio, em bun-test-review/scripts/.
set -euo pipefail
BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# O mapa é gerado na autoria e vai versionado no plugin: o destino é o repo,
# a origem continua sendo o vault (passe outro caminho como $1 se preciso).
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS="$BASE/docs"

scan() {
  for f in "$DOCS"/bun*.md; do
    base="$(basename "$f" .md)"
    case "$base" in "Bun - Testes"*) continue;; esac
    awk -v sat="$base" -v hub="Bun" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /BUN-(CORE|RT|PKG|SYS)-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `BUN-(CORE|RT|PKG|SYS)-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `BUN-(CORE|RT|PKG|SYS)-[0-9]+`/) {
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
  echo "gerado-por: plugins/hermes-backend/skills/bun-runtime/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`BUN-CORE/RT/PKG/SYS-*\`"
  echo
  echo "> Índice, não cópia. A família \`BUN-TEST-*\` **não** está aqui — ela tem gerador"
  echo "> próprio, em \`bun-test-review/scripts/gerar-mapa-de-ids.sh\`."
  echo "> Regenerar com \`bash plugins/hermes-backend/skills/bun-runtime/scripts/gerar-mapa-de-ids.sh\`."
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$TMP"

for s in runtime workspace migrate; do
  cp "$TMP" "$PLUGIN/skills/bun-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "gerado nas 3 skills ($(grep -c '^| `BUN' "$PLUGIN/skills/bun-runtime/references/mapa-de-ids.md") IDs)"
