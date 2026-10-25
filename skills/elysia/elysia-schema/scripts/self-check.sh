#!/usr/bin/env bash
# elysia-schema self-check: validator libraries in use, then the AST scan (schema group).
#   bash self-check.sh [project-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"

echo "== Validators — t is built in; Zod/Valibot through Standard Schema need fileType() for uploads and mapJsonSchema for the spec"
if [ -f "$DIR/package.json" ]; then
  grep -E '"(elysia|zod|valibot|arktype|effect|@sinclair/typebox)"' "$DIR/package.json" | sed 's/^ */   /' || echo "   only elysia's t"
else
  echo "   no package.json in $DIR"
fi
RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../elysia-diagnose/scripts/elysia-scan.mjs" "$DIR" --only schema
cat <<'NEXT'

Not decided by the scan — prove with a request:
  · a numeric body field the client may send as a string .......... ELYSIA-TYPE-04
  · a field you return that the response schema does not declare .. normalize drops it
  · a required body on a GET ......................................... silently skipped
Then: bunx tsc --noEmit && bun test
NEXT
