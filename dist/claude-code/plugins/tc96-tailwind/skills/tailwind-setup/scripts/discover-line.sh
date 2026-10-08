#!/usr/bin/env bash
# Discovers which Tailwind line the project is on, how it is integrated, and where the
# entry stylesheet lives — before anything is prescribed (TW-CORE-01).
# Usage: bash discover-line.sh [root]
#
# Prescribing the wrong line fails silently: a v4 class in a v3 project compiles to nothing,
# a v3 name in a v4 project (`shadow`, `rounded`, `outline-none`) compiles to ANOTHER value.
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "root does not exist: $ROOT" >&2; exit 1; }
heading() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
or_empty() {  # prints the input; when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s\n' "$out"; else echo "   ${1:-(nothing)}"; fi
}
RG=(rg --no-messages -g '!node_modules' -g '!dist' -g '!build' -g '!.output' -g '!coverage')

heading "1. Packages" "TW-CFG-03 — tailwindcss and every @tailwindcss/* on the SAME version"
"${RG[@]}" -n -g 'package.json' \
  '"(tailwindcss|@tailwindcss/[a-z-]+|tailwind-merge|class-variance-authority|tailwind-variants|clsx|cn|prettier-plugin-tailwindcss|postcss|autoprefixer|postcss-import|tailwindcss-animate|tw-animate-css|sass|less|stylus)":' . \
  | sed 's|^|   |' | or_empty "(no Tailwind package in any package.json)"
VERSION=$("${RG[@]}" -o -N -I -g 'package.json' '"tailwindcss":\s*"[^"]*"' . | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
# the versions of tailwindcss and every @tailwindcss/* package, reduced to major.minor
VERSIONS=$("${RG[@]}" -o -N -I -g 'package.json' '"(tailwindcss|@tailwindcss/[a-z-]+)":\s*"[^"]*"' . \
  | sed -E 's/.*"([^"]*)"$/\1/' | grep -E '[0-9]' | sed -E 's/^[^0-9]*([0-9]+\.[0-9]+).*/\1/' | sort -u)
# a Bun/pnpm catalog keeps the real range in the root package.json: read it too
VERSIONS=$(printf '%s\n' "$VERSIONS" $(python3 - <<'PY' 2>/dev/null
import json, re
try:
    root = json.load(open("package.json"))
except Exception:
    raise SystemExit
ws = root.get("workspaces")
cat = (ws.get("catalog", {}) if isinstance(ws, dict) else {}) | root.get("catalog", {})
for k, v in cat.items():
    m = re.search(r"(\d+\.\d+)", v)
    if m and (k == "tailwindcss" or k.startswith("@tailwindcss/")):
        print(m.group(1))
PY
) | grep . | sort -u)
if [ "$(printf '%s' "$VERSIONS" | grep -c .)" -gt 1 ]; then
  echo "   -> tailwindcss and @tailwindcss/* disagree ($(echo $VERSIONS)): TW-CFG-03"
fi

heading "2. Entry stylesheet(s)" "TW-CFG-05, TW-CFG-06 — one per app"
ENTRIES=$("${RG[@]}" -l -g '*.css' -e '@import\s+["'"'"']tailwindcss["'"'"']' . 2>/dev/null)
V3DIR=$("${RG[@]}" -l -g '*.{css,scss}' -e '@tailwind\s+(base|components|utilities)' . 2>/dev/null)
[ -n "$ENTRIES" ] && echo "$ENTRIES" | sed 's|^|   v4 @import  |'
[ -n "$V3DIR" ] && echo "$V3DIR" | sed 's|^|   v3 @tailwind |'
[ -z "$ENTRIES$V3DIR" ] && echo "   (none found — the project has no Tailwind yet, or the CSS lives somewhere unusual)"
# more than one entry inside the SAME app/package is TW-CFG-06; one per app is right
REPEATED=$(printf '%s\n' "$ENTRIES" | grep . | sed -E 's#^\./##; s#^((apps|packages)/[^/]+)/.*#\1#; t; s#.*#(root)#' | sort | uniq -d)
if [ -n "$REPEATED" ]; then
  echo "   -> more than one stylesheet imports tailwindcss inside: $(echo $REPEATED) — one per app (TW-CFG-06)"
fi

heading "3. The line"
MAJOR=$(printf '%s' "$VERSION" | sed -E 's/^[^0-9]*([0-9]+).*/\1/')
case "$VERSION" in latest|next) MAJOR=4 ;; esac
case "$MAJOR" in
  4) LINE_PKG=4 ;;
  3) LINE_PKG=3 ;;
  *) LINE_PKG="?" ;;
