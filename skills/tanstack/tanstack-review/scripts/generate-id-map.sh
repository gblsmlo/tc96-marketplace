#!/usr/bin/env bash
# Regenerates references/id-map.md from the family docs: ID -> doc -> section number, never the rule text.
# A rule is declared by a table row starting with its ID and carrying MUST/NEVER/SHOULD, or by its own heading.
set -euo pipefail
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="${1:-$FAMILY/docs}"
OUT="$FAMILY/tanstack-review/references/id-map.md"
mkdir -p "$(dirname "$OUT")"

{
  echo "---"
  echo "generated-by: skills/tanstack/tanstack-review/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`TSQ-*\` \`TSR-*\`"
  echo
  echo "Where each rule is declared: doc and section. Open that section for the text. Aliases: [TanStack Router](../../docs/tanstack-router.md) § 6.1."
  for f in "$DOCS"/tanstack-*.md; do
    base="$(basename "$f")"
    title="$(awk '/^title: /{ print substr($0, 8); exit }' "$f")"
    ids="$(awk '
      /^## / { s = $0; sub(/^## /, "", s); if (match(s, /^[0-9]+(\.[0-9]+)?/)) s = "§ " substr(s, RSTART, RLENGTH); else s = s }
      /^#{2,4} `TS[QR]-[A-Z]+-[0-9]+`/ || (/^\| `TS[QR]-[A-Z]+-[0-9]+`/ && /MUST|NEVER|SHOULD/) {
        match($0, /TS[QR]-[A-Z]+-[0-9]+/); id = substr($0, RSTART, RLENGTH)
        if (!(id in seen)) { seen[id] = 1; printf "`%s` %s\n", id, s }
      }' "$f" | sort -t- -k2,2 -k3,3n | paste -sd'|' - | sed 's/|/ · /g')"
    [ -n "$ids" ] || continue
    echo
    echo "**[$title](../../docs/$base)**: $ids"
  done
} > "$OUT"
echo "written: $OUT ($(grep -oE '`TS[QR]-[A-Z]+-[0-9]+`' "$OUT" | sort -u | wc -l | tr -d ' ') IDs)"
