#!/usr/bin/env bash
# Sondas de dependência e workspace sob Bun. Uso: bash sondas.sh [raiz]
#
# A primeira é a que quebra o build inteiro e falha em RUNTIME, longe da causa.
set -uo pipefail
RAIZ="${1:-.}"; cd "$RAIZ" 2>/dev/null || { echo "raiz inexistente" >&2; exit 1; }
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }

titulo "S1. trustedDependencies SUBSTITUI a lista padrão" "BUN-PKG-04 — não estende"
python3 - <<'PYJSON' 2>/dev/null || echo "   (python3 ausente: confira trustedDependencies à mão)"
import json, sys, pathlib
try:
    pkg = json.loads(pathlib.Path("package.json").read_text())
except Exception as e:
    print(f"   package.json não lido: {e}"); sys.exit(0)
td = pkg.get("trustedDependencies")
if td is None:
    print("   trustedDependencies não declarado — a lista padrão do Bun está valendo (ok)"); sys.exit(0)
print(f"   declarado: {td}")
deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
padrao = ["sharp", "esbuild", "better-sqlite3", "puppeteer", "canvas", "bcrypt", "node-sass", "sqlite3"]
desligados = [p for p in padrao if p in deps and p not in td]
if desligados:
    print("   \u26a0 SCRIPTS DE INSTALAÇÃO DESLIGADOS para: " + ", ".join(desligados))
    print("   → o sintoma não é erro de instalação: é binário não compilado, falhando em runtime")
    print("   → reinclua na MESMA lista os que ainda são necessários")
else:
    print("   nenhum pacote conhecido da lista padrão ficou de fora")
PYJSON
echo "   -- o que está bloqueado hoje, e o comando de cada um (rode você mesmo):"
echo "   $ bun pm untrusted"
echo "   → BUN-PKG-03: PR que adiciona entrada ali traz essa saída no corpo"

titulo "S2. Lockfile e CI" "BUN-PKG-02 — bun ci, não bun install"
ls bun.lock bun.lockb 2>/dev/null | sed 's|^|   |' || echo "   SEM LOCKFILE versionado"
rg -n --no-messages 'bun install|bun ci' .github/workflows/*.y*ml 2>/dev/null | sed 's|^|   |' || vazio
echo "   → \`bun install\` em CI pode atualizar o lockfile; \`bun ci\` falha se ele divergir"

titulo "S3. Workspace declarado" "monorepo"
rg -n --no-messages -A4 '"workspaces"' package.json 2>/dev/null | sed 's|^|   |' || echo "   não é workspace"

titulo "S4. Catalogs e overrides" "versão compartilhada, e resolução forçada"
rg -n --no-messages -A4 '"catalog"|"catalogs"|"overrides"|"resolutions"' package.json 2>/dev/null | sed 's|^|   |' || vazio
echo "   → \"resolutions\" é do Yarn; no Bun a chave é \"overrides\""

titulo "S5. Linker" "isolated × hoisted muda o que um pacote enxerga"
rg -n --no-messages 'linker' bunfig.toml package.json 2>/dev/null | sed 's|^|   |' || echo "   não declarado — vale o default"

titulo "S6. Patch versionado" "bun patch"
ls -d patches 2>/dev/null && ls patches | sed 's|^|   |' || echo "   sem patches/"

titulo "S7. bunx sem versão fixa" "executar pacote remoto sem pin"
rg -n --no-messages 'bunx ' package.json .github/workflows/*.y*ml 2>/dev/null | rg -v '@[0-9]' || vazio
echo "   → bunx sem @versão executa o que estiver publicado no momento"

titulo "S8. Versão do Bun pinada" "BUN-TEST-15 e paridade local × CI"
rg -n --no-messages 'bun-version|BUN_VERSION|"packageManager"' .github/workflows/*.y*ml package.json .tool-versions 2>/dev/null | sed 's|^|   |' || echo "   NÃO PINADA"

printf '\n\033[1m== Fim.\033[0m S1 é a que quebra o build inteiro — e o sintoma aparece em runtime, não na instalação.\n'
