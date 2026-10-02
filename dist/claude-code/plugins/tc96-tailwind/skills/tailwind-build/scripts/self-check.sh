#!/usr/bin/env bash
# Tailwind self-check — the items of Step 5. Usage: bash self-check.sh <file-or-dir>
#
# Runs over what you JUST wrote. Every ✗ here compiles: that is why it is checked by a
# script and not by the build.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-src}"
RG=(rg --no-messages -n --type-add 'ui:*.{tsx,jsx,ts,js,html,vue,svelte,astro,mdx}' -tui)
n=0; failures=0
bad() {  # number, label, rule, pattern [, exclusion]
  n=$((n+1)); local s
  s="$("${RG[@]}" -e "$4" "$TARGET" </dev/null 2>/dev/null)"
  [ -n "${5:-}" ] && s="$(printf '%s\n' "$s" | grep -v -e "$5" | grep .)"
  if [ -n "$s" ]; then failures=$((failures+1)); printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; printf '%s\n' "$s" | head -6 | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Tailwind self-check — $TARGET"
bad 1 "no class name built by interpolation"                TW-SRC-01 '\b(bg|text|border|ring|outline|fill|stroke|shadow|from|via|to|decoration|divide|accent|caret|p[xytrbl]?|m[xytrbl]?|w|h|size|gap|gap-[xy]|space-[xy]|grid-cols|col-span|row-span|rounded|font|leading|tracking|z|opacity|top|left|right|bottom|inset|translate-[xy]|rotate|scale|basis|grow|shrink|order|columns|aspect|blur|max-w|min-w|max-h|min-h)-\$\{'
n=$((n+1)); CONF="$(python3 "$HERE/../../tailwind-review/scripts/conflicts.py" "$TARGET" </dev/null)"
if [ -n "$CONF" ]; then failures=$((failures+1)); printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "no two utilities on the same property" "TW-UTIL-01, TW-COMP-02"; printf '%s\n' "$CONF" | head -6 | sed 's|^   |      |'
else printf '%2d. ✓ %s\n' "$n" "no two utilities on the same property"; fi
bad 3 "no line-3 name or syntax"                            TW-MIG-* '(bg|text|border|ring)-opacity-|flex-(grow|shrink)|overflow-ellipsis|bg-gradient-to-|-\[--[a-z]|["'"'"' ]![a-z]'
bad 4 "no arbitrary color (use the token)"                  TW-THEME-04 '-\[#[0-9a-fA-F]{3,8}\]|-\[rgba?\('
bad 5 "no arbitrary property that duplicates a utility"     TW-UTIL-04 '\[(display|position|padding|margin|color|width|height):'
bad 6 "no inline style with a static value"                 TW-UTIL-05 'style=\{\{[^}]*:\s*(-?[0-9]+|["'"'"'][^"'"'"'$]*["'"'"'])\s*[,}]'
bad 7 "an outline removed has a focus-visible replacement"  TW-A11Y-01 'outline-(none|hidden)' 'focus-visible:'
bad 8 "focus ring on focus-visible:, not focus:"            TW-A11Y-02 'focus:(ring|outline-[0-9])'
bad 9 "animation respects motion-reduce / motion-safe"      TW-A11Y-05 '\banimate-[a-z]' 'motion-'
bad 10 "className passed LAST to the merge"                 TW-COMP-03 '(cn|twMerge)\(\s*(props\.)?className\s*,'
case "$TARGET" in
  *components/ui*|*packages/ui*)
    bad 11 "design-system component uses semantic tokens"   TW-THEME-11 '(bg|text|border|ring)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|pink|rose)-[0-9]{2,3}';;
  *) n=$((n+1)); printf '%2d. – semantic tokens: only checked under components/ui or packages/ui  (TW-THEME-11)\n' "$n";;
esac
echo
cat <<'END'
Items that require reading:
  · the mobile style is the unprefixed one; sm:/md: override upward ......... TW-VAR-01
  · a value repeated across files is a token, not an arbitrary ............. TW-UTIL-03
  · a runtime value arrives as a CSS variable in style ...................... TW-UTIL-05
  · a design variation is a cva/tv variant, not a className ................. TW-COMP-06
  · internal conditionals join without merge and do not conflict ............ TW-COMP-02
  · an icon-only control has an accessible name ............................. TW-A11Y-03
  · nothing is reachable ONLY through hover: ................................ TW-A11Y-08
  · a component reused in containers of different widths uses @container .... TW-VAR-03

Then RENDER it — the story or the screen, light AND dark. The build passing proves nothing (TW-CORE-04).
END
exit $(( failures > 0 ))
