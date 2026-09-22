#!/usr/bin/env bash
# Sondas de revisão React — rodam ANTES de ler código.
# Uso: bash sondas.sh [alvo]        (alvo padrão: src, ou . se src não existir)
#
# Cada bloco imprime o que encontrou e o ID da regra a citar. Sonda não é achado:
# ela diz onde olhar. Confirme lendo o trecho antes de reportar.
set -uo pipefail

ALVO="${1:-}"
if [ -z "$ALVO" ]; then [ -d src ] && ALVO=src || ALVO=.; fi
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)

titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio()  { echo "   (nada)"; }

titulo "0. Ambiente" "muda o veredito das sondas 6 e 1"
rg -n '"react":|"react-dom":' package.json 2>/dev/null || vazio
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
echo "   -- <StrictMode> (REACT-DOM-06):"
"${RG[@]}" -l 'StrictMode' "$ALVO" 2>/dev/null || vazio

titulo "1. Fetch dentro de Effect" "REACT-EFFECT-06 / REACT-ASYNC-03"
"${RG[@]}" -nU 'useEffect\((?s:.{0,400}?)\b(fetch|axios)\s*[\(\.]' "$ALVO" || vazio

titulo "2. Estado derivado por Effect" "REACT-PAT-01"
"${RG[@]}" -nU 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$ALVO" || vazio

titulo "3. exhaustive-deps silenciado" "REACT-EFFECT-03"
rg -n 'eslint-disable.*exhaustive-deps' "$ALVO" || vazio

titulo "4. Effect com callback async" "REACT-EFFECT-12"
"${RG[@]}" -n 'useEffect\(\s*async' "$ALVO" || vazio

titulo "5. setState sem forma updater" "REACT-STATE-01"
"${RG[@]}" -n 'set[A-Z]\w*\(\s*\w+\s*[-+]\s*1\s*\)' "$ALVO" || vazio

titulo "6. Memoização — inventário" "REACT-PERF-01; cada ocorrência precisa de medida"
"${RG[@]}" -c '\buseMemo\(|\buseCallback\(|\bmemo\(' "$ALVO" || vazio

titulo "7. index como key" "antipadrão de React - Patterns § 8"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$ALVO" || vazio

titulo "8. forwardRef em código atual" "REACT-REF-03"
"${RG[@]}" -n '\bforwardRef\b' "$ALVO" || vazio

titulo "9. Suspense sem Error Boundary no mesmo arquivo" "REACT-ASYNC-08"
"${RG[@]}" -l '<Suspense' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'ErrorBoundary|errorElement' "$f" || echo "   $f"; done \
  | grep . || vazio

titulo "10. Mutação de array vindo de props/estado" "REACT-PURE-03 / REACT-PURE-05"
"${RG[@]}" -n '\b(props\.|state\.)?\w+\.(push|sort|splice|reverse|unshift)\(' "$ALVO" || vazio

titulo "11. Fronteira 'use client'" "REACT-RSC-03 — o que importa é a altura"
"${RG[@]}" -l --sort path "^['\"]use client['\"]" "$ALVO" || vazio

titulo "12. Server Function — validação na fronteira" "REACT-RSC-06"
"${RG[@]}" -l "['\"]use server['\"]" "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'safeParse|\.parse\(|zod|valibot|assert' "$f" || echo "   sem validação aparente: $f"; done \
  | grep . || vazio

titulo "13. Entrypoint" "REACT-DOM-01 — createRoot sobre HTML de servidor"
"${RG[@]}" -n 'createRoot\(|hydrateRoot\(' "$ALVO" || vazio

titulo "14. Ramificação por typeof window no render" "REACT-DOM-03"
"${RG[@]}" -n 'typeof window' "$ALVO" || vazio

printf '\n\033[1m== Fim.\033[0m Sonda aponta; a leitura confirma. Achado sem arquivo:linha não é achado.\n'
