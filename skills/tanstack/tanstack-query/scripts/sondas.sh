#!/usr/bin/env bash
# TanStack Query probes — the defects that reading the component does not show.
# Usage: bash sondas.sh [dir]
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

titulo "S1. Is staleTime declared?" "TSQ-CACHE-01 — without it EVERY piece of data is born stale"
"${RG[@]}" 'staleTime' "$DIR" || echo "   NO staleTime anywhere — a request on every mount, tab focus and reconnect"

titulo "S2. A trigger turned off as a cure" "TSQ-CACHE-03 — hides the symptom and creates a contradictory policy"
"${RG[@]}" 'refetchOnWindowFocus:\s*false|refetchOnMount:\s*false|refetchOnReconnect:\s*false' "$DIR" || vazio
echo "   -> calibrate staleTime first; turning a trigger off is fine-tuning, never a cure"

titulo "S3. A variable missing from the queryKey" "TSQ-BASE-03 — the variants fight over the same entry"
"${RG[@]}" 'queryKey:\s*\[[^\]]*\]' "$DIR" | head -12 | ou_vazio
echo "   -> compare against the queryFn: every argument it uses has to be in the key"

titulo "S4. Mutation without invalidation" "TSQ-MUT-07"
"${RG[@]}" 'useMutation\(' "$DIR" -l | while read -r f; do
  rg -q 'invalidateQueries|setQueryData' "$f" || echo "   $f"
done | grep . || vazio

titulo "S5. Invalidation without returning the Promise" "TSQ-MUT-02 — the button comes back before the list changes"
"${RG[@]}" 'onS(uccess|ettled):\s*(\(|async\s*\()[^)]*\)\s*=>\s*\{[^}]*invalidateQueries' "$DIR" \
  | rg -v 'return|await' || vazio

titulo "S6. Optimistic update without the full cycle" "TSQ-MUT-10, TSQ-MUT-11"
"${RG[@]}" -l 'onMutate' "$DIR" 2>/dev/null | while read -r f; do
  falta=""
  rg -q 'cancelQueries' "$f" || falta="$falta cancelQueries"
  rg -q 'onError' "$f"       || falta="$falta onError(rollback)"
  rg -q 'onSettled' "$f"     || falta="$falta onSettled(invalidate)"
  [ -n "$falta" ] && echo "   $f — missing:$falta"
done | grep . || vazio
echo "   -> and check the signature: what onMutate returns arrives as the THIRD argument (v5)"

titulo "S7. Snapshot outside the mutation flow" "TSQ-MUT-11 — the rollback restores the wrong value"
"${RG[@]}" -U 'onMutate(?s:.{0,400}?)(useRef|let\s+\w+\s*=|window\.)' "$DIR" || vazio

titulo "S8. Writing in place instead of immutably" "TSQ-MUT-08 — React sees no change"
"${RG[@]}" -U 'setQueryData\((?s:.{0,200}?)\.(push|splice|sort)\(' "$DIR" || vazio

titulo "S9. Tracked properties turned off" "TSQ-CACHE-05 — a re-render on every isFetching"
"${RG[@]}" 'const\s*\{\s*data\s*,\s*\.\.\.' "$DIR" || vazio

titulo "S10. queryFn ignoring the signal" "TSQ-SSR-10 — N requests in flight in a type-ahead search"
"${RG[@]}" -U 'queryFn:\s*(async\s*)?\((?s:.{0,200}?)fetch\(' "$DIR" | rg -v 'signal' || vazio

titulo "S11. Infinite list without maxPages" "TSQ-PATTERN-08 — invalidating refetches EVERY page, serially"
"${RG[@]}" -l 'useInfiniteQuery' "$DIR" 2>/dev/null | while read -r f; do
  rg -q 'maxPages' "$f" || echo "   $f"
done | grep . || vazio

titulo "S12. The router holding the preload" "TSR-LOAD-14 — stale data while Query looks correct"
"${RG[@]}" 'defaultPreloadStaleTime' "$DIR" router.* 2>/dev/null || echo "   not declared — with Query in the loader, the default is a 30s preload"

printf '\n\033[1m== Done.\033[0m S1 and S6 pay off most. The fix is almost never turning a trigger off.\n'
