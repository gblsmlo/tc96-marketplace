#!/usr/bin/env bash
# TanStack Query and Router probes: the defects that reading one component does not show.
#   bash probes.sh [dir] [all|query|router]
# Each hit is a candidate with its rule ID; confirm it in the code before reporting it.
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
GROUP="${2:-all}"
command -v rg >/dev/null 2>&1 || { echo "SKIPPED: the probes need ripgrep (rg) on PATH"; exit 0; }
command -v perl >/dev/null 2>&1 || { echo "SKIPPED: the probes need perl on PATH"; exit 0; }
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx -n --no-messages --no-heading)
HITS_FILE="$(mktemp)"; trap 'rm -f "$HITS_FILE"' EXIT

probe() { printf '\n== %s [%s] %s\n' "$1" "$2" "$3"; }
show() {  # prints up to 10 lines of hits, or "ok"
  local out; out="$(cat)"
  if [ -n "$out" ]; then
    printf '%s\n' "$out" | head -10 | sed 's/^/   /'
    echo x >> "$HITS_FILE"
  else
    echo "   ok"
  fi
}
files() { "${RG[@]}" -l "$1" "$DIR" 2>/dev/null; }
# perl over each file: prints "file:line: message" for every block match the script reports
blocks() { local f; for f in $(files "$1"); do perl -0777 -ne "$2" "$f"; done; }
LINE='sub ln { my ($s, $p) = @_; return 1 + (substr($s, 0, $p) =~ tr/\n//) }'

