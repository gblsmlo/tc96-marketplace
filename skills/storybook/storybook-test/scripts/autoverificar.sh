#!/usr/bin/env bash
# Story-test self-check — the 14 items of Step 5. Usage: bash autoverificar.sh <target>
# Step 0 ALWAYS: discover the framework path before prescribing anything about routing.
set -uo pipefail
ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)

printf '\033[1m== Step 0 — the framework path\033[0m  SB-CFG-01\n'
MAIN=$(ls .storybook/main.* 2>/dev/null | head -1)
if [ -n "$MAIN" ]; then
  rg -n --no-messages 'framework' "$MAIN" | sed 's|^|   |'
  rg -q 'tanstack-react' "$MAIN" && echo "   PATH A — SB-TS-* family; citing SB-RV-* here is an invalid finding"
  rg -q 'react-vite' "$MAIN"     && echo "   PATH B — SB-RV-* family; parameters.tanstack.* has NO effect (SB-RV-04)"
else echo "   .storybook/main.* not found — discover the path before prescribing"; fi
echo

n=0
mau() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$s" | sed 's|^|      |' | head -6
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

n=1; s1="$("${RG[@]}" '\bexpect\(' "$ALVO" 2>/dev/null | rg -v 'await expect|expect\.extend|await expect\.' || true)"
if [ -n "$s1" ]; then printf '\033[1m 1. ✗ %s\033[0m  (%s)\n' "every expect awaited" "SB-TEST-01"; echo "$s1" | sed 's|^|      |' | head -6
else printf ' 1. ✓ %s\n' "every expect awaited"; fi
mau 2 "the first async query is findBy…"         SB-TEST-10 'await\s+canvas\.getBy'
mau 3 "a callback is fn() in args"               SB-TEST-03 'render:\s*\([^)]*\)\s*=>\s*<[^>]*on[A-Z]\w*=\{\('
mau 4 "helpers from storybook/test, without @"   SB-CORE-01 "from '@storybook/test'"
mau 5 "Meta/StoryObj imported from the framework" SB-CORE-02 "from '@storybook/react'"
mau 6 "query by role/label, not by class"        SB-TEST-06 'querySelector\(|getByTestId\('
mau 7 "sb.mock() outside the preview"            SB-MOCK-01 'sb\.mock\('
mau 8 "no assertion about internal implementation" SB-TEST-09 'expect\(\w+\.(state|props|_)'
echo
cat <<'FIM'
Items that require reading:
  · mount destructured and called, when setup runs before the render .. SB-TEST-02
  · the mock's behavior in beforeEach, not in the preview ............. SB-MOCK-04
  · a beforeEach that changes the environment returns the cleanup ..... SB-CTX-08
  · a11y.test is 'error' where CI is expected to fail ................. SB-TEST-04
  · what tells the story apart is `args` .............................. SB-CSF-04

And the one worth more than all fourteen:
  break the component on purpose and confirm the story goes RED (TS-TEC-08).
  If nothing breaks, the play asserts nothing.

Then run:  vitest run --project=storybook     (without `run` it enters watch mode)
FIM
