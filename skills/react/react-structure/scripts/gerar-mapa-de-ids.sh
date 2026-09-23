#!/usr/bin/env bash
# Regenerates references/mapa-de-ids.md from knowledge-base/feature-based-architecture.md.
# An index, not a copy: ID -> severity -> what enforces it -> section where the rule lives.
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# The map is generated at authoring time and committed: source and destination are
# both this repository (pass another knowledge-base path as $1 if you need to).
FAMILIA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FONTE="$BASE/feature-based-architecture.md"
OUT="$FAMILIA/react-structure/references/mapa-de-ids.md"

[ -f "$FONTE" ] || { echo "source note not found: $FONTE" >&2; exit 1; }

{
  echo "---"
  echo "gerado-por: skills/react/react-structure/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`REACT-ARCH-*\`"
  echo
  echo "> An index, not a copy: each rule's text lives in [Feature-Based Architecture](../../../../knowledge-base/feature-based-architecture.md) § 4."
  echo "> The **Enforced by** column says whether lint catches it or it depends on human review — that is what decides"
  echo "> whether a finding comes back in the next PR. Regenerate with:"
  echo "> \`bash skills/react/react-structure/scripts/gerar-mapa-de-ids.sh\`"
  echo
  echo "| ID | Severity | Enforced by | Section of the extended body |"
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
  echo "A row with \`—\` in the last column: the rule is declared in the § 4 table and has no"
  echo "extended-body subsection of its own. The others do, and that is where the reasoning lives."
} > "$OUT"

echo "written: $OUT ($(grep -c '^| `REACT-ARCH' "$OUT") IDs)"
