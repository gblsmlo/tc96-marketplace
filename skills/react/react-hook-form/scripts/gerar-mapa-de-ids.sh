#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md a partir de Docs/React Hook Form*.md.
# Índice, não cópia: ID -> satélite -> seção. O texto da regra fica na nota.
#
# Prioridade quando o mesmo ID aparece em vários lugares:
#   0  heading próprio      1  linha de tabela com MUST/NEVER no satélite
#   2  a mesma no hub       3  menção em checklist ou tabela de diagnóstico
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# O mapa é gerado na autoria e vai versionado no plugin: o destino é o repo,
# a origem continua sendo o vault (passe outro caminho como $1 se preciso).
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS="$BASE/docs"
OUT="$PLUGIN/skills/react-hook-form/references/mapa-de-ids.md"

scan() {
  for f in "$DOCS"/react-hook-form*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="React Hook Form" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /RHF-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `RHF-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `RHF-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: plugins/hermes-frontend/skills/react-hook-form/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`RHF-*\`"
  echo
  echo "> Índice, não cópia: diz **onde** a regra está declarada, nunca o que ela diz."
  echo "> Regenerar com \`bash plugins/hermes-frontend/skills/react-hook-form/scripts/gerar-mapa-de-ids.sh\`."
  echo
  echo "## Citação entre docs"
  echo
  echo "Dentro de uma revisão de formulário, o ID \`RHF-*\` basta. **Ao citar entre docs**"
  echo "— uma revisão de React que encosta em formulário, ou o contrário — use o canônico,"
  echo "senão quem for corrigir não acha o texto. Tabelas abaixo extraídas da § 6.2 do hub."
  echo
  awk '/^### 6\.2/,/^### Fam/' "$DOCS/react-hook-form.md" \
    | grep -vE '^#|^Dois princípios' | cat -s || true
  echo
  echo "## Índice completo"
  echo
  echo "| ID | Satélite | Seção |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '!seen[$1]++ { printf "| `%s` | [[%s]] | %s |\n", $1, $3, $4 }'
} > "$OUT"

echo "gerado: $OUT ($(grep -c '^| `RHF' "$OUT") IDs)"
