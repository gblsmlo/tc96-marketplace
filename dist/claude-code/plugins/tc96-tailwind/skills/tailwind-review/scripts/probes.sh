#!/usr/bin/env bash
# Tailwind probes — S1 to S11. Usage: bash probes.sh [src-dir] [project-root]
#
# In Tailwind the worst defects are invisible to reading AND to the build: a class built by
# interpolation compiles to nothing, a v3 name compiles to another value, a token missing in
# .dark inherits the light one. Every probe here looks for one of those.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${1:-}"
ROOT="${2:-.}"
if [ -z "$SRC" ]; then for d in src app packages apps; do [ -d "$ROOT/$d" ] && SRC="$ROOT/$d" && break; done; fi
SRC="${SRC:-$ROOT}"
RG=(rg --no-messages -n -g '!node_modules' -g '!dist' -g '!build' -g '!.output' -g '!storybook-static'
    --type-add 'ui:*.{tsx,jsx,ts,js,html,vue,svelte,astro,mdx}')
heading() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
or_empty() {  # prints the input (capped); when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s\n' "$out" | head -"${2:-12}" | sed 's|^|   |'
  else echo "   ${1:-(nothing)}"; fi
}

heading "S1. Line, integration, entry stylesheet" "TW-CORE-01 — decides which IDs may be cited"
DISCOVERY=$(bash "$HERE/../../tailwind-setup/scripts/discover-line.sh" "$ROOT" </dev/null 2>/dev/null)
printf '%s\n' "$DISCOVERY" | grep -e ' -> ' | sed 's|^ *|   |'
LINE=$(printf '%s\n' "$DISCOVERY" | sed -n 's/.*LINE: \([0-9A-Z?]*\).*/\1/p' | head -1)
echo "   LINE=$LINE"
[ "$LINE" = 3 ] && echo "   STOP: line 3 — from here on, cite only TW-SRC-01/02, TW-UTIL-01, TW-A11Y-*, TW-COMP-*"

heading "S2. Class built by interpolation" "TW-SRC-01 — compiles to nothing, sometimes 'works' by accident"
"${RG[@]}" -tui -e '\b(bg|text|border|ring|outline|fill|stroke|shadow|from|via|to|decoration|divide|accent|caret|p[xytrbl]?|m[xytrbl]?|w|h|size|gap|gap-[xy]|space-[xy]|grid-cols|col-span|row-span|rounded|font|leading|tracking|z|opacity|top|left|right|bottom|inset|translate-[xy]|rotate|scale|basis|grow|shrink|order|columns|aspect|blur|max-w|min-w|max-h|min-h)-\$\{' -e "\b(bg|text|border)-['\"]\s*\+" -e '\{\{[^}]*\}\}-[0-9]' "$SRC" | or_empty

heading "S3. Line-3 leftovers" "TW-MIG-* — compile, with another value or none"
"${RG[@]}" -tui -o -w -e '(bg|text|border|divide|ring|placeholder)-opacity-[0-9]+' \
  -e 'flex-(grow|shrink)(-[0-9]+)?' -e 'overflow-ellipsis' -e 'decoration-(slice|clone)' \
  -e 'bg-gradient-to-[a-z]+' -e '[a-z-]+-\[--[a-z0-9-]+\]' "$SRC" | or_empty
echo "   -- bare v3 scale names (shadow, rounded, blur, ring) — v4 value differs; read each one:"
"${RG[@]}" -tui -o -e '["'"'"' `](shadow|rounded|blur|drop-shadow|backdrop-blur|ring)["'"'"' `]' "$SRC" | or_empty
echo "   -- leading-! important (v3 syntax):"
"${RG[@]}" -tui -e '(className|class)=|\b(cn|clsx|cva|tv|twMerge|twJoin)\(' "$SRC" \
  | rg --no-messages -o -e '["'"'"' `]!(bg|text|border|p[xytrbl]?|m[xytrbl]?|w|h|flex|grid|block|hidden|inline|font|rounded|shadow|z|opacity|gap|items|justify)(-[a-z0-9/.-]+)?\b' | or_empty
"${RG[@]}" -g '*.{css,scss}' -e '@tailwind\s' "$ROOT" | or_empty "(no @tailwind directive)"

heading "S4. Conflicting utilities on one element" "TW-UTIL-01, TW-COMP-02"
CONF=$(python3 "$HERE/conflicts.py" "$SRC" </dev/null)
[ -n "$CONF" ] && printf '%s\n' "$CONF" | head -15 || echo "   (nothing)"

heading "S5. Arbitrary values — census" "TW-THEME-04, TW-UTIL-03 — repeated = an undeclared token"
"${RG[@]}" -tui -o -N -I -e '[a-z-]+-\[(#[0-9a-fA-F]{3,8}|[0-9.]+(px|rem)|rgba?\([^]]*\))\]' "$SRC" \
  | sort | uniq -c | sort -rn | head -10 | or_empty
echo "   -- arbitrary property that duplicates a utility (TW-UTIL-04):"
"${RG[@]}" -tui -o -e '\[(display|position|padding|margin|color|width|height):[^]]+\]' "$SRC" | or_empty

