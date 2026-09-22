#!/usr/bin/env bash
# Sondas de TanStack Query — os defeitos que a leitura do componente não mostra.
# Uso: bash sondas.sh [dir]
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }

titulo "S1. staleTime declarado?" "TSQ-CACHE-01 — sem ele TODO dado nasce stale"
"${RG[@]}" 'staleTime' "$DIR" || echo "   NENHUM staleTime na base — rede a cada montagem, foco de aba e reconexão"

titulo "S2. Gatilho desligado como remédio" "TSQ-CACHE-03 — apaga o sintoma e cria política contraditória"
"${RG[@]}" 'refetchOnWindowFocus:\s*false|refetchOnMount:\s*false|refetchOnReconnect:\s*false' "$DIR" || vazio
echo "   → calibre staleTime primeiro; desligar gatilho é ajuste fino, nunca remédio"

titulo "S3. Variável fora da queryKey" "TSQ-BASE-03 — as variações disputam a mesma entrada"
"${RG[@]}" 'queryKey:\s*\[[^\]]*\]' "$DIR" | head -12 || vazio
echo "   → compare com a queryFn: todo argumento que ela usa precisa estar na key"

titulo "S4. Mutation sem invalidação" "TSQ-MUT-07"
"${RG[@]}" 'useMutation\(' "$DIR" -l | while read -r f; do
  rg -q 'invalidateQueries|setQueryData' "$f" || echo "   $f"
done | grep . || vazio

titulo "S5. Invalidação sem return da Promise" "TSQ-MUT-02 — o botão volta antes da lista mudar"
"${RG[@]}" 'onS(uccess|ettled):\s*(\(|async\s*\()[^)]*\)\s*=>\s*\{[^}]*invalidateQueries' "$DIR" \
  | rg -v 'return|await' || vazio

titulo "S6. Update otimista sem ciclo completo" "TSQ-MUT-10, TSQ-MUT-11"
"${RG[@]}" -l 'onMutate' "$DIR" 2>/dev/null | while read -r f; do
  falta=""
  rg -q 'cancelQueries' "$f" || falta="$falta cancelQueries"
  rg -q 'onError' "$f"       || falta="$falta onError(rollback)"
  rg -q 'onSettled' "$f"     || falta="$falta onSettled(invalidate)"
  [ -n "$falta" ] && echo "   $f — falta:$falta"
done | grep . || vazio
echo "   → e confira a assinatura: o retorno de onMutate chega como TERCEIRO argumento (v5)"

titulo "S7. Snapshot fora do fluxo da mutation" "TSQ-MUT-11 — rollback restaura valor errado"
"${RG[@]}" -U 'onMutate(?s:.{0,400}?)(useRef|let\s+\w+\s*=|window\.)' "$DIR" || vazio

titulo "S8. Escrita no lugar em vez de imutável" "TSQ-MUT-08 — o React não vê mudança"
"${RG[@]}" -U 'setQueryData\((?s:.{0,200}?)\.(push|splice|sort)\(' "$DIR" || vazio

titulo "S9. Tracked properties desligadas" "TSQ-CACHE-05 — re-render a cada isFetching"
"${RG[@]}" 'const\s*\{\s*data\s*,\s*\.\.\.' "$DIR" || vazio

titulo "S10. queryFn ignorando o signal" "TSQ-SSR-10 — N requisições em voo na busca por digitação"
"${RG[@]}" -U 'queryFn:\s*(async\s*)?\((?s:.{0,200}?)fetch\(' "$DIR" | rg -v 'signal' || vazio

titulo "S11. Lista infinita sem maxPages" "TSQ-PATTERN-08 — invalidar refaz TODAS as páginas em série"
"${RG[@]}" -l 'useInfiniteQuery' "$DIR" 2>/dev/null | while read -r f; do
  rg -q 'maxPages' "$f" || echo "   $f"
done | grep . || vazio

titulo "S12. Router segurando o preload" "TSR-LOAD-14 — dado velho com o Query aparentemente certo"
"${RG[@]}" 'defaultPreloadStaleTime' "$DIR" router.* 2>/dev/null || echo "   não declarado — com Query no loader, o padrão é 30s de preload"

printf '\n\033[1m== Fim.\033[0m S1 e S6 são as que mais pagam. A correção quase nunca é desligar gatilho.\n'
