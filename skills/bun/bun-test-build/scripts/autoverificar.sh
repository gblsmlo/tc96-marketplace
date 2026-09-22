#!/usr/bin/env bash
# Autoverificação do teste recém-escrito sob `bun test`. Uso: bash autoverificar.sh <arquivo>
# Cada item abaixo é uma falha que fica VERDE se passar despercebida.
set -uo pipefail

ALVO="${1:-}"
[ -z "$ALVO" ] && { echo "uso: bash autoverificar.sh <arquivo-de-teste>" >&2; exit 1; }
n=0
check() { n=$((n+1)); saida="$(rg -n --no-messages "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$saida" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$saida" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Autoverificação bun test — $ALVO"
case "$ALVO" in
  *.test.ts|*.test.tsx|*.test.js|*_test.ts|*.spec.ts|*.spec.tsx|*_spec.ts) echo " 0. ✓ nome casa o padrão de descoberta (BUN-TEST-01)";;
  *) printf '\033[1m 0. ✗ NOME FORA DO PADRÃO DE DESCOBERTA\033[0m  (BUN-TEST-01) — o arquivo não roda, e nada avisa\n';;
esac
check 1 "asserção em catch/callback/if com expect.assertions" BUN-TEST-06 'catch\s*\(|\.then\(|forEach\('
check 2 "nenhum done — assíncrono é async/await"              BUN-TEST-17 '\bdone\b\s*\)|\(done\)'
check 3 "nenhum .only commitado"                              BUN-TEST-08 '\.only\('
check 4 "bug conhecido em test.failing, não .skip"            BUN-TEST-11 '\.skip\('
check 5 "nenhum Bun.sleep esperando render ou timer"          "—"         'Bun\.sleep'
check 6 ".toThrow com classe ou mensagem"                     "—"         'toThrow\(\s*\)'
check 7 "useFakeTimers não usado para congelar data"          BUN-TEST-20 'useFakeTimers[^)]*\)[\s\S]{0,120}new Date'
check 8 "data formatada com fuso fixo"                        BUN-TEST-21 'toLocaleDateString|toLocaleString|Intl\.DateTimeFormat'
check 9 "componente: cleanup() presente"                      BUN-TEST-26 'render\('
check 10 "todo userEvent aguardado"                           "—"         '[^t] userEvent\.'

cat <<'FIM'

Itens 1, 8, 9 e 10 são heurísticos: a sonda aponta o arquivo, você confirma lendo.
  1  há catch/callback → confira se existe expect.assertions(n)
  8  há data formatada → confira se TZ está fixado
  9  há render()       → confira se há cleanup() em afterEach (ou no preload)
 10  há userEvent      → confira se TODOS estão aguardados

As três que exigem execução, e não leitura:
  bun test <arquivo>     # passa isolado
  bun test --randomize   # a suíte ainda passa em ordem aleatória (BUN-TEST-09)
  tsc --noEmit           # o runner não checa tipo (BUN-TEST-18)

Rode as três de verdade. "Deve passar" não é verificação.
FIM
