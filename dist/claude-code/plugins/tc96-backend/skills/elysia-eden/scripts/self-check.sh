#!/usr/bin/env bash
# elysia-eden self-check: strict + TypeScript in every tsconfig, one elysia version, then the AST scan (eden).
#   bash self-check.sh [workspace-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"

echo "== strict in every tsconfig (ELYSIA-APP-04) — the client and the server both need it"
found=0
while IFS= read -r f; do
  found=1
  if grep -qE '"strict"\s*:\s*true' "$f"; then echo "   ok      $f"
  elif grep -qE '"extends"' "$f"; then echo "   extends $f — check that the base sets strict: true"
  else echo "   MISSING $f — no strict: true; Eden degrades to any"; fi
done < <(find "$DIR" -name 'tsconfig*.json' -not -path '*/node_modules/*' 2>/dev/null)
[ "$found" = 0 ] && echo "   no tsconfig.json under $DIR"

echo
echo "== One elysia version across the workspace (ELYSIA-TYPE-11)"
ranges="$(grep -rhoE '"elysia"\s*:\s*"[^"]+"' --include=package.json --exclude-dir=node_modules "$DIR" 2>/dev/null | sed -E 's/.*:\s*"([^"]+)"/\1/' | sort -u)"
if [ -z "$ranges" ]; then echo "   no package.json declares elysia"
else
  echo "$ranges" | sed 's/^/   declared: /'
  [ "$(echo "$ranges" | wc -l)" -gt 1 ] && echo "   DIVERGENCE — several ranges declared; pin one (catalog or overrides)"
fi
installed="$(find "$DIR" -path '*/node_modules/elysia/package.json' 2>/dev/null | xargs -r grep -h '"version"' | sed -E 's/.*"([0-9][^"]*)".*/\1/' | sort -u)"
if [ -n "$installed" ]; then
  echo "$installed" | sed 's/^/   installed: /'
  [ "$(echo "$installed" | wc -l)" -gt 1 ] && echo "   DIVERGENCE — two installed copies; the client type becomes any without an error"
fi

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../elysia-diagnose/scripts/elysia-scan.mjs" "$DIR" --only eden,schema
cat <<'NEXT'

Not decided by the scan — prove with a test:
  · a 404 ends in isError, after one call (no 4xx retry) ........ ELYSIA-TYPE-09, -16
  · the status the UI switches on is in the client's error union  ELYSIA-TYPE-06, -15
Then: bunx tsc --noEmit in the server AND the client, and bun test
NEXT
