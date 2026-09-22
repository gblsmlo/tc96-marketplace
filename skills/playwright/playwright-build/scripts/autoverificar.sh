#!/usr/bin/env bash
# Autoverificação do teste recém-escrito — os 12 itens do Passo 6.
# Uso: bash autoverificar.sh <arquivo-ou-dir>
set -uo pipefail

ALVO="${1:-e2e}"
RG=(rg --type-add 'rx:*.{ts,tsx,js}' -trx -n --no-messages)
n=0
check() { # nº | descrição | regra | padrão
  n=$((n+1))
  saida="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$saida" ]; then
    printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"
    echo "$saida" | sed 's|^|      |'
  else
    printf '%2d. ✓ %s\n' "$n" "$2"
  fi
}

echo "Autoverificação Playwright — $ALVO"
check 1 "nenhum waitForTimeout"                     PW-CORE-05 'waitForTimeout'
check 2 "nenhuma asserção lê valor antes de afirmar" PW-EXP-01  'expect\(await '
check 3 "nenhum .first()/.nth() calando strict mode" PW-LOC-02  '\.(first|nth)\('
check 4 "nenhum force: true sem motivo"              PW-ACT-01  'force:\s*true'
check 5 "nenhum networkidle"                         PW-ACT-04  "waitUntil:\s*'networkidle'"
check 6 "navegação por caminho relativo"             PW-CFG-05  "goto\('https?://"
check 7 "nenhum test.only sobrando"                  PW-CFG-01  '\.only\('
check 8 "toPass com timeout explícito"               PW-EXP-03  'toPass\(\s*\)'
check 9 "nenhum ElementHandle"                       PW-LOC-03  '\$\$?\(|elementHandle'
check 10 "nenhum dispatchEvent no lugar de click"    PW-ACT-06  'dispatchEvent\('
check 11 "skip/fixme com motivo"                     PW-STR-05  '\.(skip|fixme)\(\s*\)'
check 12 "test/expect vêm do módulo do projeto"      PW-FIX-05  "from '@playwright/test'"

cat <<'FIM'

Falta o que vale mais que os doze:
  1. quebre o código de propósito e confirme que o teste fica VERMELHO (TS-TEC-08)
  2. npx playwright test <arquivo> --repeat-each=5   — cinco verdes, não um
  3. rode a suíte inteira: teste novo que suja estado quebra o vizinho
FIM
