#!/usr/bin/env bash
# Regenerates references/id-map.md for every Elysia skill, from the family docs (skills/elysia/docs).
# An index, not a copy: ID -> declared in -> body in which satellite -> section. Authoring tool only.
set -euo pipefail

FAMILY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="${1:-$FAMILY/docs}"
HUB="$DOCS/elysia.md"

titles() {
  awk 'FNR == 1 { name = FILENAME; sub(/.*\//, "", name); sub(/\.md$/, "", name) }
       /^titulo: / { print name "\t" substr($0, 9); nextfile }' "$DOCS"/elysia*.md
}

scan() {
  for f in "$DOCS"/elysia*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="elysia" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      {
        if ($0 !~ /^\| `ELYSIA-[A-Z]+-[0-9]+`/) next
        match($0, /ELYSIA-[A-Z]+-[0-9]+/); id = substr($0, RSTART, RLENGTH)
        rank = ($0 ~ /\*\*(MUST|NEVER)\*\*/) ? (sat == hub ? 2 : 1) : 3
        printf "%s\t%d\t%s\t%s\n", id, rank, sat, (h2 == "" ? "—" : h2)
      }' "$f"
  done
}

TMP="$(mktemp)"
{
  echo "---"
  echo "generated-by: skills/elysia/elysia-diagnose/scripts/generate-id-map.sh"
  echo "generated-at: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`ELYSIA-*\`"
  echo
  echo "> An index, not a copy: it says **where** a rule's body lives, never what it says."
  echo "> Regenerate with \`bash skills/elysia/elysia-diagnose/scripts/generate-id-map.sh\` — the same file is written into every Elysia skill."
  echo
  echo "## Canonical IDs and partial aliases"
  echo
  awk '/^### 6\.2/{on=1; next} /^### Full families/{on=0} on' "$HUB" | cat -s | sed -E 's#\]\(([a-z0-9-]+\.md)#](../../../docs/elysia/\1#g'
  echo
  echo "## Full index"
  echo
  echo "| ID | Body in | Section |"
  echo "| --- | --- | --- |"
  scan | sort -t$'\t' -k1,1V -k2,2n | awk -F'\t' -v hub="elysia" '
    NR == FNR { title[$1] = $2; next }
    function note(s) { return "[" (s in title ? title[s] : s) "](../../../docs/elysia/" s ".md)" }
    {
      if (!($1 in first)) { first[$1] = 1; order[++k] = $1 }
      # the body is the satellite that states the rule; the hub owns only APP-*
      if (!($1 in body) && ($3 != hub || $1 ~ /^ELYSIA-APP-/)) { body[$1] = $3; sec[$1] = $4 }
    }
    END { for (i = 1; i <= k; i++) { id = order[i]; printf "| `%s` | %s | %s |\n", id, note(body[id]), sec[id] } }
  ' <(titles) -
} > "$TMP"

n="$(grep -c '^| `ELYSIA' "$TMP")"
for s in "$FAMILY"/elysia-*/; do
  [ -f "$s/SKILL.md" ] || continue
  mkdir -p "$s/references"
  cp "$TMP" "$s/references/id-map.md"
done
rm -f "$TMP"
echo "written into $(ls -d "$FAMILY"/elysia-*/ | wc -l) skills ($n IDs)"
