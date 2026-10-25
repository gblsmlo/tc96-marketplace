#!/usr/bin/env bash
# drizzle-query self-check: the version line, then the query-group AST scan.
#   bash self-check.sh [project-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"

echo "== Version line — 0.x is the line the docs describe; 1.0.0-rc/beta changes relations and RQB filters"
PKG="$DIR/package.json"
if [ -f "$PKG" ]; then
  grep -E '"drizzle-(orm|kit|zod)"|"zod"|"typescript"' "$PKG" | sed 's/^ */   /' || echo "   no drizzle dependency in $PKG"
else
  echo "   no package.json in $DIR"
fi

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../drizzle-review/scripts/drizzle-scan.mjs" "$DIR" --only query,schema
echo
echo "Next: count statements in a test (references/patterns.md, pattern 7) — the scan sees shapes, not query counts."
