#!/usr/bin/env bash
# Bisecting hypotheses for a failing test. Usage:
#   bash isolar.sh <file[:line]> [repetitions]     (default: 20)
#
# Runs the battery from § 5.2 of the hub and prints, for each run, the hypothesis it rules out.
# NEVER use --debug to decide whether something is flaky: it forces timeout=0 and workers=1 (PW-DBG-02).
set -uo pipefail

ALVO="${1:-}"; N="${2:-20}"
[ -z "$ALVO" ] && { echo "usage: bash isolar.sh <file[:line]> [repetitions]" >&2; exit 1; }
PW="${PW_CMD:-npx playwright test}"
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
roda() { printf '   $ %s\n' "$1"; eval "$1" >/dev/null 2>&1 && echo "   -> passed" || echo "   -> FAILED"; }

titulo "0. Does the test wait on time?" "if so, that is the cause, not the symptom (PW-CORE-05)"
rg -n --no-messages 'waitForTimeout|networkidle' "${ALVO%%:*}" || echo "   (nothing)"

titulo "1. Is it intermittent?" "$N runs"
roda "$PW $ALVO --repeat-each=$N"

titulo "2. State shared between workers?" "PW-AUTH-03"
roda "$PW ${ALVO%%:*} --workers=1"

titulo "3. Dependence on another test?" "PW-CORE-06 — this case alone"
roda "$PW $ALVO"

titulo "4. Browser-specific?"
roda "$PW $ALVO --project=chromium"

titulo "5. Headless-dependent?" "rare, but real"
roda "$PW $ALVO --headed"

cat <<'FIM'

Reading it:
  1 fails and 3 passes ....... dependence on another test (PW-CORE-06)
  2 passes, the normal run fails ... shared state (PW-AUTH-03) — --workers=1 DIAGNOSES, it does not fix
  4 passes in only one project ..... browser-specific
  everything passes locally ........ environment parity: run it in the CI image (PW-SNAP-02)

What is NEVER the answer: raising retries (PW-RUN-03).
And before any hypothesis: read the trace (PW-DBG-01).
FIM
