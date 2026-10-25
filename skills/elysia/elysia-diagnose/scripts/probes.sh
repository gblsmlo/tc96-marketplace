#!/usr/bin/env bash
# elysia-diagnose probes — why a hook or plugin does not affect a route.   bash probes.sh [project-dir]
#
# The scan points at shapes (order, scope, dedup, phase); the proof is a test on the CONSUMING
# instance (references/probes-and-proof.md).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"
[ -d "$DIR" ] || { echo "no such directory: $DIR"; exit 1; }

echo "== Installed line"
if [ -f "$DIR/package.json" ]; then
  grep -E '"(elysia|@elysia/[a-z-]+|@elysiajs/[a-z-]+)"' "$DIR/package.json" | sed 's/^ */   /' || echo "   no elysia dependency"
else
  echo "   no package.json in $DIR"
fi

echo
echo "== Plugins and where they are used (a plugin used by 2+ instances needs a name)"
grep -rnE "new Elysia\(\{[^}]*name:" "$DIR" --include=*.ts --exclude-dir=node_modules 2>/dev/null | sed 's/^/   /' | head -20 || true

RUN=""
command -v node >/dev/null 2>&1 && RUN=node
[ -z "$RUN" ] && command -v bun >/dev/null 2>&1 && RUN=bun
if [ -z "$RUN" ]; then echo "SKIPPED: the AST scan needs node or bun on PATH"; exit 0; fi
echo
"$RUN" "$HERE/elysia-scan.mjs" "$DIR" --only lifecycle,route
cat <<'NEXT'

Order before scope: an ELYSIA-CORE-01 finding explains the symptom before any scope finding does.
Proof: a test on the CONSUMING instance through app.handle(new Request('http://localhost/...')).
NEXT
