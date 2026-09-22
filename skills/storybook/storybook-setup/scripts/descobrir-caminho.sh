#!/usr/bin/env bash
# Discovers the Storybook framework path and checks the version floors.
# Usage: bash descobrir-caminho.sh [root]
#
# It is the only structure in this knowledge base where PRESCRIBING THE WRONG PATH FAILS
# SILENTLY: under react-vite, parameters.tanstack.* has no effect at all (SB-RV-04);
# under tanstack-react, a decorator with RouterProvider creates a SECOND router (SB-TS-03).
set -uo pipefail

ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

RAIZ="${1:-.}"
cd "$RAIZ" 2>/dev/null || { echo "root does not exist: $RAIZ" >&2; exit 1; }
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

MAIN=$(ls .storybook/main.* 2>/dev/null | head -1)
titulo "1. The framework field" "SB-CFG-01 — read it BEFORE prescribing anything"
if [ -z "$MAIN" ]; then
  echo "   .storybook/main.* NOT FOUND — the project has no Storybook yet"
  CAMINHO="none"
else
  echo "   $MAIN"
  rg -n --no-messages 'framework' "$MAIN" | sed 's|^|   |'
  if rg -q --no-messages 'tanstack-react' "$MAIN"; then CAMINHO="A (tanstack-react)"
  elif rg -q --no-messages 'react-vite' "$MAIN"; then CAMINHO="B (react-vite)"
  else CAMINHO="undetermined"; fi
fi
printf '\n   \033[1mPATH: %s\033[0m\n' "$CAMINHO"
case "$CAMINHO" in
  A*) echo "   -> SB-TS-* family · note: Storybook - TanStack React"
      echo "   -> citing SB-RV-* here is an INVALID FINDING";;
  B*) echo "   -> SB-RV-* family · note: Storybook - React Vite"
      echo "   -> citing SB-TS-* here is an INVALID FINDING"
      echo "   -> parameters.tanstack.* HAS NO EFFECT on this path (SB-RV-04)";;
esac

titulo "2. The version floors" "tanstack-react demands the highest floor in the structure"
rg -n --no-messages '"(react|vite|storybook|@storybook/[a-z-]+)":' package.json | sed 's|^|   |'
cat <<'FIM'
   tanstack-react ... React >= 18 · Vite >= 7
   react-vite ....... React >= 16.8 · Vite >= 5
   -> Vite 5 or 6 with tanstack-react = migrate Vite BEFORE any story
FIM

titulo "3. Package version alignment" "SB-CORE-*"
rg -n --no-messages '"(storybook|@storybook/[a-z-]+)":' package.json | sed 's|^|   |'
echo "   -> every @storybook/* package on the SAME version as the CLI"

titulo "4. Where the Vite config is inherited from"
ls vite.config.* vitest.config.* 2>/dev/null | sed 's|^|   |' | ou_vazio "(none)"
[ -n "$MAIN" ] && rg -n --no-messages 'viteFinal|builder' "$MAIN" | sed 's|^|   |'

titulo "5. Path contradiction in the code" "the finding that fails silently"
if [ "${CAMINHO:0:1}" = "B" ]; then
  rg -n --no-messages -g '*.{ts,tsx}' 'parameters.*tanstack|tanstack:\s*\{' .storybook src 2>/dev/null \
    && echo "   ABOVE: parameters.tanstack.* under react-vite — no effect, no error (SB-RV-04)" \
    || echo "   (nothing)"
elif [ "${CAMINHO:0:1}" = "A" ]; then
  rg -n --no-messages -g '*.{ts,tsx}' 'RouterProvider' .storybook src 2>/dev/null \
    && echo "   ABOVE: a hand-written RouterProvider under tanstack-react — creates a SECOND router (SB-TS-03)" \
    || echo "   (nothing)"
fi

printf '\n\033[1m== Done.\033[0m The choice is all but irreversible: the automigration only goes one way.\n'
