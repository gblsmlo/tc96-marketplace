#!/usr/bin/env bash
# Boundary probes — they run BEFORE reading any code, in the order that fails most.
# Usage: bash sondas-imports.sh [target]   (default target: src)
#
# A probe is not a finding: it points at the file. Confirm by reading, and report with
# an ID from Feature-Based Architecture § 4 + file:line.
set -uo pipefail

ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "0. Enforcement" "without this, every finding below comes back next PR"
echo "   -- biome.json:"
ls biome.json biome.jsonc 2>/dev/null || echo "   MISSING — first finding of the report"
echo "   -- boundary rules turned on:"
rg -n 'noRestrictedImports|noImportCycles' biome.json biome.jsonc 2>/dev/null || vazio
echo "   -- aliases across the three files (divergence = breaks only in the test):"
for f in tsconfig.json vite.config.ts vitest.config.ts; do
  printf '   %-18s ' "$f"
  rg -c '@features|@components|@libs|@hooks|@routes' "$f" 2>/dev/null || echo "no alias"
done

titulo "1. Inverted direction" "REACT-ARCH-06 / REACT-ARCH-07 — the most expensive finding"
echo "   -- generic layer importing the domain:"
GENERICAS=()
for d in components hooks libs types; do [ -d "$ALVO/$d" ] && GENERICAS+=("$ALVO/$d"); done
if [ ${#GENERICAS[@]} -gt 0 ]; then
  "${RG[@]}" -n "from '@(features|routes)/" "${GENERICAS[@]}" || vazio
else vazio; fi
echo "   -- feature importing a route:"
"${RG[@]}" -n "from '@routes/" "$ALVO/features" 2>/dev/null || vazio

titulo "2. Deep import" "REACT-ARCH-05 — three segments or more after the alias"
"${RG[@]}" -n "from '@(features|components)/[^/']+/[^/']+/" "$ALVO" || vazio

titulo "3. A feature aliasing itself" "REACT-ARCH-04 — lint only catches it once a cycle closes"
"${RG[@]}" -l "from '@features/" "$ALVO/features" 2>/dev/null \
  | while read -r f; do
      dono="$(echo "$f" | sed -E "s|.*features/([^/]+)/.*|\1|")"
      rg -nH "from '@features/$dono" "$f" | sed "s|^|   |"
    done | grep . || vazio

titulo "4. Barrel with logic" "REACT-ARCH-03 — index.ts only re-exports"
find "$ALVO" -name 'index.ts' -not -path '*/node_modules/*' 2>/dev/null \
  | while read -r f; do
      rg -qv '^\s*(export|import|//|/\*|\*|$)' "$f" && echo "   $f"
    done | grep . || vazio

titulo "5. Bloated route" "REACT-ARCH-09 — apply the bench test, not an impression"
find "$ALVO/routes" -name '*.tsx' 2>/dev/null -exec wc -l {} + 2>/dev/null | sort -rn | head -6 | ou_vazio

titulo "6. Naming convention" "REACT-ARCH-12 — kebab-case for file and directory"
find "$ALVO" -name '*[A-Z]*' -not -path '*/node_modules/*' 2>/dev/null | head -10 | sed 's|^|   |' | grep . | ou_vazio

titulo "7. Type leaving the barrel without export type" "REACT-ARCH-11"
find "$ALVO" -name 'index.ts' -not -path '*/node_modules/*' 2>/dev/null \
  | xargs rg -n "^export \{[^}]*\b(Props|Type|Dto|Schema)\b" 2>/dev/null || vazio

printf '\n\033[1m== Done.\033[0m A structural finding comes before an internal one: moving a file erases the second.\n'
