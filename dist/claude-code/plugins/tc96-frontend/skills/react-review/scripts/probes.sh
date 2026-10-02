#!/usr/bin/env bash
# React review probes — they run BEFORE reading any code.
# Usage: bash probes.sh [target]   (default target: src, or . when src does not exist)
#
# Each block prints what it found and the ID of the rule to cite. A probe is not a
# finding: it says where to look. Confirm by reading the snippet before reporting.
set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then [ -d src ] && TARGET=src || TARGET=.; fi
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)

heading() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
none_found()  { echo "   (nothing)"; }

heading "0. Environment" "changes the verdict of probes 6 and 1"
rg -n '"react":|"react-dom":' package.json 2>/dev/null || none_found
echo "   -- React Compiler (REACT-PERF-02):"
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' \
   package.json vite.config.* babel.config.* next.config.* 2>/dev/null || none_found
echo "   -- lint net for REACT-HOOK-* and REACT-EFFECT-02/03:"
python3 - <<'PYLINT' 2>/dev/null || rg -n --no-messages 'react-hooks' package.json eslint.config.* .eslintrc* biome.json* 2>/dev/null || echo "      NO net found"
import json, pathlib, re, sys

def found(msg): print(f"      {msg}")

# ESLint
eslint = [p for p in ("eslint.config.js", "eslint.config.mjs", "eslint.config.ts",
                      ".eslintrc", ".eslintrc.js", ".eslintrc.json", ".eslintrc.cjs")
          if pathlib.Path(p).exists()]
pkg = {}
try:
    pkg = json.loads(pathlib.Path("package.json").read_text())
except Exception:
    pass
deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
has_eslint_plugin = "eslint-plugin-react-hooks" in deps or any(
    "react-hooks" in pathlib.Path(p).read_text() for p in eslint)
if has_eslint_plugin:
    found("ESLint: eslint-plugin-react-hooks present ✓")

# Biome — the Hooks rules are recommended FOR THE react DOMAIN; the domain has to be on
bio = next((p for p in ("biome.json", "biome.jsonc") if pathlib.Path(p).exists()), None)
has_biome_react = False
if bio:
    raw = pathlib.Path(bio).read_text()
    try:
        # JSONC: drop comments only OUTSIDE strings — a naive "//" strip also cuts
        # the "https://" of "$schema" and makes every biome.json look empty
        cfg = json.loads(re.sub(r'("(?:\\.|[^"\\])*")|//[^\n]*|/\*.*?\*/',
                                lambda m: m.group(1) or "", raw, flags=re.S))
    except Exception:
        cfg = {}
    linter = cfg.get("linter", {}) or {}
    dominio = (linter.get("domains") or {}).get("react")
    rules_json = json.dumps(linter.get("rules", {}))
    explicit = "useHookAtTopLevel" in rules_json and "useExhaustiveDependencies" in rules_json
    if dominio in ("recommended", "all"):
        found(f"Biome: linter.domains.react = {dominio!r} ✓")
        has_biome_react = True
    elif explicit:
        found("Biome: useHookAtTopLevel and useExhaustiveDependencies declared ✓")
        has_biome_react = True
    else:
        found(f"Biome present ({bio}), but the react domain is NOT on")
        found("  the Hooks rules are 'recommended for the react domain' — without the domain they never run")
        found("  fix: \"linter\": { \"domains\": { \"react\": \"recommended\" } }")

if not has_eslint_plugin and not has_biome_react:
    found("NO active net — REACT-HOOK-* and REACT-EFFECT-02/03 depend on human review")
    found("this is the FIRST finding of the report: without it, everything here comes back next PR")
PYLINT
echo "   -- <StrictMode> (REACT-DOM-06):"
"${RG[@]}" -l 'StrictMode' "$TARGET" 2>/dev/null || none_found

heading "1. Fetch inside an Effect" "REACT-EFFECT-06 / REACT-ASYNC-03"
"${RG[@]}" -nU 'useEffect\((?s:.{0,400}?)\b(fetch|axios)\s*[\(\.]' "$TARGET" || none_found

heading "2. State derived by an Effect" "REACT-PAT-01"
"${RG[@]}" -nU 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$TARGET" || none_found

heading "3. exhaustive-deps silenced" "REACT-EFFECT-03"
rg -n 'eslint-disable.*exhaustive-deps' "$TARGET" || none_found

heading "4. Effect with an async callback" "REACT-EFFECT-12"
"${RG[@]}" -n 'useEffect\(\s*async' "$TARGET" || none_found

heading "5. setState without the updater form" "REACT-STATE-01"
"${RG[@]}" -n 'set[A-Z]\w*\(\s*\w+\s*[-+]\s*1\s*\)' "$TARGET" || none_found

heading "6. Memoization — inventory" "REACT-PERF-01; every occurrence needs a measurement"
"${RG[@]}" -c '\buseMemo\(|\buseCallback\(|\bmemo\(' "$TARGET" || none_found

heading "7. index as key" "antipattern from React - Patterns § 8"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$TARGET" || none_found

heading "8. forwardRef in current code" "REACT-REF-03"
"${RG[@]}" -n '\bforwardRef\b' "$TARGET" || none_found

heading "9. Suspense without an Error Boundary in the same file" "REACT-ASYNC-08"
"${RG[@]}" -l '<Suspense' "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q 'ErrorBoundary|errorElement' "$f" || echo "   $f"; done \
  | grep . || none_found

heading "10. Mutating an array that came from props/state" "REACT-PURE-03 / REACT-PURE-05"
"${RG[@]}" -n '\b(props\.|state\.)?\w+\.(push|sort|splice|reverse|unshift)\(' "$TARGET" || none_found

heading "11. The 'use client' boundary" "REACT-RSC-03 — what matters is how high it sits"
"${RG[@]}" -l --sort path "^['\"]use client['\"]" "$TARGET" || none_found

heading "12. Server Function — validation at the boundary" "REACT-RSC-06"
"${RG[@]}" -l "['\"]use server['\"]" "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q 'safeParse|\.parse\(|zod|valibot|assert' "$f" || echo "   no visible validation: $f"; done \
  | grep . || none_found

heading "13. Entrypoint" "REACT-DOM-01 — createRoot over server-rendered HTML"
"${RG[@]}" -n 'createRoot\(|hydrateRoot\(' "$TARGET" || none_found

heading "14. Branching on typeof window during render" "REACT-DOM-03"
"${RG[@]}" -n 'typeof window' "$TARGET" || none_found

printf '\n\033[1m== Done.\033[0m A probe points; the reading confirms. A finding without file:line is not a finding.\n'
