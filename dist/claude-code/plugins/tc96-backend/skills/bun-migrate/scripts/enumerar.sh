#!/usr/bin/env bash
# Enumerates the node:* modules used by your code AND by the transitive dependencies.
# Usage: bash enumerar.sh [code-dir]
#
# BUN-SYS-07: this is the step you cannot skip. The second search is the one that changes the plan.
set -uo pipefail

ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "1. In your own code" "what you control"
saida=$({ rg -no "from ['\"]node:[a-z_/]+" "$DIR" 2>/dev/null; rg -no "require\(['\"]node:[a-z_/]+" "$DIR" 2>/dev/null; } \
  | sed -E "s/.*node:([a-z_/]+).*/\1/" | sort | uniq -c | sort -rn)
[ -n "$saida" ] && echo "$saida" | sed 's|^|   |' || echo "   (no node:* module in the code)"

titulo "2. In the transitive dependencies" "the half that usually goes missing"
if [ -d node_modules ]; then
  rg -ho "require\(['\"](node:)?(async_hooks|worker_threads|crypto|vm|cluster|dgram|inspector|perf_hooks|v8|repl|child_process|http2|tls|net)['\"]" node_modules 2>/dev/null \
    | sed -E "s/.*['\"](node:)?([a-z_2]+)['\"].*/\2/" | sort | uniq -c | sort -rn | head -20 | sed 's|^|   |' | ou_vazio "(nothing)"
else
  echo "   node_modules missing — run \`bun install\` first; without it the enumeration is partial"
fi

titulo "3. The four gaps that matter" "check each one on the official page (BUN-CORE-05)"
cat <<'FIM'
   async_hooks .... a stub that DOES NOT THROW: the code runs and the result is silently wrong
   crypto ......... complete in almost everything, with per-cipher gaps — check the one you use
   worker_threads . partial
   vm / cluster ... partial or absent

   "It works in Node" is NOT evidence that it works in Bun.
FIM

titulo "4. What does not go to production"
rg -n --no-messages 'node-gyp|\.node"' package.json 2>/dev/null | sed 's|^|   |' | ou_vazio "(no visible native addon)"

titulo "5. Container" "shutting down without dropping a request"
ls Dockerfile* 2>/dev/null | sed 's|^|   |' | ou_vazio "no Dockerfile"
[ -f Dockerfile ] && rg -n --no-messages 'FROM|CMD|ENTRYPOINT|STOPSIGNAL|--smol' Dockerfile | sed 's|^|   |'
echo "   -> without SIGTERM handling, the container exits mid-request"

printf '\n\033[1m== Done.\033[0m Search 2 decides whether the migration is viable, and it never shows up in the project code.\n'
