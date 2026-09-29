#!/usr/bin/env bash
# Playwright suite probes — S1 to S8. Usage: bash sondas.sh [test-dir]
#
# In an E2E suite the worst defects are invisible to reading: the files look right, CI is
# green, and yet the trace was never recorded or a .only cut everything down to one case.
set -uo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then for d in e2e tests test; do [ -d "$d" ] && DIR="$d" && break; done; fi
DIR="${DIR:-.}"
RG=(rg --type-add 'rx:*.{ts,tsx,js}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "S1. Version and Node floor" "PW-CORE-01, PW-CORE-03"
node -v 2>/dev/null | sed 's|^|   node |'
rg -n --no-messages '"@playwright/test"|"playwright"' package.json || vazio
echo "   the two packages must be in lockstep; 1.62 requires Node >= 22"

titulo "S2. Leftover test.only, and the gate" "PW-CFG-01 — green CI running ONE test"
"${RG[@]}" -n --no-messages '\.only\(' "$DIR" || vazio
echo "   -- forbidOnly in the config:"
rg -n --no-messages 'forbidOnly' playwright.config.* 2>/dev/null || echo "   MISSING"

titulo "S3. Does the trace exist?" "PW-CFG-02, PW-DBG-05 — 'off' in CI turns every failure into guesswork"
rg -n --no-messages 'trace\s*:' playwright.config.* 2>/dev/null || echo "   MISSING"

titulo "S4. Waiting on time" "PW-CORE-05, PW-ACT-04 — the two no. 1 causes of flake"
"${RG[@]}" -n --no-messages 'waitForTimeout|networkidle' "$DIR" || vazio

titulo "S5. An assertion that freezes the instant" "PW-EXP-01 — no linter catches it"
"${RG[@]}" -n --no-messages 'expect\(await ' "$DIR" || vazio

titulo "S6. Assertion without await" "PW-CORE-04 — it ALWAYS passes; only lint catches it"
rg -n --no-messages 'no-floating-promises|noFloatingPromises' .eslintrc* eslint.config.* biome.json* 2>/dev/null \
  || echo "   MISSING — blocking: there may be any number of assertions that assert nothing"

titulo "S7. Shard, fullyParallel e blob" "PW-RUN-01, PW-RUN-06"
rg -n --no-messages 'fullyParallel|shard|blob|merge-reports' playwright.config.* .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S8. storageState committed" "PW-AUTH-02 — a session credential in the git history"
if rg -qn --no-messages 'storageState' playwright.config.* "$DIR" 2>/dev/null; then
  rg -n --no-messages 'storageState' playwright.config.* "$DIR" 2>/dev/null | head -5
  echo "   -- does .gitignore cover the session file?"
  rg -n --no-messages 'auth|storageState|\.state\.json' .gitignore 2>/dev/null \
    || echo "   NO — a SECURITY finding; report it separately, and first"
else
  echo "   (the project does not use storageState — the login is probably in a beforeEach: PW-AUTH-01)"
fi

titulo "Extra. Agent-generated test" "PW-AGT-04, PW-AGT-05 — are the specs committed?"
rg --files --no-messages -g '*.md' "$DIR" 2>/dev/null | head -5 | ou_vazio "no .md spec beside the tests: a healer that deletes an assertion becomes undetectable"

printf '\n\033[1m== Done.\033[0m S2 with a .only and no forbidOnly, or S8 with a committed session: report BEFORE going on.\n'
