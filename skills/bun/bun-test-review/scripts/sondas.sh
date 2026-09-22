#!/usr/bin/env bash
# Sondas de suíte `bun test` — S1 a S7. Uso: bash sondas.sh [--rodar]
#
# Sem --rodar, executa só as sondas mecânicas (S1, S5-parcial, S6, S7).
# Com --rodar, executa também as que exigem a suíte de pé (S2, S3, S4, S5-completa).
set -uo pipefail

RODAR=0; [ "${1:-}" = "--rodar" ] && RODAR=1
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
ou_vazio() {  # imprime a entrada; se vier vazia, a mensagem
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nada)}"; fi
}

titulo "S1. Teste que nunca roda" "BUN-TEST-01 — fora do padrão de descoberta, sem aviso"
find . -path ./node_modules -prune -o -name '*[Tt]est*' -print 2>/dev/null \
  | grep -Ev '\.(test|spec)\.[cm]?[jt]sx?$|_(test|spec)\.[cm]?[jt]sx?$|/node_modules/' \
  | grep -E '\.[cm]?[jt]sx?$' | head -10 | sed 's|^|   |' | grep . | ou_vazio

titulo "S6. Restauração de mock existe?" "BUN-TEST-02 — sem isso, todo spyOn é candidato a vazar"
rg -n --no-messages 'preload' bunfig.toml 2>/dev/null || echo "   sem preload declarado em bunfig.toml"
rg -rn --no-messages 'mock\.restore\(\)' . -g '!node_modules' 2>/dev/null | head -5 | ou_vazio "NENHUM mock.restore() na suíte"

titulo "S7. Marcas e comandos" "BUN-TEST-05, -08, -11, -18"
echo "   -- .only / .skip commitados:"
rg -n --no-messages -g '*.{test,spec}.*' '\.(only|skip)\(' . 2>/dev/null | head -8 | ou_vazio
echo "   -- -u / --retry global / typecheck no CI:"
rg -n --no-messages 'update-snapshots| -u\b|--retry|tsc --noEmit' package.json .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S5. O portão de cobertura fecha?" "BUN-TEST-27, -28 — limiar sem reporter text não reprova"
rg -n --no-messages 'coverageThreshold|coverageReporter|coverage' bunfig.toml 2>/dev/null || echo "   sem [test] coverage em bunfig.toml"

titulo "Extra. Configuração que falha em silêncio" "BUN-TEST-13, -14, -24"
rg -n --no-messages 'seed|randomize|root|pathIgnorePatterns' bunfig.toml 2>/dev/null || vazio
echo "   seed sem randomize = true não tem efeito (BUN-TEST-14)"

if [ "$RODAR" -eq 0 ]; then
  cat <<'FIM'

As quatro sondas que exigem a suíte de pé (rode com --rodar, ou à mão):
   S2. bun test --randomize        ; echo "exit=$?"   → dependência de ordem (BUN-TEST-09)
   S3. bun test --isolate          ; echo "exit=$?"   → dependência do global compartilhado
   S4. bun test --rerun-each 20    ; echo "exit=$?"   → flaky que não é de ordem
   S5. bun test --coverage         ; echo "exit=$?"   → o portão REPROVA mesmo?
FIM
  exit 0
fi

roda() { titulo "$1" "$2"; printf '   $ %s\n' "$3"; eval "$3" >/dev/null 2>&1 && echo "   → exit=0 (passou)" || echo "   → exit≠0 (FALHOU)"; }
roda "S2. Dependência de ordem"            "BUN-TEST-09" "bun test --randomize"
roda "S3. Dependência do global"           "compartilhado por todos os arquivos" "bun test --isolate"
roda "S4. Flaky que não é de ordem"        "await faltando, timer real, concorrência" "bun test --rerun-each 20"
roda "S5. O portão de cobertura reprova?"  "BUN-TEST-27, -28" "bun test --coverage"

cat <<'FIM'

Leitura:
  S2 falha ................ a suíte passa só na ordem de descoberta (BUN-TEST-09)
  S3 conserta o que falhava  estado no globalThis compartilhado: spy, módulo mockado
  S4 falha ................ await faltando, timer real, ou concorrência (BUN-TEST-23)
  S5 exit=0 abaixo do limiar  o portão é decorativo (BUN-TEST-27/-28)

S1 com arquivo, ou S5 com portão aberto: reporte ANTES de revisar conteúdo.
FIM
