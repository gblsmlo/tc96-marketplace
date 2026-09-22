#!/usr/bin/env bash
# Bissecção de hipóteses para um teste que falha. Uso:
#   bash isolar.sh <arquivo[:linha]> [repeticoes]     (padrão: 20)
#
# Roda a bateria da § 5.2 do hub e imprime, para cada execução, a hipótese que ela elimina.
# NUNCA use --debug para decidir se é flake: ele força timeout=0 e workers=1 (PW-DBG-02).
set -uo pipefail

ALVO="${1:-}"; N="${2:-20}"
[ -z "$ALVO" ] && { echo "uso: bash isolar.sh <arquivo[:linha]> [repeticoes]" >&2; exit 1; }
PW="${PW_CMD:-npx playwright test}"
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
roda() { printf '   $ %s\n' "$1"; eval "$1" >/dev/null 2>&1 && echo "   → passou" || echo "   → FALHOU"; }

titulo "0. O teste tem espera por tempo?" "se sim, é a causa, não o sintoma (PW-CORE-05)"
rg -n --no-messages 'waitForTimeout|networkidle' "${ALVO%%:*}" || echo "   (nada)"

titulo "1. É intermitente?" "$N execuções"
roda "$PW $ALVO --repeat-each=$N"

titulo "2. Estado compartilhado entre workers?" "PW-AUTH-03"
roda "$PW ${ALVO%%:*} --workers=1"

titulo "3. Dependência de outro teste?" "PW-CORE-06 — só este caso"
roda "$PW $ALVO"

titulo "4. Específico de browser?"
roda "$PW $ALVO --project=chromium"

titulo "5. Dependente de headless?" "raro, mas existe"
roda "$PW $ALVO --headed"

cat <<'FIM'

Leitura:
  1 falha e 3 passa .......... dependência de outro teste (PW-CORE-06)
  2 passa e o normal falha ... estado compartilhado (PW-AUTH-03) — --workers=1 DIAGNOSTICA, não conserta
  4 passa só em um project ... específico de browser
  tudo passa local ........... paridade de ambiente: rode no container da imagem do CI (PW-SNAP-02)

O que NUNCA é a resposta: subir retries (PW-RUN-03).
E antes de qualquer hipótese: leia o trace (PW-DBG-01).
FIM