heading "S6. Inline style with a static value" "TW-UTIL-05"
"${RG[@]}" -tui -e 'style=\{\{[^}]*:\s*(-?[0-9]+|["'"'"'][^"'"'"'$]*["'"'"'])\s*[,}]' "$SRC" | or_empty

heading "S7. @apply in the project's own components" "TW-UTIL-07 — @utility and @layer base are allowed"
for f in $("${RG[@]}" -l -g '*.{css,scss}' -g '*.vue' -g '*.svelte' -e '@apply' "$ROOT" </dev/null); do
  python3 - "$f" <<'PY'
import re, sys
path = sys.argv[1]
text = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), open(path, encoding="utf-8").read(), flags=re.S)
stack = []                      # the at-rule or selector that opened each { level
for n, line in enumerate(text.splitlines(), 1):
    if "@apply" in line and not any(s.startswith(("@utility", "@layer base")) for s in stack):
        print(f"   {path}:{n}:{line.strip()}")
    for m in re.finditer(r"([^{}]*)\{|\}", line):
        if m.group(0) == "}":
            stack and stack.pop()
        else:
            stack.append(m.group(1).strip())
PY
done | or_empty

heading "S8. Theme: raw palette in design-system components; dark: by hand" "TW-THEME-11, TW-THEME-06"
UI=$(ls -d "$SRC"/components/ui "$ROOT"/packages/ui/src 2>/dev/null | head -1)
if [ -n "$UI" ]; then
  "${RG[@]}" -tui -o -e '(bg|text|border|ring|fill|stroke)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-[0-9]{2,3}' "$UI" \
    | or_empty "(none in $UI)"
else echo "   (no components/ui or packages/ui/src)"; fi
printf '   dark: occurrences: %s\n' "$("${RG[@]}" -tui -o -e 'dark:[a-z]' "$SRC" | wc -l)"
echo "   -- tokens declared in :root but missing in .dark (TW-THEME-13):"
for css in $("${RG[@]}" -l -g '*.css' -e '\.dark\s*\{' "$ROOT" </dev/null); do
  python3 - "$css" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
def nomes(sel):
    m = re.search(sel + r"\s*\{([^}]*)\}", t)
    return set(re.findall(r"(--[\w-]+)\s*:", m.group(1))) if m else set()
falta = sorted(nomes(r":root") - nomes(r"\.dark") - {"--radius"})
if falta: print(f"   {sys.argv[1]}: " + " ".join(falta))
PY
done

heading "S9. Composition and merge" "TW-COMP-03, TW-COMP-04, TW-COMP-05"
echo "   -- className passed FIRST to the merge (the default wins over the consumer):"
"${RG[@]}" -tui -e '(cn|twMerge)\(\s*(props\.)?className\s*,' "$SRC" | or_empty
echo "   -- composition helpers defined:"
"${RG[@]}" -tui -e 'export (function|const) (cn|cx)\b' -e "export \{ cn \}" "$ROOT" | or_empty
echo "   -- custom non-color tokens (need extendTailwindMerge):"
"${RG[@]}" -g '*.css' -o -e '--(text|spacing|radius|shadow|font-weight|leading|tracking)-[a-z0-9-]+\s*:' "$ROOT" \
  | grep -v -E -e '--[a-z-]+-([0-9]?(xs|sm|md|lg|xl)|base|full|none|tight|snug|normal|relaxed|loose|wide|wider|widest|tighter|thin|light|medium|semibold|bold|extrabold|black|extralight|inner)\s*:' \
  | grep -v -e '--line-height' | or_empty "(only default scale names — tailwind-merge already knows them)"
"${RG[@]}" -tui -q -e 'extendTailwindMerge' "$ROOT" && echo "   extendTailwindMerge: present" || echo "   extendTailwindMerge: ABSENT"

heading "S10. Accessibility" "TW-A11Y-01, TW-A11Y-02, TW-A11Y-05"
echo "   -- outline removed with no focus-visible style on the same string:"
"${RG[@]}" -tui -e 'outline-(none|hidden)' "$SRC" | grep -v 'focus-visible:' | or_empty
echo "   -- focus ring on focus: instead of focus-visible:"
"${RG[@]}" -tui -o -e 'focus:(ring|outline)-[a-z0-9-]+' "$SRC" | grep -v -e 'outline-none' -e 'outline-hidden' | or_empty
echo "   -- animation with no motion-safe/motion-reduce:"
"${RG[@]}" -tui -e '\banimate-[a-z]' "$SRC" | grep -v -e 'motion-' \
  | grep -v -E 'animate-spin.*(Loader|Spinner|role="status"|aria-busy)|(Loader|Spinner|role="status"|aria-busy).*animate-spin' \
  | or_empty "(nothing — a spinning loader is essential motion and is skipped)"
echo "   -- icon-only buttons are NOT probed: read every <button> whose only child is an <svg> (TW-A11Y-03)"

heading "S11. Utility class used as a test selector" "PW-LOC-01"
"${RG[@]}" -g '*.{spec,test}.{ts,tsx,js}' -e "locator\(['\"\`][^'\"\`]*\.(bg|text|p|m|px|py|flex|grid|rounded|border|w|h)-" "$ROOT" | or_empty

printf '\n\033[1m== Done.\033[0m S1 decides the IDs; S2 and S4 are the findings that hide best — report them first.\n'
