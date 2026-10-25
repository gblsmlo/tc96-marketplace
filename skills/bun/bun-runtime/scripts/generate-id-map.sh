#!/usr/bin/env bash
# Regenerates references/id-map.md for the three Bun runtime/package/migration skills, from the
# family docs (skills/bun/docs). Covers BUN-CORE-*, BUN-RT-*, BUN-PKG-* and BUN-SYS-*. The
# BUN-TEST-* family has a generator of its own, in bun-test-review/scripts/.
# The map is a router: ID -> satellite -> section. It never copies the rule's text.
#
# Declaration priority, when the same ID shows up in several places:
#   0  its own heading — where the rule is defined
#   1  table row with MUST/NEVER in a satellite
#   2  table row with MUST/NEVER in the Bun hub (redeclaring § 6)
#   3  mention in a checklist or scan table
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docs}"
# The map is generated at authoring time and committed: source and destination are
# both this family (pass another docs path as $1 if you need to).
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$BASE"

# Title of each note, from the `titulo:` field in the file itself — the link label.
titles() {
  awk 'FNR == 1 { name = FILENAME; sub(/.*\//, "", name); sub(/\.md$/, "", name) }
       /^titulo: / { print name "\t" substr($0, 9); nextfile }' "$DOCS"/*.md
}

scan() {
  for f in "$DOCS"/bun*.md; do
    base="$(basename "$f" .md)"
    case "$base" in bun-tests*) continue;; esac   # the test family has its own map
    awk -v sat="$base" -v hub="bun" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /BUN-(CORE|RT|PKG|SYS)-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `BUN-(CORE|RT|PKG|SYS)-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `BUN-(CORE|RT|PKG|SYS)-[0-9]+`/) {
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
  echo "generated-by: skills/bun/bun-runtime/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`BUN-CORE/RT/PKG/SYS-*\`"
  echo
  echo "> An index, not a copy. The \`BUN-TEST-*\` family is **not** here — it has a generator"
  echo "> of its own, in \`bun-test-review/scripts/generate-id-map.sh\`."
  echo "> Regenerate with \`bash skills/bun/bun-runtime/scripts/generate-id-map.sh\`."
  echo
  echo "| ID | Satellite | Section |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' 'NR == FNR { title[$1] = $2; next }
                  !seen[$1]++ { printf "| `%s` | [%s](../../docs/%s.md) | %s |\n", \
                                $1, ($3 in title ? title[$3] : $3), $3, $4 }' <(titles) -
} > "$TMP"

for s in runtime workspace migrate; do
  cp "$TMP" "$FAMILY/bun-$s/references/id-map.md"
done
rm -f "$TMP"
echo "written into 3 skills ($(grep -c '^| `BUN' "$FAMILY/bun-runtime/references/id-map.md") IDs)"
