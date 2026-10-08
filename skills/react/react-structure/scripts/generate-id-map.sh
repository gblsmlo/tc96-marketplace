#!/usr/bin/env bash
# Regenerates references/id-map.md from the family's docs/feature-based-architecture.md.
# An index, not a copy: ID -> severity -> what enforces it -> section where the rule lives.
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docs}"
# The map is generated at authoring time and committed: source and destination are
# both this family (pass another docs path as $1 if you need to).
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FONTE="$BASE/feature-based-architecture.md"
OUT="$FAMILY/react-structure/references/id-map.md"

[ -f "$FONTE" ] || { echo "source note not found: $FONTE" >&2; exit 1; }

{
  echo "---"
  echo "generated-by: skills/react/react-structure/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`REACT-ARCH-*\`"
  echo
  echo "> An index, not a copy: each rule's text lives in [Feature-Based Architecture](../../docs/feature-based-architecture.md) § 4."
  echo "> The **Enforced by** column says whether lint catches it or it depends on human review — that is what decides"
  echo "> whether a finding comes back in the next PR. Regenerate with \`bash skills/react/react-structure/scripts/generate-id-map.sh\`."
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
      if (id in seen) next
      seen[id] = 1
      corpo[id] = ""
      row[id] = sprintf("| `%s` | %s | %s |", id, sev, enf)
      ordem[++k] = id
    }
    /^#{3,4} `REACT-ARCH-[0-9]+`/ {
      if (match($0, /REACT-ARCH-[0-9]+/) > 0) {
        cid = substr($0, RSTART, RLENGTH)
        heading = $0; sub(/^#+ `REACT-ARCH-[0-9]+` +/, "", heading); sub(/^— */, "", heading); sub(/^- */, "", heading)
        detail[cid] = heading
      }
    }
    END {
      for (i = 1; i <= k; i++) {
        id = ordem[i]
        printf "%s %s |\n", row[id], (id in detail ? detail[id] : "—")
      }
    }
  ' "$FONTE"
  echo
  echo "A row with \`—\` in the last column: the rule is declared in the § 4 table and has no"
  echo "extended-body subsection of its own. The others do, and that is where the reasoning lives."
} > "$OUT"

echo "written: $OUT ($(grep -c '^| `REACT-ARCH' "$OUT") IDs)"
