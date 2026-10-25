#!/usr/bin/env bash
# elysia-openapi self-check: plugin and validator versions, then the AST scan (openapi + schema).
#   bash self-check.sh [project-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"
echo "== Plugin and validators — @elysia/openapi, not @elysiajs/swagger; Zod 4 needs no mapJsonSchema, Zod 3/Valibot/Effect do"
if [ -f "$DIR/package.json" ]; then
  grep -E '"(elysia|@elysia/openapi|@elysiajs/openapi|@elysiajs/swagger|zod|valibot|effect|@valibot/to-json-schema|zod-to-json-schema)"' "$DIR/package.json" | sed 's/^ */   /' || echo "   no openapi dependency"
else
  echo "   no package.json in $DIR"
fi
RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../elysia-diagnose/scripts/elysia-scan.mjs" "$DIR" --only openapi,schema
cat <<'NEXT'

The scan reads the code; the spec is the evidence. Dump /openapi/json through app.handle and run:
  node spec-lint.mjs openapi.json
NEXT
