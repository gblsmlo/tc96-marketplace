#!/usr/bin/env bash
# Re-render hazard probes — run them on a component ALREADY confirmed slow, before profiling.
# Usage: bash probes.sh [target]   (default target: src, or . when src does not exist)
#
# Each block prints where to look and the ID (or the doc section) behind the hazard. A probe
# is a lead for the Profiler, not a finding and not a fix: the measurement decides
# (REACT-PERF-01). Blocks marked "no ID" are hazards with no rule of their own; never invent one.
set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then [ -d src ] && TARGET=src || TARGET=.; fi
# tests and stories pass inline props on purpose: they are not the hot path
EXCLUDE=(-g '!*.test.*' -g '!*.spec.*' -g '!*.stories.*' -g '!**/__tests__/**')
RG=(rg --no-messages --type-add 'rx:*.{ts,tsx,js,jsx}' -trx "${EXCLUDE[@]}")

heading() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
none_found() { echo "   (nothing)"; }

heading "0. Environment" "changes the verdict of every block below"
rg --no-messages -n '"react":|"react-dom":|"jsdom":' package.json 2>/dev/null || echo "   no package.json react/jsdom entry here"
echo "   -- React Compiler (REACT-PERF-02): if active, hand-written memo is the wrong lever"
rg --no-messages -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' \
   package.json vite.config.* babel.config.* next.config.* 2>/dev/null || none_found
echo "   -- virtualization library (REACT-PERF-09): a volume problem is not solved by memo"
rg --no-messages -n '@tanstack/react-virtual|react-window|react-virtuoso|react-virtualized' package.json 2>/dev/null || none_found
echo "   -- an existing harness or results file (REACT-PERF-13, REACT-PERF-17): reuse it, its baseline is the 'before'"
rg --no-messages -l 'bench-harness v[0-9]+|"schema": "bench-result/v1"' . 2>/dev/null | head -10 | grep . || none_found

heading "1. Memoization inventory" "REACT-PERF-01 — each one needs a measurement; REACT-PERF-03 — and stable props"
"${RG[@]}" -c '\bmemo\(|\buseMemo\(|\buseCallback\(' "$TARGET" || none_found

heading "2. Inline object or array passed to a component" "REACT-PERF-03 — a new identity every render cancels memo"
"${RG[@]}" -n '<[A-Z][\w.]*\b[^>]*\s[a-z]\w*=\{\s*[\{\[]' "$TARGET" || none_found

heading "3. Inline function passed to a component" "REACT-PERF-03 — stabilize, or a latest-callback when the consumer owns it"
"${RG[@]}" -n '<[A-Z][\w.]*\b[^>]*\s(on[A-Z]\w*|render\w*|get\w*|\w+Fn)=\{\s*(async\s+)?(\([^)]*\)|\w+)\s*=>' "$TARGET" || none_found

heading "4. Provider value built inline" "REACT-STATE-07 — every consumer re-renders on every provider render"
"${RG[@]}" -n '<\w+(\.Provider)?\s[^>]*value=\{\{' "$TARGET" || none_found

heading "5. Render functions instead of components" "no ID — no memo boundary; its Hooks would belong to the caller (REACT-CALL-01 if it is a component called as a function)"
"${RG[@]}" -n '\{\s*render[A-Z]\w*\(|(const|function)\s+render[A-Z]\w*\s*(=\s*(\([^)]*\)|\w+)\s*=>|\()' "$TARGET" || none_found

heading "6. Linear lookup inside .map" "no ID — O(n x m) per render; build a Map/Set once (React - Performance and Concurrency § 1: computation)"
"${RG[@]}" -nU -o -r '.map(… .$1(' '\.map\((?:[^\n]*\n){0,2}?[^\n]*?\.(findIndex|indexOf|includes|find|filter|some)\(' "$TARGET" || none_found

heading "7. JSON.stringify as a key or a dependency" "no ID — serializes on every render and hides an identity problem"
"${RG[@]}" -n 'key=\{[^}]*JSON\.stringify|\[[^\]]*JSON\.stringify[^\]]*\]\s*\)' "$TARGET" || none_found

heading "8. Effect that sets state from props or state" "REACT-PAT-01 — one extra render per change"
"${RG[@]}" -nU -o -r 'useEffect(() => { set…' 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$TARGET" || none_found

heading "9. Unstable key" "REACT-PURE-01 (random in render) / REACT-UTIL-02 (useId as key) — remounts the subtree every render"
"${RG[@]}" -n 'key=\{[^}]*(Math\.random|crypto\.randomUUID|Date\.now|useId)' "$TARGET" || none_found

heading "10. Component declared inside another component" "no ID — a new type every render: the subtree remounts"
rg --no-messages -n --type-add 'jsxlike:*.{tsx,jsx}' -tjsxlike "${EXCLUDE[@]}" \
   '^\s{2,}(function\s+[A-Z]\w*\s*\(|const\s+[A-Z]\w*\s*=\s*(\([^)]*\)|\w+)\s*=>\s*[(<])' "$TARGET" || none_found

heading "11. External store or table subscription" "circuit breaker — a memo that needs this subscription changed stops the skill"
"${RG[@]}" -n 'useSyncExternalStore\(|useReactTable\(|useTable\(|useStore\(|useSelector\(|useSnapshot\(|useAtomValue\(' "$TARGET" || none_found

printf '\n\033[1m== Done.\033[0m A probe points; the Profiler and the render count decide. Baseline before any change (REACT-PERF-13).\n'
