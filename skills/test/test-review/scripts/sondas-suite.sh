#!/usr/bin/env bash
# Probes of the suite's SHAPE — S1 to S9 of test-review. Usage: bash sondas-suite.sh [root]
#
# They measure the set, not the tests. A probe is not a finding: a finding about shape needs
# the NUMBER pasted into the report. S2 and S4 require running/reading CI — this script
# prepares, it does not conclude.
set -uo pipefail

RAIZ="${1:-.}"
cd "$RAIZ" 2>/dev/null || { echo "root does not exist: $RAIZ" >&2; exit 1; }
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}
CASO='^\s*(test|it)\s*[(.]'

titulo "S1. The shape of the suite" "TS-NIV-04 — mass in E2E is an ice-cream cone"
total=0
for d in e2e tests test src packages apps; do
  [ -d "$d" ] || continue
  n=$(rg -c --no-messages -g '*.{spec,test}.*' "$CASO" "$d" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  [ "$n" -gt 0 ] && { printf '   %-12s %5d cases\n' "$d/" "$n"; total=$((total+n)); }
done
[ "$total" -eq 0 ] && vazio || echo "   ─── total: $total cases"
echo "   -- files by suffix:"
rg -l --no-messages -g '*.{spec,test}.*' "$CASO" . 2>/dev/null \
  | sed -E 's|.*/||; s|.*\.(spec\|test)\..*|\1|' | sort | uniq -c | sed 's|^|   |' | head -6

titulo "S2. Duration" "TS-SUI-* — a suite nobody runs before the PR has stopped being a gate"
echo "   cannot be automated without running it. Measure EACH level separately:"
echo "     time bun test            # unit/integration"
echo "     time bunx playwright test  # e2e"

titulo "S3. Does the static layer count?" "TS-TIPO-08 — the cheapest layer, and often turned off"
rg -n --no-messages '"strict"|noUncheckedIndexedAccess|noImplicitAny' tsconfig*.json 2>/dev/null || vazio
echo "   -- no-floating-promises (blocking when Playwright is present):"
rg -n --no-messages 'no-floating-promises|noFloatingPromises' .eslintrc* eslint.config.* biome.json* 2>/dev/null || echo "   MISSING"

titulo "S4. Does the gate close?" "TS-PROC-03 — a step that runs and never fails is decorative"
rg -n --no-messages 'continue-on-error|\|\| true|exit 0' .github/workflows/*.y*ml 2>/dev/null || vazio
echo "   -- test steps in CI (check each one's exit code, not its presence):"
rg -n --no-messages 'run:.*(test|playwright|coverage)' .github/workflows/*.y*ml 2>/dev/null | head -10 | ou_vazio

titulo "S5. A coverage gate used as a TARGET?" "TS-CORE-05 — a coverage target is a finding, not a virtue"
rg -n --no-messages 'coverageThreshold|coverageSkipTestFiles|codecov|--coverage' \
   package.json bunfig.toml vitest.config.* jest.config.* .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S6. Risk classes with no test" "TS-TIPO-02 — the error state is the one most often missing"
for termo in loading carregando empty vazio error erro retry recupera; do
  n=$(rg -ilc --no-messages -g '*.{spec,test}.*' "$termo" . 2>/dev/null | wc -l | tr -d ' ')
  printf '   %-12s %3s files\n' "$termo" "$n"
done

titulo "S7. Non-functional attribute" "TS-TIPO-05 — a requirement without a number is not verified"
rg -ln --no-messages 'p95|percentil|lighthouse|\bk6\b|axe-core|@axe|toHaveNoViolations' . 2>/dev/null | head -8 | ou_vazio

titulo "S8. Escape" "TS-CORE-06 — a production defect with no test comes back"
git log --oneline -i --grep='fix\|hotfix' --since='6 months ago' 2>/dev/null | wc -l \
  | sed 's|^|   fix commits in the last 6 months: |'
echo "   cross-check with: git show --stat <sha> | rg '\\.(spec|test)\\.' — a fix with no test is the finding"

titulo "S9. skip and debt" "TS-SUI-11 — a skip with no reason is anonymous debt"
rg -n --no-messages -g '*.{spec,test}.*' '\.(skip|todo|failing)\(|fixme' . 2>/dev/null || vazio

printf '\n\033[1m== Done.\033[0m An inverted S1 or an S4 that never fails: report it BEFORE auditing the inside.\n'
