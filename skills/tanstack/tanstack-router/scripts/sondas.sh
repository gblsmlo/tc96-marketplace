#!/usr/bin/env bash
# Sondas de TanStack Router — rota, navegação, search e loader. Uso: bash sondas.sh [dir]
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
ou_vazio() {  # imprime a entrada; se vier vazia, a mensagem
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nada)}"; fi
}

titulo "S1. \`to\` com string interpolada" "TSR-NAV-01 — params vão em params, query em search"
"${RG[@]}" 'to=\{?`[^`]*\$\{' "$DIR" || vazio

titulo "S2. navigate onde caberia Link" "TSR-NAV-02 — destino conhecido no render é <Link>"
"${RG[@]}" 'onClick=\{[^}]*navigate\(' "$DIR" || vazio

titulo "S3. \`to\` relativo sem \`from\`" "TSR-NAV-03 — sem from, a origem é / e não a rota atual"
"${RG[@]}" "to=[\"'{]\\.\\.?" "$DIR" | rg -v 'from' || vazio

titulo "S4. \`from\` como string literal" "TSR-NAV-04 — deve vir de Route.fullPath"
"${RG[@]}" "from=[\"']/" "$DIR" || vazio

titulo "S5. Rota que lê search sem validateSearch" "TSR-SEARCH-01"
"${RG[@]}" -l 'useSearch\(' "$DIR" 2>/dev/null | while read -r f; do
  rg -q 'validateSearch' "$f" || echo "   $f"
done | grep . || vazio

titulo "S6. Search lido fora do router" "TSR-SEARCH-02 — a fonte é useSearch"
"${RG[@]}" 'window\.location\.search|new URLSearchParams|useSearchParams' "$DIR" || vazio

titulo "S7. Atualização de search sem spread" "TSR-SEARCH-07 — objeto literal SUBSTITUI o search inteiro"
"${RG[@]}" 'search:\s*\{' "$DIR" | rg -v '\.\.\.' || vazio

titulo "S8. Zod v3 com .catch() sem fallback()" "TSR-SEARCH-05 — o tipo colapsa para unknown"
"${RG[@]}" -U 'validateSearch(?s:.{0,300}?)\.catch\(' "$DIR" | rg -v 'fallback' || vazio

titulo "S9. fetch em useEffect na rota" "TSR-LOAD-01 (apelido de REACT-EFFECT-06)"
"${RG[@]}" -U 'useEffect\((?s:.{0,300}?)fetch\(' "$DIR" || vazio

titulo "S10. loader sem signal" "TSR-LOAD-02"
"${RG[@]}" -U 'loader:\s*(async\s*)?\((?s:.{0,300}?)fetch\(' "$DIR" | rg -v 'signal' || vazio

titulo "S11. loaderDeps devolvendo o search inteiro" "TSR-LOAD-03"
"${RG[@]}" 'loaderDeps:\s*\(\s*\{\s*search\s*\}\s*\)\s*=>\s*search' "$DIR" || vazio

titulo "S12. beforeLoad buscando dado de tela" "TSR-LOAD-05 — é serial e bloqueia os loaders paralelos"
"${RG[@]}" -U 'beforeLoad:(?s:.{0,300}?)(fetch\(|queryClient\.(fetch|ensure))' "$DIR" || vazio

titulo "S13. Guarda por navigate em componente" "TSR-LOAD-06 — é throw redirect em beforeLoad"
"${RG[@]}" -U 'useEffect\((?s:.{0,200}?)navigate\(' "$DIR" || vazio

titulo "S14. Rota com loader sem errorComponent" "TSR-LOAD-09"
"${RG[@]}" -l 'loader:' "$DIR" 2>/dev/null | while read -r f; do
  rg -q 'errorComponent' "$f" || echo "   $f"
done | grep . || echo "   (todas têm errorComponent, ou há defaultErrorComponent no router)"

titulo "S15. Query no loader sem defaultPreloadStaleTime: 0" "TSR-LOAD-14 (canônico de TSR-NAV-08)"
if "${RG[@]}" -q 'ensureQueryData|fetchQuery' "$DIR" 2>/dev/null; then
  "${RG[@]}" 'defaultPreloadStaleTime' "$DIR" router.* 2>/dev/null \
    || echo "   loader usa Query e defaultPreloadStaleTime NÃO está declarado — dois caches decidindo frescor"
else echo "   (o loader não usa Query)"; fi

titulo "S16. Navegação que consome a rota atual sem replace" "TSR-NAV-09 — o voltar devolve a um estado consumido"
"${RG[@]}" -U 'navigate\(\{(?s:.{0,150}?)\}\)' "$DIR" | rg -v 'replace' | head -8 | ou_vazio

printf '\n\033[1m== Fim.\033[0m S5 e S15 são as que mais pagam: sem validateSearch não há tipo, e com dois caches o frescor é indefinido.\n'
