#!/usr/bin/env bash
# Boundary probes — they run BEFORE reading any code, in the order that fails most.
# Usage: bash import-probes.sh [target]   (default target: src)
#
# A probe is not a finding: it points at the file. Confirm by reading, and report with
# an ID from Feature-Based Architecture § 4 + file:line.
set -uo pipefail

TARGET="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx -g '!*.gen.ts')
# an import through any alias form (@/x, @x, #/x, ~/x), either quote
IMPORT="from ['\"](@/|@|#/|~/)"
heading() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
none_found() { echo "   (nothing)"; }
or_empty() {  # prints the input; when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s
' "$out"; else echo "   ${1:-(nothing)}"; fi
}

heading "0. Enforcement" "without this, every finding below comes back next PR"
echo "   -- biome.json:"
BIOME=$(ls biome.json biome.jsonc 2>/dev/null | head -1)
[ -n "$BIOME" ] && echo "   $BIOME" || echo "   MISSING — first finding of the report"
echo "   -- boundary rules turned on:"
[ -n "$BIOME" ] && rg -n 'noRestrictedImports|noImportCycles' "$BIOME" 2>/dev/null | sed 's|^|   |' || none_found
echo "   -- aliases in each config (divergence = breaks only in the test or the build):"
for f in tsconfig*.json vite.config.* vitest.config.*; do
  [ -f "$f" ] || continue
  printf '   %-22s ' "$f"
  ALIASES=$(rg -o --no-messages '"[@#~][^"]*/\*"' "$f" | tr -d '"' | sort -u | tr '\n' ' ')
  if [ -n "$ALIASES" ]; then echo "$ALIASES"
  elif rg -q --no-messages 'tsconfigPaths|tsconfig-paths' "$f"; then echo "inherits tsconfig paths"
  else echo "no alias"; fi
done

heading "1. Inverted direction" "REACT-ARCH-06 / REACT-ARCH-07 — the most expensive finding"
echo "   -- generic layer importing the domain:"
GENERICAS=()
for d in components hooks libs lib utils types shared entities; do [ -d "$TARGET/$d" ] && GENERICAS+=("$TARGET/$d"); done
if [ ${#GENERICAS[@]} -gt 0 ]; then
  "${RG[@]}" -n "$IMPORT(features|routes|app)/" "${GENERICAS[@]}" || none_found
else none_found; fi
echo "   -- feature importing a route:"
"${RG[@]}" -n "${IMPORT}routes/" "$TARGET/features" 2>/dev/null || none_found

heading "2. Deep import" "REACT-ARCH-05 — three segments or more after the alias"
"${RG[@]}" -n "$IMPORT(features|components)/[^/'\"]+/[^/'\"]+/" "$TARGET" || none_found

heading "3. A feature aliasing itself" "REACT-ARCH-04 — lint only catches it once a cycle closes"
"${RG[@]}" -l "${IMPORT}features/" "$TARGET/features" 2>/dev/null \
  | while read -r f; do
      owner="$(echo "$f" | sed -E "s|.*features/([^/]+)/.*|\1|")"
      rg -nH "${IMPORT}features/$owner[/'\"]" "$f" | sed "s|^|   |"
    done | grep . || none_found

heading "4. Barrel with logic" "REACT-ARCH-03 — index.ts only re-exports"
find "$TARGET" -name 'index.ts' -not -path '*/node_modules/*' 2>/dev/null \
  | while read -r f; do
      python3 - "$f" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
t = re.sub(r"/\*.*?\*/|//[^\n]*", "", t, flags=re.S)
t = re.sub(r"export\s+(type\s+)?(\*|\{[^}]*\})(\s+as\s+\w+)?\s+from\s+['\"][^'\"]+['\"]\s*;?", "", t)
t = re.sub(r"import\s+(type\s+)?[^;]*?from\s+['\"][^'\"]+['\"]\s*;?", "", t)
if t.strip(): print("   " + sys.argv[1])
PY
    done | grep . || none_found

heading "5. Bloated route" "REACT-ARCH-09 — apply the bench test, not an impression"
find "$TARGET/routes" -name '*.tsx' 2>/dev/null -exec wc -l {} + 2>/dev/null | sort -rn | head -6 | or_empty

heading "6. Naming convention" "REACT-ARCH-12 — kebab-case for file and directory"
find "$TARGET" -name '*[A-Z]*' -not -path '*/node_modules/*' -not -name '*.gen.ts' -not -name 'README*' -not -name 'CHANGELOG*' 2>/dev/null \
  | grep -v -E '\$[a-zA-Z]+[^/]*$|/\$[a-zA-Z]+/' | head -10 | sed 's|^|   |' | grep . | or_empty

heading "7. Type leaving the barrel without export type" "REACT-ARCH-11"
find "$TARGET" -name 'index.ts' -not -path '*/node_modules/*' 2>/dev/null \
  | xargs rg -n "^export \{[^}]*\b(Props|Type|Dto|Schema)\b" 2>/dev/null || none_found

printf '\n\033[1m== Done.\033[0m A structural finding comes before an internal one: moving a file erases the second.\n'
