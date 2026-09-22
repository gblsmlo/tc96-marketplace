#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md das três skills de teste, a partir de Docs/Teste*.
# Índice, não cópia: ID -> satélite -> seção. O texto da regra fica na nota.
#
# Prioridade quando o mesmo ID aparece em vários lugares:
#   0  heading próprio   1  tabela com MUST/NEVER no satélite
#   2  a mesma no hub    3  menção em checklist ou tabela de antipadrão
set -euo pipefail

VAULT="${1:-$HOME/Sync/Vaults/Notes}"
DOCS="$VAULT/Docs"
HUB="$DOCS/Teste de Software.md"

scan() {
  for f in "$DOCS"/Teste\ de\ Software*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="Teste de Software" '
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
  echo "gerado-por: Skills/teste/teste-design/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`TS-*\`"
  echo
  echo "> Índice, não cópia: diz **onde** a regra está declarada, nunca o que ela diz."
  echo "> Regenerar com \`bash Skills/teste/teste-design/scripts/gerar-mapa-de-ids.sh\` —"
  echo "> o mesmo arquivo é escrito nas três skills de teste."
  echo
  echo "## Apelidos — citar é achado inválido"
  echo
  awk '/^### 6\.2/,/^### Contagem/' "$HUB" | grep -vE '^#|^### Contagem' | cat -s || true
  echo
  echo "## Índice completo"
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$TMP"

for s in design review diagnose; do
  cp "$TMP" "$VAULT/Skills/teste/teste-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "gerado nas 3 skills ($(grep -c '^| `TS' "$VAULT/Skills/teste/teste-design/references/mapa-de-ids.md") IDs)"
