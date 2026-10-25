#!/usr/bin/env bash
# Enumerates the node:* modules used by your code AND by the transitive dependencies.
# Usage: bash enumerate.sh [code-dir]   (run it from the project root, where node_modules lives)
#
# BUN-SYS-07: this is the step you cannot skip. The second search is the one that changes the plan.
set -uo pipefail

or_empty() {  # prints the input; when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s\n' "$out"; else echo "   ${1:-(nothing)}"; fi
}
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
title() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

# Prints every match of an extended regex under a path, one per line, without file names.
# ripgrep when it is there, grep otherwise — so the enumeration never depends on one tool.
matches() {  # matches <regex> <path> [extra rg glob]
  if command -v rg >/dev/null 2>&1; then
    rg -o --no-filename --no-messages -e "$1" "$2"
  else
    grep -rhoE --include='*.js' --include='*.cjs' --include='*.mjs' --include='*.ts' --include='*.tsx' \
      -e "$1" "$2" 2>/dev/null
  fi
}

LEGACY='assert|async_hooks|buffer|child_process|cluster|crypto|dgram|dns|events|fs|http|http2|https|inspector|module|net|os|path|perf_hooks|readline|repl|stream|timers|tls|tty|url|util|v8|vm|worker_threads|zlib'

title "1. In your own code" "what you control — node:* and the legacy bare names"
out=$({ matches "(from|require\()[[:space:]]*['\"]node:[a-z_/]+" "$DIR";
        matches "(from|require\()[[:space:]]*['\"]($LEGACY)['\"]" "$DIR"; } \
  | sed -E "s/.*['\"](node:)?([a-z_/0-9]+)['\"]?.*/\2/" | sort | uniq -c | sort -rn)
[ -n "$out" ] && echo "$out" | sed 's|^|   |' || echo "   (no node:* module in the code)"

title "2. In the transitive dependencies" "the half that usually goes missing"
if [ -d node_modules ]; then
  RISKY='async_hooks|worker_threads|crypto|vm|cluster|dgram|inspector|perf_hooks|v8|repl|child_process|http2|https|tls|net|module'
  matches "(from|require\()[[:space:]]*['\"](node:)?($RISKY)['\"]" node_modules \
    | sed -E "s/.*['\"](node:)?([a-z_0-9]+)['\"].*/\2/" | sort | uniq -c | sort -rn | head -20 \
    | sed 's|^|   |' | or_empty "(no risky node:* module in node_modules)"
  echo "   -- which package each one comes from (the packages to look up with \`bun why\`):"
  if command -v rg >/dev/null 2>&1; then
    rg -l --no-messages -e "(from|require\()[[:space:]]*['\"](node:)?(async_hooks|crypto|cluster|worker_threads|vm|v8|perf_hooks)['\"]" node_modules
  else
    grep -rlE --include='*.js' --include='*.cjs' --include='*.mjs' \
      "(from|require\()[[:space:]]*['\"](node:)?(async_hooks|crypto|cluster|worker_threads|vm|v8|perf_hooks)['\"]" node_modules 2>/dev/null
  fi | sed -E 's#^node_modules/((@[^/]+/)?[^/]+).*#\1#' | sort -u | head -20 | sed 's|^|   |' | or_empty
  echo "   -> each one is a CANDIDATE, not proof: grep sees comments and dead code, and misses require(variable)"
else
  echo "   node_modules missing — run \`bun install\` first; without it the enumeration is PARTIAL"
fi

title "3. The four gaps that matter" "check each one on the official page (BUN-CORE-05)"
cat <<'EOF'
   async_hooks .... createHook / executionAsyncId are stubs that DO NOT THROW: the code runs and
                    the result is silently wrong (BUN-SYS-09). AsyncLocalStorage works.
   crypto ......... complete in almost everything, with per-cipher gaps — check the one you use (BUN-SYS-08)
   worker_threads . partial
   vm / cluster ... partial; cluster balances HTTP between workers only on Linux

   "It works in Node" is NOT evidence that it works in Bun.
EOF

title "4. What does not go to production"
{ grep -nE 'node-gyp|\.node"|"gypfile"' package.json 2>/dev/null || true; } | sed 's|^|   |' | or_empty "(no visible native addon)"

title "5. Container" "shutting down without dropping a request — BUN-SYS-11, BUN-SYS-12"
ls Dockerfile* 2>/dev/null | sed 's|^|   |' | or_empty "no Dockerfile"
for f in Dockerfile*; do
  [ -f "$f" ] || continue
  grep -nE '^[[:space:]]*(FROM|CMD|ENTRYPOINT|STOPSIGNAL|USER)|--smol' "$f" | sed "s|^|   $f:|"
  # shell form: CMD/ENTRYPOINT not followed by a JSON array
  grep -nE '^[[:space:]]*(CMD|ENTRYPOINT)[[:space:]]+[^[[:space:]]' "$f" | sed "s|^|   ✗ SHELL FORM $f:|"
  grep -nE '^[[:space:]]*FROM[[:space:]]+[^[:space:]]+:latest|^[[:space:]]*FROM[[:space:]]+oven/bun[[:space:]]*$' "$f" | sed "s|^|   ✗ UNPINNED $f:|"
  grep -qE '^[[:space:]]*USER[[:space:]]' "$f" || echo "   ✗ $f: no USER line — the process runs as root"
done
echo "   -> a shell-form CMD/ENTRYPOINT makes /bin/sh -c PID 1, and the orchestrator's SIGTERM may never reach bun:"
echo "      use the exec form, ENTRYPOINT [\"bun\", \"run\", \"--no-env-file\", \"src/index.ts\"]"
echo "   -> and without a SIGTERM listener that drains and calls process.exit(), the container exits mid-request"
{ grep -rnE "process\.on\(['\"]SIGTERM" "$DIR" 2>/dev/null || true; } | sed 's|^|   |' | or_empty "NO SIGTERM listener in $DIR"

printf '\n\033[1m== Done.\033[0m Search 2 decides whether the migration is viable, and it never shows up in the project code.\n'
