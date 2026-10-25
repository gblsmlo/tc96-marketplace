#!/usr/bin/env bash
# drizzle-review probes, P0–P7, before reading any code.   bash probes.sh [project-dir]
#
# In persistence the worst defects are invisible to reading: the schema looks complete, the query
# looks right, the test passes — and the relational API is switched off, or the migration
# generator diffs from a stale snapshot. P0, P2 and P3 are shell; P1 and P4–P7 are the AST scan.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"
[ -d "$DIR" ] || { echo "no such directory: $DIR"; exit 1; }
title() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

title "P0. Version line" "the docs describe 0.x; 1.0.0-rc changes relations, RQB filters and the Zod import"
if [ -f "$DIR/package.json" ]; then
  grep -E '"drizzle-(orm|kit|zod)"|"zod"' "$DIR/package.json" | sed 's/^ */   /' || echo "   no drizzle dependency"
else
  echo "   no package.json in $DIR"
fi

title "P2. Snapshot chain" "a hand-edited migration with a stale snapshot makes generate diff from the wrong state"
J="$(find "$DIR" -name '_journal.json' -not -path '*/node_modules/*' 2>/dev/null | head -1)"
if [ -n "$J" ]; then
  META="$(dirname "$J")"
  n_j="$(grep -o '"idx"' "$J" | wc -l | tr -d ' ')"
  n_s="$(find "$META" -maxdepth 1 -name '*_snapshot.json' | wc -l | tr -d ' ')"
  n_sql="$(find "$META/.." -maxdepth 1 -name '*.sql' | wc -l | tr -d ' ')"
  echo "   $J"
  echo "   journal entries: $n_j | snapshots: $n_s | .sql files: $n_sql"
  if [ "$n_j" != "$n_s" ] || [ "$n_j" != "$n_sql" ]; then
    echo "   DIVERGENCE — run \`drizzle-kit generate\` on a clean tree: if it proposes SQL, the snapshot chain is stale"
  fi
  # a migration listed in the journal whose .sql is missing, or a .sql the journal does not list
  for tag in $(grep -o '"tag": *"[^"]*"' "$J" | sed 's/.*"\([^"]*\)"$/\1/'); do
    [ -f "$META/../$tag.sql" ] || echo "   journal lists $tag, but $tag.sql is missing"
  done
  for f in "$META"/../*.sql; do
    [ -e "$f" ] || continue
    b="$(basename "$f" .sql)"; grep -q "\"$b\"" "$J" || echo "   $b.sql is not in the journal — written by hand?"
  done
else
  echo "   no meta/_journal.json — the project uses push, or keeps migrations elsewhere (DRZ-MIG-02, DRZ-MIG-04)"
fi

title "P3. push outside local" "DRZ-MIG-02 — push in a deploy path; DRZ-MIG-04 — push and migrate side by side"
hits="$(grep -rnE 'drizzle-kit +push|"db:push"' "$DIR/package.json" "$DIR"/.github/workflows "$DIR"/Dockerfile* "$DIR"/*.sh 2>/dev/null)"
if [ -n "$hits" ]; then echo "$hits" | sed 's/^/   /'; else echo "   (nothing)"; fi
# a package.json script that runs push, called by name from a workflow or Dockerfile
for s in $(grep -oE '"[A-Za-z0-9:_-]+": *"[^"]*drizzle-kit +push' "$DIR/package.json" 2>/dev/null | sed -E 's/^"([^"]+)".*/\1/'); do
  calls="$(grep -rnE "(bun|npm|pnpm|yarn) +(run +)?$s\b" "$DIR"/.github/workflows "$DIR"/Dockerfile* "$DIR"/*.sh 2>/dev/null)"
  [ -n "$calls" ] && echo "$calls" | sed "s/^/   script \"$s\" (drizzle-kit push) called from: /"
done
if grep -qE 'drizzle-kit +push' "$DIR/package.json" 2>/dev/null && grep -qE 'drizzle-kit +(migrate|generate)' "$DIR/package.json" 2>/dev/null; then
  echo "   push AND generate/migrate both scripted — which one owns which environment? (DRZ-MIG-04)"
fi

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
title "P1, P4–P7. AST scan" "P1 = DRZ-REL-05 (stop if it fires) · P4 schema · P5 query · P6 mutation · P7 zod"
if [ -z "$RUN" ]; then
  echo "   SKIPPED: needs node or bun on PATH — read the code for these by hand, and say so in the report"
else
  "$RUN" "$HERE/drizzle-scan.mjs" "$DIR" --only schema,query,mutation,zod | sed 's/^/   /'
fi

printf '\n\033[1m== Done.\033[0m If DRZ-REL-05 fired: STOP and report it first — with the relational API off, the hand-built reads are consequences.\n'
printf 'P8 (the live integration tests) needs a running database — declare it if you did not run it.\n'
