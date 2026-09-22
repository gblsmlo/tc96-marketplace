#!/usr/bin/env bash
# Autoverificação de teste em story — os 14 itens do Passo 5. Uso: bash autoverificar.sh <alvo>
# Passo 0 SEMPRE: descubra o caminho do framework antes de qualquer prescrição de router.
set -uo pipefail
ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)

printf '\033[1m== Passo 0 — o caminho do framework\033[0m  SB-CFG-01\n'
MAIN=$(ls .storybook/main.* 2>/dev/null | head -1)
if [ -n "$MAIN" ]; then
  rg -n --no-messages 'framework' "$MAIN" | sed 's|^|   |'
  rg -q 'tanstack-react' "$MAIN" && echo "   CAMINHO A — família SB-TS-*; citar SB-RV-* aqui é achado inválido"
  rg -q 'react-vite' "$MAIN"     && echo "   CAMINHO B — família SB-RV-*; parameters.tanstack.* NÃO tem efeito (SB-RV-04)"
else echo "   .storybook/main.* não encontrado — descubra o caminho antes de prescrever"; fi
echo

n=0
mau() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$s" | sed 's|^|      |' | head -6
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

n=1; s1="$("${RG[@]}" '\bexpect\(' "$ALVO" 2>/dev/null | rg -v 'await expect|expect\.extend|await expect\.' || true)"
if [ -n "$s1" ]; then printf '\033[1m 1. ✗ %s\033[0m  (%s)\n' "todo expect aguardado" "SB-TEST-01"; echo "$s1" | sed 's|^|      |' | head -6
else printf ' 1. ✓ %s\n' "todo expect aguardado"; fi
mau 2 "primeira query assíncrona é findBy…"      SB-TEST-10 'await\s+canvas\.getBy'
mau 3 "callback é fn() em args"                  SB-TEST-03 'render:\s*\([^)]*\)\s*=>\s*<[^>]*on[A-Z]\w*=\{\('
mau 4 "utilitários de storybook/test, sem @"     SB-CORE-01 "from '@storybook/test'"
mau 5 "import de Meta/StoryObj do framework"     SB-CORE-02 "from '@storybook/react'"
mau 6 "query por papel/rótulo, não por classe"   SB-TEST-06 'querySelector\(|getByTestId\('
mau 7 "sb.mock() fora do preview"                SB-MOCK-01 'sb\.mock\('
mau 8 "sem asserção sobre implementação interna" SB-TEST-09 'expect\(\w+\.(state|props|_)'
echo
cat <<'FIM'
Itens que exigem leitura:
  · mount desestruturado e chamado, se há setup antes do render ... SB-TEST-02
  · comportamento do mock em beforeEach, não no preview ........... SB-MOCK-04
  · beforeEach que altera ambiente retorna a limpeza .............. SB-CTX-08
  · a11y.test é 'error' onde se espera que o CI reprove ........... SB-TEST-04
  · o que distingue a story é `args` .............................. SB-CSF-04

E a que vale mais que as catorze:
  quebre o componente de propósito e confirme que a story fica VERMELHA (TS-TEC-08).
  Se nada quebrar, a play não afirma nada.

Depois rode:  vitest run --project=storybook     (sem `run` entra em watch mode)
FIM
