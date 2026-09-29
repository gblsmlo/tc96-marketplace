#!/usr/bin/env bash
# Self-check of the test you just wrote under `bun test`. Usage: bash autoverificar.sh <file>
# Every item below is a failure that stays GREEN if it slips through.
set -uo pipefail

ALVO="${1:-}"
[ -z "$ALVO" ] && { echo "usage: bash autoverificar.sh <test-file>" >&2; exit 1; }
n=0
check() { n=$((n+1)); saida="$(rg -n --no-messages "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$saida" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$saida" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "bun test self-check — $ALVO"
case "$ALVO" in
  *.test.ts|*.test.tsx|*.test.js|*_test.ts|*.spec.ts|*.spec.tsx|*_spec.ts) echo " 0. ✓ the name matches the discovery pattern (BUN-TEST-01)";;
  *) printf '\033[1m 0. ✗ NAME OUTSIDE THE DISCOVERY PATTERN\033[0m  (BUN-TEST-01) — the file never runs, and nothing warns\n';;
esac
check 1 "assertion in catch/callback/if with expect.assertions" BUN-TEST-06 'catch\s*\(|\.then\(|forEach\('
check 2 "no done — async means async/await"                    BUN-TEST-17 '\bdone\b\s*\)|\(done\)'
check 3 "no committed .only"                                   BUN-TEST-08 '\.only\('
check 4 "a known bug goes in test.failing, not .skip"          BUN-TEST-11 '\.skip\('
check 5 "no Bun.sleep waiting on a render or a timer"          "—"         'Bun\.sleep'
check 6 ".toThrow with a class or a message"                   "—"         'toThrow\(\s*\)'
check 7 "useFakeTimers not used to freeze a date"              BUN-TEST-20 'useFakeTimers[^)]*\)[\s\S]{0,120}new Date'
check 8 "a formatted date with a fixed time zone"              BUN-TEST-21 'toLocaleDateString|toLocaleString|Intl\.DateTimeFormat'
check 9 "component: cleanup() present"                         BUN-TEST-26 'render\('
check 10 "every userEvent awaited"                             "—"         '[^t] userEvent\.'

cat <<'FIM'

Items 1, 8, 9 and 10 are heuristic: the probe points at the file, you confirm by reading.
  1  there is a catch/callback -> check whether expect.assertions(n) exists
  8  there is a formatted date -> check whether TZ is pinned
  9  there is a render()       -> check for cleanup() in afterEach (or in the preload)
 10  there is a userEvent      -> check that ALL of them are awaited

The three that require running, not reading:
  bun test <file>        # it passes in isolation
  bun test --randomize   # the suite still passes in random order (BUN-TEST-09)
  tsc --noEmit           # the runner does not check types (BUN-TEST-18)

Actually run all three. "It should pass" is not verification.
FIM
