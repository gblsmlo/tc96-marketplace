#!/usr/bin/env bash
# Story self-check — the 14 items of Step 6. Usage: bash autoverificar.sh <file-or-dir>
set -uo pipefail
ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
n=0
mau() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$s" | sed 's|^|      |' | head -6
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }
semB() { n=$((n+1)); alvos="$("${RG[@]}" -l "$4" "$ALVO" 2>/dev/null)"; falta=""
  for f in $alvos; do rg -q --no-messages "$5" "$f" || falta="$falta$f\n"; done
  if [ -n "$falta" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; printf "$falta" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Story self-check — $ALVO"
semB 1 "satisfies Meta<…> on the meta"                SB-CSF-02 'const meta' 'satisfies Meta'
semB 2 "StoryObj<typeof meta> on the stories"         SB-CSF-02 'const meta' 'StoryObj<typeof meta>'
mau  3 "Meta/StoryObj imported from the framework package" SB-CORE-02 "from '@storybook/react'"
mau  4 "literal title (no interpolation, no variable)" SB-CSF-03 'title:\s*[`$]'
mau  5 "no argTypes the docgen would already infer"   SB-CSF-08 'argTypes:\s*\{'
mau  6 "no mutation of Story.args"                    SB-CSF-05 '\w+\.args\s*(\.|\[)[^=]*='
mau  7 "environment does not travel through args"     SB-CTX-03 'args:\s*\{[^}]*(router|theme|queryClient|provider)'
mau  8 "no side effect in the module body"            SB-CORE-06 '^(?!.*(export|import|const meta|type ))\s*\w+\([^)]*\)\s*;\s*$'
mau  9 "no story depending on another"                SB-CORE-05 'Default\.(play|args)\s*\('
echo
cat <<'FIM'
Items that require reading:
  · each story is a NAMED STATE, not a demo ............... SB-CSF-04
  · what tells the stories apart is `args` ................ SB-CSF-04
  · a prop's description lives only in the JSDoc .......... SB-DOC-02
  · a non-serializable value goes through `mapping` ....... SB-CSF-06
  · an export that is not a story is in excludeStories .... SB-CSF-09
  · empty and error states exist, or their absence was decided  (TS-TIPO-02)

Then START it and look at the sidebar: a glob that matches nothing does NOT error — it gives an empty sidebar (SB-CFG-02).
And open the docs page: empty controls are the symptom of a violated SB-CSF-04.
FIM
