#!/usr/bin/env bash
# Sondas de suíte Playwright — S1 a S8. Uso: bash sondas.sh [dir-de-testes]
#
# Numa suíte E2E os piores defeitos são invisíveis à leitura: os arquivos parecem certos,
# o CI está verde, e mesmo assim o trace nunca foi gravado ou um .only reduziu tudo a um caso.
set -uo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then for d in e2e tests test; do [ -d "$d" ] && DIR="$d" && break; done; fi
DIR="${DIR:-.}"
RG=(rg --type-add 'rx:*.{ts,tsx,js}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
ou_vazio() {  # imprime a entrada; se vier vazia, a mensagem
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nada)}"; fi
}

titulo "S1. Versão e piso de Node" "PW-CORE-01, PW-CORE-03"
node -v 2>/dev/null | sed 's|^|   node |'
rg -n --no-messages '"@playwright/test"|"playwright"' package.json || vazio
echo "   os dois pacotes precisam estar em lockstep; 1.62 exige Node ≥ 22"

titulo "S2. test.only sobrando, e o portão" "PW-CFG-01 — CI verde rodando UM teste"
"${RG[@]}" -n --no-messages '\.only\(' "$DIR" || vazio
echo "   -- forbidOnly no config:"
rg -n --no-messages 'forbidOnly' playwright.config.* 2>/dev/null || echo "   AUSENTE"

titulo "S3. Trace existe?" "PW-CFG-02, PW-DBG-05 — 'off' em CI torna toda falha adivinhação"
rg -n --no-messages 'trace\s*:' playwright.config.* 2>/dev/null || echo "   AUSENTE"

titulo "S4. Espera por tempo" "PW-CORE-05, PW-ACT-04 — as duas causas nº 1 de flake"
"${RG[@]}" -n --no-messages 'waitForTimeout|networkidle' "$DIR" || vazio

titulo "S5. Asserção que congela o instante" "PW-EXP-01 — nenhum linter pega"
"${RG[@]}" -n --no-messages 'expect\(await ' "$DIR" || vazio

titulo "S6. Asserção sem await" "PW-CORE-04 — passa SEMPRE; só o lint pega"
rg -n --no-messages 'no-floating-promises|noFloatingPromises' .eslintrc* eslint.config.* biome.json* 2>/dev/null \
  || echo "   AUSENTE — bloqueante: pode haver qualquer quantidade de asserção que não afirma nada"

titulo "S7. Shard, fullyParallel e blob" "PW-RUN-01, PW-RUN-06"
rg -n --no-messages 'fullyParallel|shard|blob|merge-reports' playwright.config.* .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S8. storageState versionado" "PW-AUTH-02 — credencial de sessão no histórico do git"
if rg -qn --no-messages 'storageState' playwright.config.* "$DIR" 2>/dev/null; then
  rg -n --no-messages 'storageState' playwright.config.* "$DIR" 2>/dev/null | head -5
  echo "   -- .gitignore cobre o arquivo de sessão?"
  rg -n --no-messages 'auth|storageState|\.state\.json' .gitignore 2>/dev/null \
    || echo "   NÃO — achado de SEGURANÇA, reporte separado e primeiro"
else
  echo "   (o projeto não usa storageState — login provavelmente está em beforeEach: PW-AUTH-01)"
fi

titulo "Extra. Teste gerado por agente" "PW-AGT-04, PW-AGT-05 — specs versionadas?"
rg --files --no-messages -g '*.md' "$DIR" 2>/dev/null | head -5 | ou_vazio "sem spec .md ao lado dos testes: healer que apaga asserção fica indetectável"

printf '\n\033[1m== Fim.\033[0m S2 com .only sem forbidOnly, ou S8 com sessão versionada: reporte ANTES de continuar.\n'
