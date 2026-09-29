#!/usr/bin/env bash
# TanStack Router probes — route, navigation, search and loader. Usage: bash sondas.sh [dir]
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "S1. \`to\` com string interpolada" "TSR-NAV-01 — params go in params, query in search"
"${RG[@]}" 'to=\{?`[^`]*\$\{' "$DIR" || vazio

titulo "S2. navigate where a Link would do" "TSR-NAV-02 — a destination known at render time is a <Link>"
"${RG[@]}" 'onClick=\{[^}]*navigate\(' "$DIR" || vazio

titulo "S3. \`to\` relativo sem \`from\`" "TSR-NAV-03 — without from, the origin is / and not the current route"
"${RG[@]}" "to=[\"'{]\\.\\.?" "$DIR" | rg -v 'from' || vazio

titulo "S4. \`from\` como string literal" "TSR-NAV-04 — it must come from Route.fullPath"
"${RG[@]}" "from=[\"']/" "$DIR" || vazio

titulo "S5. Route reading search without validateSearch" "TSR-SEARCH-01"
"${RG[@]}" -l 'useSearch\(' "$DIR" 2>/dev/null | while read -r f; do
  rg -q 'validateSearch' "$f" || echo "   $f"
done | grep . || vazio

titulo "S6. Search read outside the router" "TSR-SEARCH-02 — the source is useSearch"
"${RG[@]}" 'window\.location\.search|new URLSearchParams|useSearchParams' "$DIR" || vazio

titulo "S7. Updating search without a spread" "TSR-SEARCH-07 — an object literal REPLACES the whole search"
"${RG[@]}" 'search:\s*\{' "$DIR" | rg -v '\.\.\.' || vazio

titulo "S8. Zod v3 with .catch() and no fallback()" "TSR-SEARCH-05 — the type collapses to unknown"
"${RG[@]}" -U 'validateSearch(?s:.{0,300}?)\.catch\(' "$DIR" | rg -v 'fallback' || vazio

titulo "S9. fetch in a useEffect inside the route" "TSR-LOAD-01 (alias of REACT-EFFECT-06)"
"${RG[@]}" -U 'useEffect\((?s:.{0,300}?)fetch\(' "$DIR" || vazio

titulo "S10. loader without signal" "TSR-LOAD-02"
"${RG[@]}" -U 'loader:\s*(async\s*)?\((?s:.{0,300}?)fetch\(' "$DIR" | rg -v 'signal' || vazio

titulo "S11. loaderDeps returning the whole search" "TSR-LOAD-03"
"${RG[@]}" 'loaderDeps:\s*\(\s*\{\s*search\s*\}\s*\)\s*=>\s*search' "$DIR" || vazio

titulo "S12. beforeLoad fetching screen data" "TSR-LOAD-05 — it is serial and blocks the parallel loaders"
"${RG[@]}" -U 'beforeLoad:(?s:.{0,300}?)(fetch\(|queryClient\.(fetch|ensure))' "$DIR" || vazio

titulo "S13. A guard via navigate in a component" "TSR-LOAD-06 — it is throw redirect in beforeLoad"
"${RG[@]}" -U 'useEffect\((?s:.{0,200}?)navigate\(' "$DIR" || vazio

titulo "S14. Route with a loader and no errorComponent" "TSR-LOAD-09"
"${RG[@]}" -l 'loader:' "$DIR" 2>/dev/null | while read -r f; do
  rg -q 'errorComponent' "$f" || echo "   $f"
done | grep . || echo "   (they all have errorComponent, or the router has a defaultErrorComponent)"

titulo "S15. Query in the loader without defaultPreloadStaleTime: 0" "TSR-LOAD-14 (canonical for TSR-NAV-08)"
if "${RG[@]}" -q 'ensureQueryData|fetchQuery' "$DIR" 2>/dev/null; then
  "${RG[@]}" 'defaultPreloadStaleTime' "$DIR" router.* 2>/dev/null \
    || echo "   the loader uses Query and defaultPreloadStaleTime is NOT declared — two caches deciding freshness"
else echo "   (the loader does not use Query)"; fi

titulo "S16. Navigation that consumes the current route without replace" "TSR-NAV-09 — back returns to a consumed state"
"${RG[@]}" -U 'navigate\(\{(?s:.{0,150}?)\}\)' "$DIR" | rg -v 'replace' | head -8 | ou_vazio

printf '\n\033[1m== Done.\033[0m S5 and S15 pay off most: without validateSearch there is no type, and with two caches freshness is undefined.\n'
