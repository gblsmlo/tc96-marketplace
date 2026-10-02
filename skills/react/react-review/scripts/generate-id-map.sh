#!/usr/bin/env bash
# Regenerates references/id-map.md for the two React skills, from the knowledge base.
# The map is a router: ID -> satellite -> section. It never copies the rule's text,
# because a rule copied into a skill becomes a stale replica (skills/README.md).
#
# Declaration priority, when the same ID shows up in several places:
#   0  its own heading (`### `REACT-X-NN` — title`) — where the rule is defined
#   1  table row with MUST/NEVER in a satellite
#   2  table row with MUST/NEVER in the React.js hub (redeclaring § 6)
#   3  mention in a checklist or scan table
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docs}"
# The map is generated at authoring time and committed: source and destination are
# both this family (pass another docs path as $1 if you need to).
FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$BASE"

# Title of each note, from the `heading:` field in the file itself — the link label.
titles() {
  awk 'FNR == 1 { name = FILENAME; sub(/.*\//, "", name); sub(/\.md$/, "", name) }
       /^titulo: / { print name "\t" substr($0, 9); nextfile }' "$DOCS"/*.md
}

# Rewrites a note's own relative links to how they are seen from
# <family>/<skill>/references/ — nothing here points outside the project.
links() {
  sed -E -e 's#\]\(([^)/]+\.md)#](../../docs/\1#g'
}
OUT_DEV="$FAMILY/react-developer/references/id-map.md"
OUT_REV="$FAMILY/react-review/references/id-map.md"
TMP="$(mktemp)"

scan() {
  for f in "$DOCS"/react*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="react-js" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /REACT-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `REACT-[A-Z0-9]+-[0-9]+`/)      rank = 0
        else if ($0 ~ /^\| `REACT-[A-Z0-9]+-[0-9]+`/) {
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
  echo "generated-by: skills/react/react-review/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`REACT-*\` — where each rule lives"
  echo
  echo "> A router, not a copy: this file says **where** the rule is declared, never what it says."
  echo "> For the text, open the satellite. Regenerate with \`bash skills/react/react-review/scripts/generate-id-map.sh\`."
  echo
  echo "## Aliases — never cite one in a review"
  echo
  echo "From [React.js](../../docs/react-js.md) § 6.2. Always cite the canonical ID; an alias in a finding is an invalid finding."
  echo
  awk '/^### 6\.2/,/^### (Fam|Full families)/' "$DOCS/react-js.md" | grep -E '^\|' | links || true
  echo
  echo "## Full index"
  echo
  echo "| ID | Satellite | Section |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' 'NR == FNR { title[$1] = $2; next }
                  !seen[$1]++ { printf "| `%s` | [%s](../../docs/%s.md) | %s |\n", \
                                $1, ($3 in title ? title[$3] : $3), $3, $4 }' <(titles) -
} > "$TMP"

cp "$TMP" "$OUT_DEV"
mv "$TMP" "$OUT_REV"
echo "written: $OUT_DEV ($(grep -c '^| `REACT' "$OUT_DEV") IDs)"
echo "written: $OUT_REV"
