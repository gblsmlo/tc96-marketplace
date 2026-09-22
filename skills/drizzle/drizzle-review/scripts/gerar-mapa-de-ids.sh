#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md a partir de Docs/Drizzle*.
set -euo pipefail
BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# O mapa é gerado na autoria e vai versionado no plugin: o destino é o repo,
# a origem continua sendo o vault (passe outro caminho como $1 se preciso).
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS="$BASE/docs"
OUT="$PLUGIN/skills/drizzle-review/references/mapa-de-ids.md"

scan() {
  for f in "$DOCS"/drizzle*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="Drizzle ORM" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /DRZ-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `DRZ-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `DRZ-[A-Z0-9]+-[0-9]+`/) {
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
  echo "gerado-por: plugins/hermes-backend/skills/drizzle-review/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`DRZ-*\`"
  echo
  echo "> Índice, não cópia. \`DRZ-SCHEMA-01\` é **apelido** de \`DRZ-CORE-02\` e não aparece em revisão."
  echo "> Regenerar com \`bash plugins/hermes-backend/skills/drizzle-review/scripts/gerar-mapa-de-ids.sh\`."
  echo
  echo "| ID | Declarada em | Corpo no satélite | Seção do corpo |"
  echo "| --- | --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' -v hub="Drizzle ORM" '
    {
      if (!( $1 in decl )) { decl[$1] = $3; ordem[++k] = $1 }
      if ($3 != hub && !( $1 in corpo )) { corpo[$1] = $3; sec[$1] = $4 }
    }
    END {
      for (i = 1; i <= k; i++) {
        id = ordem[i]
        printf "| `%s` | [[%s]] | %s | %s |\n", id, decl[id],
          (id in corpo ? "[[" corpo[id] "]]" : "— (só no hub)"),
          (id in sec ? sec[id] : "—")
      }
    }'
} > "$OUT"
echo "gerado: $OUT ($(grep -c '^| `DRZ' "$OUT") IDs)"
