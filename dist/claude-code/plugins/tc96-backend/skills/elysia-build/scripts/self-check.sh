#!/usr/bin/env bash
# elysia-build self-check: the installed line, then the AST scan (route + lifecycle groups).
#   bash self-check.sh [project-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"

echo "== Installed line — 1.4 is what the docs describe; @elysiajs/swagger is discontinued"
if [ -f "$DIR/package.json" ]; then
  grep -E '"(elysia|@elysia/[a-z-]+|@elysiajs/[a-z-]+|typescript)"' "$DIR/package.json" | sed 's/^ */   /' || echo "   no elysia dependency in $DIR/package.json"
else
  echo "   no package.json in $DIR"
fi

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../elysia-diagnose/scripts/elysia-scan.mjs" "$DIR" --only route,lifecycle
cat <<'NEXT'

Not decided by the scan — read for these:
  · an expected error the client must see typed is returned, not thrown .... ELYSIA-CORE-03
  · a recurring domain failure has its own .error() code ................... ELYSIA-CORE-08
  · the auth test hits a route of the CONSUMING instance without credentials  ELYSIA-LIFE-08
Then: bunx tsc --noEmit && bun test
NEXT
