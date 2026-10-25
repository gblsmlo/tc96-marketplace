#!/usr/bin/env bash
# drizzle-mutation self-check: the version line, then the mutation-group AST scan.
#   bash self-check.sh [project-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"

echo "== Version line — the verified write behaviour was executed on drizzle-orm 0.45.4"
PKG="$DIR/package.json"
if [ -f "$PKG" ]; then
  grep -E '"drizzle-(orm|kit)"' "$PKG" | sed 's/^ */   /' || echo "   no drizzle dependency in $PKG"
else
  echo "   no package.json in $DIR"
fi

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../drizzle-review/scripts/drizzle-scan.mjs" "$DIR" --only mutation
echo
echo "Next: a test per guarantee (replay, overdraft, empty patch, other owner's rows) — the scan sees shapes, not races."
