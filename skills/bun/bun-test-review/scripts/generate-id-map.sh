#!/usr/bin/env bash
# Regenerates references/id-map.md for the two Bun test skills, from the family docs
# (skills/bun/docs/bun-tests*.md). An index, not a copy: ID -> satellite -> section.
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
  for f in "$DOCS"/bun-tests*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="bun-tests" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /BUN-TEST-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `BUN-TEST-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `BUN-TEST-[0-9]+`/) {
          if ($0 ~ /MUST|NEVER/) rank = (sat == hub ? 1 : 2)
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
  echo "generated-by: skills/bun/bun-test-review/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`BUN-TEST-*\`"
  echo
  echo "> An index, not a copy: it says **where** the rule is declared, never what it says."
  echo "> The whole family lives in § 6 of the \`Bun - Tests\` hub, and the body in the owning satellite."
  echo "> It runs from \`BUN-TEST-01\` to \`BUN-TEST-29\` — **never invent an ID outside that range**."
  echo "> Regenerate with \`bash skills/bun/bun-test-review/scripts/generate-id-map.sh\`."
  echo
  echo "| ID | Declared in | Body in the satellite | Section of the body |"
  echo "| --- | --- | --- | --- |"
  scan | sort -t$'\t' -k1,1V -k2,2n \
    | awk -F'\t' -v hub="bun-tests" '
    function note(s) { return "[" (s in title ? title[s] : s) "](../../docs/" s ".md)" }
    NR == FNR { title[$1] = $2; next }
    {
      if (!( $1 in decl )) { decl[$1] = $3; order[++k] = $1 }
      if ($3 != hub && !( $1 in body )) { body[$1] = $3; sec[$1] = $4 }
    }
    END {
      for (i = 1; i <= k; i++) {
        id = order[i]
        printf "| `%s` | %s | %s | %s |\n", id, note(decl[id]),
          (id in body ? note(body[id]) : "— (hub only)"),
          (id in sec ? sec[id] : "—")
      }
    }' <(titles) -
} > "$TMP"

for s in build review; do
  cp "$TMP" "$FAMILY/bun-test-$s/references/id-map.md"
done
rm -f "$TMP"
echo "written into 2 skills ($(grep -c '^| `BUN-TEST' "$FAMILY/bun-test-build/references/id-map.md") IDs)"