esac
if [ -n "$V3DIR" ] && [ -n "$ENTRIES" ]; then LINE="MIXED"
elif [ -n "$V3DIR" ]; then LINE=3
elif [ -n "$ENTRIES" ]; then LINE=4
else LINE="$LINE_PKG"; fi
[ "$LINE_PKG" != "?" ] && [ "$LINE" != "MIXED" ] && [ "$LINE" != "$LINE_PKG" ] && LINE="MIXED"
printf '   package.json: %s   ->   \033[1mLINE: %s\033[0m\n' "${VERSION:-none}" "$LINE"
case "$LINE" in
  4)     echo "   -> every TW-* family applies; TW-MIG-* only to leftovers";;
  3)     echo "   -> staying on 3.x: ONLY TW-SRC-01/02, TW-UTIL-01, TW-A11Y-*, TW-COMP-* apply"
         echo "   -> citing TW-CFG/TW-THEME/TW-MIG here is an INVALID FINDING (except as a migration recommendation)"
         echo "   -> API surface: Context7 /websites/v3_tailwindcss";;
  MIXED) echo "   -> a migration stopped halfway: package and stylesheet disagree. Finish it first (TW-MIG-01)";;
  *)     echo "   -> no Tailwind detected";;
esac

heading "4. Integration" "TW-CFG-01, TW-CFG-02"
VITE=$(ls vite.config.* app.config.* 2>/dev/null | head -3)
printf '%s\n' "$VITE" | grep . | sed 's|^|   |'
"${RG[@]}" -n -g 'vite.config.*' -g 'app.config.*' '@tailwindcss/vite|tailwindcss\(' . | sed 's|^|   vite     |'
"${RG[@]}" -n -g 'postcss.config.*' -g '.postcssrc*' 'tailwindcss|autoprefixer|postcss-import' . | sed 's|^|   postcss  |'
if [ -n "$VITE" ] && "${RG[@]}" -q -g 'postcss.config.*' -g '.postcssrc*' 'tailwindcss' . ; then
  echo "   -> Vite project integrating through PostCSS: TW-CFG-01"
fi
"${RG[@]}" -q -g 'postcss.config.*' -g '.postcssrc*' 'autoprefixer|postcss-import' . \
  && [ "$LINE" = 4 ] && echo "   -> autoprefixer/postcss-import alongside v4: TW-CFG-02"

if "${RG[@]}" -q -g 'package.json' '"@tanstack/react-start"' . ; then
  ROOT_ROUTE=$("${RG[@]}" --files -g '__root.tsx' . | head -1)
  if [ -n "$ROOT_ROUTE" ]; then
    "${RG[@]}" -q "import\s+['\"][^'\"]+\.css['\"]" "$ROOT_ROUTE" </dev/null \
      && echo "   -> TanStack Start importing the CSS without ?url in $ROOT_ROUTE: TW-CFG-04"
  fi
fi

heading "5. JavaScript config" "TW-CFG-08, TW-CFG-09 — ignored by v4 unless loaded by @config"
CFG=$("${RG[@]}" --files -g 'tailwind.config.*' . 2>/dev/null)
printf '%s\n' "$CFG" | grep . | sed 's|^|   |' | or_empty "(none)"
"${RG[@]}" -n -g '*.css' '@config|@plugin' . | sed 's|^|   |'
if [ -n "$CFG" ] && [ "$LINE" = 4 ] && ! "${RG[@]}" -q -g '*.css' '@config' . ; then
  echo "   -> a tailwind.config exists and NOTHING loads it: every value in it is silently ignored (TW-CFG-08)"
fi
[ -n "$CFG" ] && "${RG[@]}" -n -g 'tailwind.config.*' 'corePlugins|safelist|separator' . | sed 's|^|   unsupported in v4: |'

