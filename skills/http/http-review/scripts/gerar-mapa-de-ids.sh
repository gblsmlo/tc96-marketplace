#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md das quatro skills de HTTP, a partir de Docs/HTTP*.
set -euo pipefail
BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# O mapa é gerado na autoria e vai versionado no plugin: o destino é o repo,
# a origem continua sendo o vault (passe outro caminho como $1 se preciso).
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS="$BASE/docs"
HUB="$DOCS/http.md"

scan() {
  for f in "$DOCS"/http*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="HTTP" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /HTTP-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `HTTP-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `HTTP-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: plugins/hermes-core/skills/http-review/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`HTTP-*\`"
  echo
  echo "> Índice, não cópia: diz **onde** a regra está declarada, nunca o que ela diz."
  echo "> Regenerar com \`bash plugins/hermes-core/skills/http-review/scripts/gerar-mapa-de-ids.sh\` —"
  echo "> o mesmo arquivo é escrito nas quatro skills de HTTP."
  echo
  echo "## Canônicos e apelidos"
  echo
  awk '/^### 6\.2/,/^### Fam|^## 7/' "$HUB" | grep -vE '^### ' | cat -s || true
  echo
  echo "## Índice completo"
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$TMP"

for s in contract cache diagnose review; do
  cp "$TMP" "$PLUGIN/skills/http-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "gerado nas 4 skills ($(grep -c '^| `HTTP' "$PLUGIN/skills/http-review/references/mapa-de-ids.md") IDs)"
