#!/usr/bin/env bash
# Measures a suite's flakiness rate. Usage:
#   bash medir-flakiness.sh "<test command>" [runs]     (default: 20)
#   bash medir-flakiness.sh --inventario                (the survey alone)
#
# Without the rate there is no diagnosis — only an impression (TS-CORE-04). The threshold
# where a suite loses its value is ~1%; Google's own figure is ~0.15%.
set -uo pipefail

titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

inventario() {
  titulo "Painkillers already installed" "each one hides a cause (TS-SUI-03, -09, -11)"
  echo "   -- retry configured:"
  rg -n --no-messages 'retries|retry:|--retry|--rerun' \
     playwright.config.* bunfig.toml vitest.config.* package.json .github/workflows/*.y*ml 2>/dev/null || vazio
  echo "   -- workers/parallelism forced to 1:"
  rg -n --no-messages 'workers:\s*1|--workers[= ]1|maxConcurrency:\s*1|--concurrency[= ]1' \
     playwright.config.* vitest.config.* package.json .github/workflows/*.y*ml 2>/dev/null || vazio
  echo "   -- accumulated skip / todo (TS-SUI-11):"
  rg -c --no-messages -g '*.{spec,test}.*' '\.(skip|todo|failing)\(' . 2>/dev/null || vazio
  echo "   -- waiting on a fixed time, the no. 1 cause (TS-SUI-07):"
  rg -n --no-messages -g '*.{spec,test}.*' 'waitForTimeout|sleep\(|setTimeout\(.*(resolve|done)' . 2>/dev/null | head -10 | ou_vazio
  echo "   -- a real clock in a test about time (TS-DUB-05):"
  rg -ln --no-messages -g '*.{spec,test}.*' 'new Date\(\)|Date\.now\(\)|Math\.random\(\)' . 2>/dev/null | head -8 | ou_vazio
  echo "   -- a numeric prefix encoding order (§ 8.4 of the satellite):"
  rg --files --no-messages -g '*[0-9][0-9]-*.{spec,test}.*' . 2>/dev/null | head -5 | ou_vazio
  echo "   -- try/catch in the test body, invisible in review (§ 5 of the satellite):"
  rg -nU --no-messages -g '*.{spec,test}.*' '(test|it)\((?s:.{0,200}?)try\s*\{' . 2>/dev/null | head -5 | ou_vazio
}

if [ "${1:-}" = "--inventario" ] || [ $# -eq 0 ]; then
  inventario
  [ $# -eq 0 ] && printf '\n\033[1m== Done.\033[0m Pass the test command to measure the rate: bash medir-flakiness.sh "bun test" 20\n'
  exit 0
fi

CMD="$1"; N="${2:-20}"
inventario

titulo "Flakiness rate" "$N runs of: $CMD"
falhas=0
for i in $(seq 1 "$N"); do
  if eval "$CMD" >/dev/null 2>&1; then printf '.'; else printf 'F'; falhas=$((falhas+1)); fi
done
echo
taxa=$(awk -v f="$falhas" -v n="$N" 'BEGIN{printf "%.1f", (f/n)*100}')
echo "   runs: $N | failures: $falhas | rate: ${taxa}%"
awk -v t="$taxa" -v n="$N" 'BEGIN{
  if (t == 0)       print "   0% over " n " runs does not prove the absence of a 1-in-50 flake — run more, or use the CI history."
  else if (t < 1)   print "   below ~1%: the suite is healthy. A residual retry is legitimate here (TS-SUI-03)."
  else              print "   ABOVE ~1%: the suite has lost its value. The true red passes alongside the false ones (TS-CORE-04)."
}'

titulo "Separating the hypotheses" "run and compare — a change in behavior names the cause"
cat <<'FIM'
   alone .................. dependence on another test
   with 1 worker .......... shared state / parallelism (TS-SUI-09)
   in random order ........ order dependence
   20x the same test ...... confirms it is intermittent
   in the CI image ........ environment parity
FIM
printf '\n\033[1m== Done.\033[0m Diagnosing is not fixing: 1 worker makes the symptom vanish and keeps the coupling.\n'