if [ "$GROUP" = all ] || [ "$GROUP" = query ]; then
  probe Q1 TSQ-CACHE-01 "query with no staleTime and no staleTime default: born stale"
  if "${RG[@]}" -U -l 'defaultOptions(?s:.{0,200}?)staleTime' "$DIR" | grep -q .; then echo "   ok (QueryClient defaultOptions sets staleTime)"
  else blocks '(queryOptions|useQuery|useSuspenseQuery|useInfiniteQuery|infiniteQueryOptions)\(' "$LINE"'
    while (/\b(queryOptions|useQuery|useSuspenseQuery|useInfiniteQuery|infiniteQueryOptions)\(\s*\{(.{0,800}?)\n\s*\}\)/sg) {
      print "$ARGV:" . ln($_, $-[0]) . ": $1 without staleTime\n" unless $2 =~ /staleTime/;
    }' | show; fi

  probe Q2 TSQ-CACHE-03 "refetch trigger switched off as a remedy"
  "${RG[@]}" 'refetchOn(WindowFocus|Mount|Reconnect):\s*false' "$DIR" | show

  probe Q3 TSQ-BASE-03 "a variable the queryFn reads is missing from the queryKey"
  blocks 'queryKey' "$LINE"'
    while (/queryKey:\s*(\[[^\]]*\])(.{0,500}?)(?=queryKey:|\z)/sg) {
      my ($k, $b, $p) = ($1, $2, $-[0]); my %seen;
      $seen{$1}++ while $b =~ /(?:const|let|var)\s+(\w+)/g;
      while ($b =~ /\$\{\s*([A-Za-z_]\w*)/g) {
        my $v = $1; next if $seen{$v}++ || $v =~ /^(encodeURIComponent|String|Number|JSON|pageParam|signal|meta)$/;
        print "$ARGV:" . ln($_, $p) . ": key $k does not contain `$v`\n" unless $k =~ /\b\Q$v\E\b/;
      }
    }' | show

  probe Q4 TSQ-BASE-05 "queryFn on fetch without a thrown error for !res.ok"
  blocks 'queryFn' "$LINE"'
    while (/queryFn:(.{0,400}?)(?=queryFn:|\n\s*\}\)|\z)/sg) {
      my ($b, $p) = ($1, $-[0]);
      print "$ARGV:" . ln($_, $p) . ": no ok/status check before parsing\n"
        if $b =~ /\b(fetch|request)\(/ && $b !~ /\.ok\b|\.status\b|throw\b/;
    }' | show

  probe Q5 TSQ-MUT-07 "mutation that never invalidates nor writes the cache"
  for f in $(files 'useMutation\('); do rg -q 'invalidateQueries|setQueryData|refetchQueries' "$f" || echo "$f"; done | show

  probe Q13 TSQ-MUT-07 "invalidation or cache write whose key root matches no queryKey"
  roots="$("${RG[@]}" --no-filename --no-line-number "queryKey:\s*\[\s*['\"][^'\"]+" "$DIR" \
    | grep -vE '(invalidate|refetch|cancel|remove|reset)Queries' \
    | sed -E "s/.*queryKey:[[:space:]]*\[[[:space:]]*['\"]([^'\"]+).*/\1/" | sort -u)"
  "${RG[@]}" "(invalidateQueries|refetchQueries|cancelQueries)\(\{\s*queryKey:\s*\[\s*['\"][^'\"]+|setQueryData[^(]*\(\s*\[\s*['\"][^'\"]+" "$DIR" \
    | while IFS= read -r hit; do
        root="$(printf '%s' "$hit" | sed -E "s/.*(queryKey:[[:space:]]*|setQueryData[^(]*\([[:space:]]*)\[[[:space:]]*['\"]([^'\"]+).*/\2/")"
        printf '%s\n' "$roots" | grep -qx -- "$root" || printf '%s  <- no queryKey starts with '"'"'%s'"'"'\n' "$hit" "$root"
      done | show

  probe Q6 TSQ-MUT-02 "invalidation inside a callback that does not return or await it"
  blocks 'invalidateQueries' "$LINE"'
    while (/on(Success|Settled|Error):\s*(?:async\s*)?\([^)]*\)\s*=>\s*\{(.{0,400}?)\n\s*\},?/sg) {
      my ($b, $p) = ($2, $-[2]);
      print "$ARGV:" . ln($_, $p + index($b, "invalidateQueries")) . ": invalidateQueries is neither returned nor awaited\n"
        if $b =~ /invalidateQueries/ && $b !~ /(return|await)\b[^;]*invalidateQueries|return\s+Promise\.all|await\s+Promise\.all/;
    }' | show

  probe Q7 "TSQ-MUT-10/12" "optimistic update without the full cycle"
  for f in $(files 'onMutate'); do
    miss=""
    rg -q 'cancelQueries' "$f" || miss="$miss cancelQueries"
    rg -q 'onError' "$f" || miss="$miss onError-rollback"
    rg -q 'onSettled' "$f" || miss="$miss onSettled-invalidate"
    [ -n "$miss" ] && echo "$f: missing$miss"
  done | show

  probe Q8 TSQ-MUT-11 "snapshot kept outside onMutate's return, or rollback read from the wrong argument"
  blocks 'onMutate' "$LINE"'
    while (/onMutate(.{0,400}?)(\w+)\.current\s*=/sg) { print "$ARGV:" . ln($_, $-[0]) . ": snapshot stored in $2.current\n" }
    while (/onError:\s*(?:async\s*)?\(\s*\w*\s*,\s*\w*\s*,\s*\w*\s*,\s*(\w+)\s*\)(.{0,200})/sg) {
      my ($c, $b, $p) = ($1, $2, $-[0]);
      print "$ARGV:" . ln($_, $p) . ": rollback reads the 4th argument `$c` (MutationFunctionContext); the snapshot is the 3rd\n"
        if $b =~ /\b\Q$c\E\??\.(?!client|meta|mutationKey)\w+/;
    }' | show

  probe Q9 TSQ-MUT-08 "cache written in place instead of immutably"
  blocks 'setQueryData' "$LINE"'
    while (/setQueryData[^(]*\((.{0,300}?)\.(push|splice|sort|reverse|unshift|pop|shift)\(/sg) { print "$ARGV:" . ln($_, $-[0]) . ": .$2() inside setQueryData\n" }' | show

  probe Q10 TSQ-CACHE-05 "rest spread on a query result switches off tracked properties"
  "${RG[@]}" 'const\s*\{[^}]*\.\.\.\w+\s*\}\s*=\s*use(Suspense)?(Infinite)?Query\(' "$DIR" | show

  probe Q11 TSQ-SSR-10 "queryFn that fetches without the AbortSignal"
  blocks 'queryFn' "$LINE"'
    while (/queryFn:(.{0,300}?)\b(fetch|request|axios\.\w+)\(/sg) {
      my ($b, $p) = ($1, $-[0]);
      print "$ARGV:" . ln($_, $p) . ": no signal passed\n" unless $b =~ /signal/;
    }' | show

  probe Q12 TSQ-PATTERN-08 "infinite query without maxPages"
  blocks 'useInfiniteQuery|infiniteQueryOptions' "$LINE"'
    while (/\b(useInfiniteQuery|infiniteQueryOptions)\(\s*\{(.{0,900}?)\n\s*\}\)/sg) {
      print "$ARGV:" . ln($_, $-[0]) . ": $1 without maxPages\n" unless $2 =~ /maxPages/;
    }' | show
fi

if [ "$GROUP" = all ] || [ "$GROUP" = router ]; then
  probe R1 TSR-NAV-01 "path built by interpolation instead of params/search"
  "${RG[@]}" "(to=\{\`|to:\s*\`|href=\{\`/)[^\`]*\\$\{" "$DIR" | show

  probe R2 TSR-NAV-02 "navigate() in onClick where a <Link> would do"
  "${RG[@]}" 'onClick=\{[^}]*navigate\(' "$DIR" | show

  probe R3 TSR-NAV-03 "relative to without from"
  blocks 'to=' "$LINE"'
    while (/<Link\b([^>]*?)>/sg) { my ($a, $p) = ($1, $-[0]);
      print "$ARGV:" . ln($_, $p) . ": relative to without from\n" if $a =~ /\bto=["\x27{]+\.\.?[\/"\x27]/ && $a !~ /\bfrom=/ }' | show

  probe R4 TSR-NAV-04 "from as a string literal instead of Route.fullPath"
  "${RG[@]}" "from[=:]\s*[\"']/" "$DIR" | show

  probe R5 TSR-SEARCH-01 "search read without validateSearch on the route"
  {
    "${RG[@]}" 'useSearch\([^)]*\)\s*as\s' "$DIR"
    for f in $(files 'createFileRoute|createRoute\('); do
      rg -q 'useSearch|loaderDeps:\s*\(\s*\{\s*search' "$f" && ! rg -q 'validateSearch' "$f" && echo "$f: route reads search, no validateSearch"
    done
  } | show

  probe R6 TSR-SEARCH-02 "search read outside the router"
  "${RG[@]}" 'window\.location\.search|new URLSearchParams\(\s*(window\.)?location|useSearchParams\(' "$DIR" | show

  probe R7 TSR-SEARCH-07 "search on the current route updated with an object literal (replaces every other key)"
  blocks 'search' "$LINE"'
    while (/(navigate\(\s*\{|<Link\b)(.{0,300}?)(\}\s*\)|\/?>)/sg) { my ($b, $p) = ($2, $-[0]);
      next unless $b =~ /search(:|=\{)\s*\{/;
      next if $b =~ /\bto[:=]\s*["\x27{]*\/[\w$]/;
      print "$ARGV:" . ln($_, $p) . ": search object literal with no new destination\n" }' | show

  probe R8 TSR-SEARCH-05 "Zod v3 .catch() in validateSearch without fallback()"
  if rg -q '"zod":\s*"[~^]?3' package.json 2>/dev/null; then
    blocks 'validateSearch' "$LINE"'while (/validateSearch(.{0,300}?)\.catch\(/sg) { print "$ARGV:" . ln($_, $-[0]) . ": .catch without fallback\n" unless $1 =~ /fallback/ }' | show
  else echo "   ok (not Zod v3)"; fi

  probe R9 "TSR-LOAD-01 (alias of REACT-EFFECT-06)" "first-render data fetched in useEffect"
  blocks 'useEffect' "$LINE"'while (/useEffect\((.{0,300}?)\b(fetch|request|axios\.\w+)\(/sg) { print "$ARGV:" . ln($_, $-[0]) . ": $2() inside useEffect\n" }' | show

  probe R10 TSR-LOAD-02 "loader fetching without the abort signal"
  blocks 'loader:' "$LINE"'while (/loader:(.{0,300}?)\b(fetch|request)\(/sg) { print "$ARGV:" . ln($_, $-[0]) . ": no signal\n" unless $1 =~ /signal|abortController/ }' | show

  probe R11 TSR-LOAD-03 "loaderDeps returning the whole search"
  "${RG[@]}" 'loaderDeps:\s*\(\s*\{\s*search\s*\}\s*\)\s*=>\s*(search\b|\(\{\s*\.\.\.search)' "$DIR" | show

  probe R12 TSR-LOAD-05 "beforeLoad fetching screen data (serial, blocks the loaders)"
  blocks 'beforeLoad' "$LINE"'while (/beforeLoad:(.{0,300}?)\b(fetch\(|request\(|queryClient\.(fetch|ensure|query\b|infiniteQuery\b)\w*\()/sg) { print "$ARGV:" . ln($_, $-[0]) . ": $2 in beforeLoad\n" }' | show

  probe R13 TSR-LOAD-06 "access guard as navigate() in an effect"
  blocks 'useEffect' "$LINE"'while (/useEffect\((.{0,200}?)navigate\(/sg) { print "$ARGV:" . ln($_, $-[0]) . ": navigate inside useEffect\n" }' | show

  probe R14 TSR-LOAD-09 "route with a loader and no errorComponent"
  if files 'defaultErrorComponent' | grep -q .; then echo "   ok (router declares defaultErrorComponent)"
  else for f in $(files 'loader:'); do rg -q 'errorComponent' "$f" || echo "$f"; done | show; fi

  probe R15 "TSR-LOAD-14 (canonical for TSR-NAV-08)" "loader uses Query but the router keeps its own 30 s preload cache"
  if files 'ensureQueryData|prefetchQuery|fetchQuery|queryClient\.(query|infiniteQuery)\(' | grep -q .; then
    files 'defaultPreloadStaleTime:\s*0\b' | grep -q . && echo "   ok" \
      || echo "$DIR: loaders use Query and defaultPreloadStaleTime: 0 is not set" | show
  else echo "   ok (no loader uses Query)"; fi

  probe R16 TSR-NAV-09 "post-login/post-submit navigation without replace (candidate)"
  blocks 'navigate\(' "$LINE"'while (/(login|submit|onSuccess|signIn)(.{0,300}?)navigate\(\{([^}]*)\}/sgi) { print "$ARGV:" . ln($_, $-[0]) . ": navigate without replace\n" unless $3 =~ /replace/ }' | show
fi

HITS="$(wc -l < "$HITS_FILE" | tr -d ' ')"
printf '\n== %d probe(s) with candidates. Confirm each in the code; a probe hit is not yet a finding.\n' "$HITS"
