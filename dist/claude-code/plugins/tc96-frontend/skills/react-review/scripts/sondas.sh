#!/usr/bin/env bash
# React review probes — they run BEFORE reading any code.
# Usage: bash sondas.sh [target]   (default target: src, or . when src does not exist)
#
# Each block prints what it found and the ID of the rule to cite. A probe is not a
# finding: it says where to look. Confirm by reading the snippet before reporting.
set -uo pipefail

ALVO="${1:-}"
if [ -z "$ALVO" ]; then [ -d src ] && ALVO=src || ALVO=.; fi
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)

titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio()  { echo "   (nothing)"; }

titulo "0. Environment" "changes the verdict of probes 6 and 1"
rg -n '"react":|"react-dom":' package.json 2>/dev/null || vazio
echo "   -- React Compiler (REACT-PERF-02):"
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' \
   package.json vite.config.* babel.config.* next.config.* 2>/dev/null || vazio
echo "   -- lint net for REACT-HOOK-* and REACT-EFFECT-02/03:"
python3 - <<'PYLINT' 2>/dev/null || rg -n --no-messages 'react-hooks' package.json eslint.config.* .eslintrc* biome.json* 2>/dev/null || echo "      NO net found"
import json, pathlib, re, sys

def achou(msg): print(f"      {msg}")

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
tem_eslint_plugin = "eslint-plugin-react-hooks" in deps or any(
    "react-hooks" in pathlib.Path(p).read_text() for p in eslint)
if tem_eslint_plugin:
    achou("ESLint: eslint-plugin-react-hooks present ✓")

# Biome — the Hooks rules are recommended FOR THE react DOMAIN; the domain has to be on
bio = next((p for p in ("biome.json", "biome.jsonc") if pathlib.Path(p).exists()), None)
tem_biome_react = False
if bio:
    bruto = pathlib.Path(bio).read_text()
    try:
        cfg = json.loads(re.sub(r"//.*", "", bruto))
    except Exception:
        cfg = {}
    linter = cfg.get("linter", {}) or {}
    dominio = (linter.get("domains") or {}).get("react")
    regras = json.dumps(linter.get("rules", {}))
    explicitas = "useHookAtTopLevel" in regras and "useExhaustiveDependencies" in regras
    if dominio in ("recommended", "all"):
        achou(f"Biome: linter.domains.react = {dominio!r} ✓")
        tem_biome_react = True
    elif explicitas:
        achou("Biome: useHookAtTopLevel and useExhaustiveDependencies declared ✓")
        tem_biome_react = True
    else:
        achou(f"Biome present ({bio}), but the react domain is NOT on")
        achou("  the Hooks rules are 'recommended for the react domain' — without the domain they never run")
        achou("  fix: \"linter\": { \"domains\": { \"react\": \"recommended\" } }")

if not tem_eslint_plugin and not tem_biome_react:
    achou("NO active net — REACT-HOOK-* and REACT-EFFECT-02/03 depend on human review")
    achou("this is the FIRST finding of the report: without it, everything here comes back next PR")
PYLINT
echo "   -- <StrictMode> (REACT-DOM-06):"
"${RG[@]}" -l 'StrictMode' "$ALVO" 2>/dev/null || vazio

titulo "1. Fetch inside an Effect" "REACT-EFFECT-06 / REACT-ASYNC-03"
"${RG[@]}" -nU 'useEffect\((?s:.{0,400}?)\b(fetch|axios)\s*[\(\.]' "$ALVO" || vazio

titulo "2. State derived by an Effect" "REACT-PAT-01"
"${RG[@]}" -nU 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$ALVO" || vazio

titulo "3. exhaustive-deps silenced" "REACT-EFFECT-03"
rg -n 'eslint-disable.*exhaustive-deps' "$ALVO" || vazio

titulo "4. Effect with an async callback" "REACT-EFFECT-12"
"${RG[@]}" -n 'useEffect\(\s*async' "$ALVO" || vazio

titulo "5. setState without the updater form" "REACT-STATE-01"
"${RG[@]}" -n 'set[A-Z]\w*\(\s*\w+\s*[-+]\s*1\s*\)' "$ALVO" || vazio

titulo "6. Memoization — inventory" "REACT-PERF-01; every occurrence needs a measurement"
"${RG[@]}" -c '\buseMemo\(|\buseCallback\(|\bmemo\(' "$ALVO" || vazio

titulo "7. index as key" "antipattern from React - Patterns § 8"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$ALVO" || vazio

titulo "8. forwardRef in current code" "REACT-REF-03"
"${RG[@]}" -n '\bforwardRef\b' "$ALVO" || vazio

titulo "9. Suspense without an Error Boundary in the same file" "REACT-ASYNC-08"
"${RG[@]}" -l '<Suspense' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'ErrorBoundary|errorElement' "$f" || echo "   $f"; done \
  | grep . || vazio

titulo "10. Mutating an array that came from props/state" "REACT-PURE-03 / REACT-PURE-05"
"${RG[@]}" -n '\b(props\.|state\.)?\w+\.(push|sort|splice|reverse|unshift)\(' "$ALVO" || vazio

titulo "11. The 'use client' boundary" "REACT-RSC-03 — what matters is how high it sits"
"${RG[@]}" -l --sort path "^['\"]use client['\"]" "$ALVO" || vazio

titulo "12. Server Function — validation at the boundary" "REACT-RSC-06"
"${RG[@]}" -l "['\"]use server['\"]" "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'safeParse|\.parse\(|zod|valibot|assert' "$f" || echo "   no visible validation: $f"; done \
  | grep . || vazio

titulo "13. Entrypoint" "REACT-DOM-01 — createRoot over server-rendered HTML"
"${RG[@]}" -n 'createRoot\(|hydrateRoot\(' "$ALVO" || vazio

titulo "14. Branching on typeof window during render" "REACT-DOM-03"
"${RG[@]}" -n 'typeof window' "$ALVO" || vazio

printf '\n\033[1m== Done.\033[0m A probe points; the reading confirms. A finding without file:line is not a finding.\n'