heading "6. Sources" "TW-SRC-03, TW-SRC-04 — what the scanner does NOT see"
"${RG[@]}" -n -g '*.css' '@source|source\(' . | sed 's|^|   |' | or_empty "(no @source — automatic detection only)"
if "${RG[@]}" -q -g 'package.json' '"workspaces"' . ; then
  echo "   monorepo: $(ls -d packages/* apps/* 2>/dev/null | tr '\n' ' ')"
  # a CSS file inside packages/ that declares @source covers every app importing it
  PKG_WITH_SOURCE=$("${RG[@]}" -l -g 'packages/**/*.css' '@source' . </dev/null 2>/dev/null)
  for e in $ENTRIES; do
    if rg -q --no-messages '@source|source\(' "$e" </dev/null; then continue; fi
    if [ -n "$PKG_WITH_SOURCE" ] && rg -q --no-messages '@import\s+["'"'"'][^"'"'"']*(packages/|@[a-z0-9-]+/)' "$e" </dev/null; then continue; fi
    [ -d packages ] && echo "   -> $e declares no source for the workspace packages it renders (TW-SRC-04)"
  done
fi

heading "7. Theme and dark mode" "TW-THEME-01, TW-THEME-05, TW-THEME-09"
"${RG[@]}" -c -g '*.css' '@theme' . | sed 's|^|   @theme blocks  |'
DUP=$("${RG[@]}" -l -g '*.css' '@theme' . </dev/null 2>/dev/null | python3 -c '
import re, sys
seen = {}
for path in sys.stdin.read().split():
    text = re.sub(r"/\*.*?\*/", "", open(path, encoding="utf-8").read(), flags=re.S)
    for block in re.findall(r"@theme[^{]*\{([^}]*)\}", text):
        for name in re.findall(r"(--[a-z0-9-]+)\s*:", block):
            seen.setdefault(name, set()).add(path)
print(" ".join(sorted(n for n, files in seen.items() if len(files) > 1)[:5]))
')
if [ -n "$DUP" ]; then
  echo "   -> the same token is declared in more than one stylesheet ($(echo $DUP)): one shared theme file, imported by each app (TW-THEME-08)"
fi
"${RG[@]}" -n -g '*.css' '@custom-variant\s+dark' . | sed 's|^|   |' | or_empty "(no @custom-variant dark — dark: follows the OS)"
if "${RG[@]}" -q -g '*.{ts,tsx,js,jsx}' "classList\.(add|toggle|remove)\(\s*['\"]dark|data-theme" . \
   && ! "${RG[@]}" -q -g '*.css' '@custom-variant\s+dark' . ; then
  echo "   -> the app toggles .dark/data-theme but declares no @custom-variant dark: the toggle has no effect (TW-THEME-09)"
fi

if rg -q --no-messages -U '@theme\s*\{[^}]*var\(' ${ENTRIES:-/dev/null} </dev/null 2>/dev/null; then
  echo "   -> a plain @theme maps to var(...): the utility resolves at :root, not at the element (TW-THEME-05 — use @theme inline)"
fi
rg -q --no-messages -U '@layer\s+base\s*\{[^@]*:root' ${ENTRIES:-/dev/null} </dev/null 2>/dev/null \
  && echo "   -> :root/.dark inside @layer base: the pre-inline shadcn pattern (Theme and Tokens § 5)"

heading "8. shadcn/ui" "TW-THEME-14"
if [ -f components.json ]; then
  rg -n --no-messages '"config"|"css"|"baseColor"|"cssVariables"' components.json | sed 's|^|   |'
  rg -q --no-messages '"config"\s*:\s*"[^"]+' components.json && [ "$LINE" = 4 ] \
    && echo "   -> tailwind.config is NOT empty under v4 (TW-THEME-14)"
else
  echo "   (no components.json)"
fi
"${RG[@]}" -q -g 'package.json' -g '*.css' 'tailwindcss-animate' . \
  && echo "   -> tailwindcss-animate is deprecated: tw-animate-css, imported in CSS (TW-THEME-14)"

heading "9. Preprocessors" "TW-CFG-07"
"${RG[@]}" --files -g '*.{scss,sass,less,styl}' . | head -5 | sed 's|^|   |' | or_empty "(none)"

heading "10. Formatter" "TW-TOOL-01, TW-TOOL-02"
"${RG[@]}" -n -g '.prettierrc*' -g 'prettier.config.*' -g 'package.json' 'prettier-plugin-tailwindcss|tailwindStylesheet|tailwindFunctions' . | sed 's|^|   |'
"${RG[@]}" -n -g 'biome.json*' 'useSortedClasses' . | sed 's|^|   |'
ls biome.json* >/dev/null 2>&1 && echo "   Biome present: class order is partial (nursery) — never a blocking finding (TW-TOOL-02)"

printf '\n\033[1m== Done.\033[0m LINE %s. Record it: it decides which TW-* IDs may be cited in this project.\n' "$LINE"
