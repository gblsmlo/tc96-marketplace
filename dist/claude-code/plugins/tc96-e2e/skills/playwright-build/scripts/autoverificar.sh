#!/usr/bin/env bash
# Self-check of the test you just wrote — the 12 items of Step 6.
# Usage: bash autoverificar.sh <file-or-dir>
set -uo pipefail

ALVO="${1:-e2e}"
RG=(rg --type-add 'rx:*.{ts,tsx,js}' -trx -n --no-messages)
n=0
check() { # no. | description | rule | pattern | [extra rg args]
  n=$((n+1))
  saida="$("${RG[@]}" "${@:5}" -e "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$saida" ]; then
    printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"
    echo "$saida" | sed 's|^|      |'
  else
    printf '%2d. ✓ %s\n' "$n" "$2"
  fi
}

echo "Playwright self-check — $ALVO"
check 1 "no waitForTimeout"                          PW-CORE-05 'waitForTimeout'
check 2 "no assertion reads a value before asserting" PW-EXP-01  'expect\(await '
check 3 "no .first()/.nth() silencing strict mode"    PW-LOC-02  '\.(first|nth)\('
check 4 "no force: true without a reason"             PW-ACT-01  'force:\s*true'
check 5 "no networkidle"                              PW-ACT-04  "waitUntil:\s*['\"\`]networkidle['\"\`]"
check 6 "navigation by relative path"                 PW-CFG-05  "goto\(\s*['\"\`]https?://"
check 7 "no leftover test.only"                       PW-CFG-01  '\.only\('
check 8 "toPass with an explicit timeout"             PW-EXP-03  'toPass\(\s*\)'
check 9 "no ElementHandle"                            PW-LOC-03  '\$\$?\(|elementHandle'
check 10 "no dispatchEvent in place of click"         PW-ACT-06  'dispatchEvent\('
check 11 "skip/fixme with a reason"                   PW-STR-05  '\.(skip|fixme)\(\s*\)'
# Only test files: the fixture module itself must import from the package. Type-only imports carry no `test`.
check 12 "test/expect come from the project module"   PW-FIX-05  "^(?!import\s+type\b).*from\s+['\"]@playwright/test['\"]" \
  -P -g '*.{spec,test}.{ts,tsx,js}'

cat <<'FIM'

What is worth more than the twelve is still missing:
  1. break the code on purpose and confirm the test goes RED (TS-TEC-08)
  2. npx playwright test <file> --repeat-each=5   — five greens, not one
  3. run the whole suite: a new test that dirties state breaks its neighbor
FIM
