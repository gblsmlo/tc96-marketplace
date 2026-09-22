#!/usr/bin/env bash
# Autoverificação do código recém-escrito. Uso: bash autoverificar.sh <arquivo-ou-diretório>
#
# Não substitui as três passadas de references/autoverificacao.md — aponta onde olhar.
# Toda saída não vazia exige decisão antes de entregar.
set -uo pipefail

ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (limpo)"; }

titulo "Ambiente" "roda antes da primeira linha, não depois"
echo "   -- React Compiler (REACT-PERF-02):"
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' \
   package.json vite.config.* babel.config.* next.config.* 2>/dev/null || vazio
echo "   -- rede de lint para REACT-HOOK-* e REACT-EFFECT-02/03:"
python3 - <<'PYLINT' 2>/dev/null || rg -n --no-messages 'react-hooks' package.json eslint.config.* .eslintrc* biome.json* 2>/dev/null || echo "      NENHUMA rede encontrada"
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
    achou("ESLint: eslint-plugin-react-hooks presente ✓")

# Biome — as regras de Hooks são recommended DO DOMÍNIO react; o domínio precisa estar ligado
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
        achou("Biome: useHookAtTopLevel e useExhaustiveDependencies declaradas ✓")
        tem_biome_react = True
    else:
        achou(f"Biome presente ({bio}), mas o domínio react NÃO está ligado")
        achou("  as regras de Hooks são 'recommended para o domínio react' — sem o domínio, não rodam")
        achou("  correção: \"linter\": { \"domains\": { \"react\": \"recommended\" } }")

if not tem_eslint_plugin and not tem_biome_react:
    achou("NENHUMA rede ativa — REACT-HOOK-* e REACT-EFFECT-02/03 dependem de revisão humana")
    achou("é o PRIMEIRO achado do relatório: sem ela, tudo aqui volta no próximo PR")
PYLINT

titulo "1. Fetch dentro de Effect" "REACT-EFFECT-06"
"${RG[@]}" -nU 'useEffect\((?s:.{0,400}?)\b(fetch|axios)\s*[\(\.]' "$ALVO" || vazio

titulo "2. Estado derivado por Effect" "REACT-PAT-01"
"${RG[@]}" -nU 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$ALVO" || vazio

titulo "3. Effect com callback async" "REACT-EFFECT-12"
"${RG[@]}" -n 'useEffect\(\s*async' "$ALVO" || vazio

titulo "4. exhaustive-deps silenciado" "REACT-EFFECT-03"
rg -n 'eslint-disable.*exhaustive-deps' "$ALVO" || vazio

titulo "5. setState sem forma updater" "REACT-STATE-01"
"${RG[@]}" -n 'set[A-Z]\w*\(\s*\w+\s*[-+]\s*1\s*\)' "$ALVO" || vazio

titulo "6. index como key" "React - Patterns § 8"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$ALVO" || vazio

titulo "7. forwardRef em código novo" "REACT-REF-03"
"${RG[@]}" -n '\bforwardRef\b' "$ALVO" || vazio

titulo "8. Memoização" "REACT-PERF-01 — cada ocorrência precisa de medida"
"${RG[@]}" -c '\buseMemo\(|\buseCallback\(|\bmemo\(' "$ALVO" || vazio

titulo "9. Fronteira 'use client'" "REACT-RSC-03 — o que importa é a altura"
"${RG[@]}" -l --sort path "^['\"]use client['\"]" "$ALVO" || vazio

titulo "10. Suspense sem Error Boundary" "REACT-ASYNC-08"
"${RG[@]}" -l '<Suspense' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'ErrorBoundary|errorElement' "$f" || echo "   $f"; done \
  | grep . || vazio

printf '\n\033[1m== Fim.\033[0m Passadas 1 a 3 de references/autoverificacao.md continuam obrigatórias.\n'
