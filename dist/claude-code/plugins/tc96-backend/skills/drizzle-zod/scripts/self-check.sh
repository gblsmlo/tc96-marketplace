#!/usr/bin/env bash
# drizzle-zod self-check: generator and Zod versions, then the zod-group AST scan.
#   bash self-check.sh [project-dir]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"

echo "== Versions — drizzle-orm 0.x: drizzle-zod · 1.0.0-rc: drizzle-orm/zod · zod 3.25: import from 'zod/v4'"
PKG="$DIR/package.json"
if [ -f "$PKG" ]; then
  grep -E '"drizzle-(orm|zod)"|"zod"' "$PKG" | sed 's/^ */   /' || echo "   no drizzle or zod dependency in $PKG"
  if grep -Eq '"zod": *"[\^~]?3\.' "$PKG"; then
    echo "   zod 3.x: every file that refines or extends a generated schema must import z from 'zod/v4'"
  fi
else
  echo "   no package.json in $DIR"
fi

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/../../drizzle-review/scripts/drizzle-scan.mjs" "$DIR" --only zod
echo
echo "Next: one assertion per rule on the schemas themselves, and tsc --noEmit — refinement keys are only checked by the compiler."
