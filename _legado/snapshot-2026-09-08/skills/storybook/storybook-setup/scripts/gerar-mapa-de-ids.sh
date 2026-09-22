#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md das três skills de Storybook, de Docs/Storybook*.
set -euo pipefail
VAULT="${1:-$HOME/Sync/Vaults/Notes}"
DOCS="$VAULT/Docs"
HUB="$DOCS/Storybook.md"

scan() {
  for f in "$DOCS"/Storybook*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="Storybook" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /SB-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `SB-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `SB-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: Skills/storybook/storybook-setup/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`SB-*\`"
  echo
  echo "> Índice, não cópia. **\`SB-TS-*\` e \`SB-RV-*\` são mutuamente exclusivas:**"
  echo "> citar a família do caminho errado é achado inválido. Descubra o caminho primeiro —"
  echo "> \`bash Skills/storybook/storybook-setup/scripts/descobrir-caminho.sh\`."
  echo "> Regenerar com \`bash Skills/storybook/storybook-setup/scripts/gerar-mapa-de-ids.sh\`."
  echo
  echo "## Canônicos, apelidos e os pares por caminho"
  echo
  awk '/^### 6\.2/,/^### Famílias/' "$HUB" | grep -vE '^### ' | cat -s || true
  echo
  echo "## Índice completo"
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$TMP"

for s in setup story test; do
  cp "$TMP" "$VAULT/Skills/storybook/storybook-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "gerado nas 3 skills ($(grep -c '^| `SB' "$VAULT/Skills/storybook/storybook-setup/references/mapa-de-ids.md") IDs)"
