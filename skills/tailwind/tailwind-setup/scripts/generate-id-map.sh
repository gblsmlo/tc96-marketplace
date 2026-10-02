#!/usr/bin/env bash
# Regenerates references/id-map.md for the three Tailwind skills, from tailwindcss*.
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

# Rewrites a note's own relative links to how they are seen from
# <family>/<skill>/references/ — nothing here points outside the project.
links() {
  sed -E -e 's#\]\(([^)/]+\.md)#](../../docs/\1#g'
}
HUB="$DOCS/tailwindcss.md"

scan() {
  for f in "$DOCS"/tailwindcss*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="tailwindcss" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /TW-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `TW-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `TW-[A-Z0-9]+-[0-9]+`/) {
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
  echo "generated-by: skills/tailwind/tailwind-setup/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`TW-*\`"
  echo
  echo "> An index, not a copy. **The TW-* rules are written for line 4.** On a project that stays on"
  echo "> line 3, only \`TW-SRC-01\`, \`TW-SRC-02\`, \`TW-UTIL-01\`, \`TW-A11Y-*\` and \`TW-COMP-*\` may be cited."
  echo "> Discover the line first — \`bash \${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh\`."
  echo "> Regenerate with \`bash skills/tailwind/tailwind-setup/scripts/generate-id-map.sh\`."
  echo
  echo "## Canonical IDs and the pairs that look like aliases"
  echo
  awk '/^### 6\.2/,/^### Full families/' "$HUB" | grep -vE '^### ' | cat -s | links || true
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

for s in setup build review; do
  cp "$TMP" "$FAMILY/tailwind-$s/references/id-map.md"
done
rm -f "$TMP"
echo "written into 3 skills ($(grep -c '^| `TW' "$FAMILY/tailwind-setup/references/id-map.md") IDs)"
