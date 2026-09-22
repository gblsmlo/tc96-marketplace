#!/usr/bin/env bash
# Regenera references/mapa-de-ids.md a partir de Pages/Feature-Based Architecture.md.
# Índice, não cópia: ID -> severidade -> quem faz valer -> seção onde a regra mora.
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# The map is generated at authoring time and committed: source and destination are
# both this repository (pass another knowledge-base path as $1 if you need to).
FAMILIA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FONTE="$BASE/pages/feature-based-architecture.md"
OUT="$FAMILIA/react-structure/references/mapa-de-ids.md"

[ -f "$FONTE" ] || { echo "nota-fonte não encontrada: $FONTE" >&2; exit 1; }

{
  echo "---"
  echo "gerado-por: skills/react/react-structure/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# Mapa de IDs \`REACT-ARCH-*\`"
  echo
  echo "> Índice, não cópia: o texto de cada regra mora em \`Pages/Feature-Based Architecture.md\` § 4."
  echo "> A coluna **Faz valer** diz se o lint pega ou se depende de revisão humana — é o que decide"
  echo "> se um achado se repete no próximo PR. Regenerar com:"
  echo "> \`bash skills/react/react-structure/scripts/gerar-mapa-de-ids.sh\`"
  echo
  echo "| ID | Severidade | Faz valer | Seção do corpo estendido |"
  echo "| --- | --- | --- | --- |"
  awk '
    /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
    /^\| `REACT-ARCH-[0-9]+`/ {
      n = split($0, c, "|")
      id = c[2]; sev = c[4]; enf = c[5]
      gsub(/^[ \t]+|[ \t]+$/, "", id); gsub(/^[ \t]+|[ \t]+$/, "", sev); gsub(/^[ \t]+|[ \t]+$/, "", enf)
      gsub(/`/, "", id)
      if (id in visto) next
      visto[id] = 1
      corpo[id] = ""
      linha[id] = sprintf("| `%s` | %s | %s |", id, sev, enf)
      ordem[++k] = id
    }
    /^#{3,4} `REACT-ARCH-[0-9]+`/ {
      if (match($0, /REACT-ARCH-[0-9]+/) > 0) {
        cid = substr($0, RSTART, RLENGTH)
        titulo = $0; sub(/^#+ `REACT-ARCH-[0-9]+` +/, "", titulo); sub(/^— */, "", titulo); sub(/^- */, "", titulo)
        detalhe[cid] = titulo
      }
    }
    END {
      for (i = 1; i <= k; i++) {
        id = ordem[i]
        printf "%s %s |\n", linha[id], (id in detalhe ? detalhe[id] : "—")
      }
    }
  ' "$FONTE"
  echo
  echo "Linha com \`—\` na última coluna: a regra é declarada na tabela da § 4 e não tem"
  echo "subseção própria de corpo estendido. As demais têm, e é onde mora o raciocínio."
} > "$OUT"

echo "gerado: $OUT ($(grep -c '^| `REACT-ARCH' "$OUT") IDs)"
