#!/usr/bin/env bash
# Builds react-audit/references/id-map.md by joining the three generated maps of the siblings.
# Run the three sibling generators first; this one never reads the docs itself.
set -euo pipefail

FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$FAMILY/react-audit/references/id-map.md"
body() { sed '1,/^---$/d' "$1" | sed '/^# /d' | sed '/^## Contents$/,/^$/d'; }
{
  echo "---"
  echo "generated-by: skills/react/react-audit/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map for the audit — \`REACT-*\`, \`REACT-ARCH-*\`, \`RHF-*\`"
  echo
  echo "> Joined from the maps of react-review, react-structure and react-hook-form. Where a rule lives, never what it says."
  echo
  echo "## Contents"
  echo "- [\`REACT-*\`](#react-)"
  echo "- [\`REACT-ARCH-*\`](#react-arch-)"
  echo "- [\`RHF-*\`](#rhf-)"
  echo
  echo "## \`REACT-*\`"
  body "$FAMILY/react-review/references/id-map.md" | sed 's/^## /### /'
  echo
  echo "## \`REACT-ARCH-*\`"
  body "$FAMILY/react-structure/references/id-map.md" | sed 's/^## /### /'
  echo
  echo "## \`RHF-*\`"
  body "$FAMILY/react-hook-form/references/id-map.md" | sed 's/^## /### /'
} > "$OUT"
echo "written: $OUT ($(grep -cE '^\| `(REACT|RHF)-' "$OUT") rows)"
