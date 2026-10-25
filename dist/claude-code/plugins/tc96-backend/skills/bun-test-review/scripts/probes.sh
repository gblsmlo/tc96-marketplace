#!/usr/bin/env bash
# `bun test` suite probes — S1 to S7. Usage: bash probes.sh [--run]
#
# Without --run it runs only the mechanical probes (S1, partial S5, S6, S7).
# With --run it also runs the ones that need a working suite (S2, S3, S4, full S5).
set -uo pipefail

RUN=0; [ "${1:-}" = "--run" ] && RUN=1
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "S1. A test that never runs" "BUN-TEST-01 — outside the discovery pattern, with no warning"
find . -path ./node_modules -prune -o -name '*[Tt]est*' -print 2>/dev/null \
  | grep -Ev '\.(test|spec)\.[cm]?[jt]sx?$|_(test|spec)\.[cm]?[jt]sx?$|/node_modules/' \
  | grep -E '\.[cm]?[jt]sx?$' | head -10 | sed 's|^|   |' | grep . | ou_vazio

titulo "S6. Does mock restoration exist?" "BUN-TEST-02 — without it, every spyOn is a candidate to leak"
rg -n --no-messages 'preload' bunfig.toml 2>/dev/null || echo "   no preload declared in bunfig.toml"
rg -rn --no-messages 'mock\.restore\(\)' . -g '!node_modules' 2>/dev/null | head -5 | ou_vazio "NO mock.restore() in the suite"

titulo "S7. Marks and commands" "BUN-TEST-05, -08, -11, -18"
echo "   -- committed .only / .skip:"
rg -n --no-messages -g '*.{test,spec}.*' '\.(only|skip)\(' . 2>/dev/null | head -8 | ou_vazio
echo "   -- -u / global --retry / typecheck in CI:"
rg -n --no-messages 'update-snapshots| -u\b|--retry|tsc --noEmit' package.json .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S5. Does the coverage gate close?" "BUN-TEST-27, -28 — a threshold without the text reporter never fails"
rg -n --no-messages 'coverageThreshold|coverageReporter|coverage' bunfig.toml 2>/dev/null || echo "   no [test] coverage in bunfig.toml"

titulo "Extra. Configuration that fails silently" "BUN-TEST-13, -14, -24"
rg -n --no-messages 'seed|randomize|root|pathIgnorePatterns' bunfig.toml 2>/dev/null || vazio
echo "   a seed without randomize = true has no effect (BUN-TEST-14)"

if [ "$RUN" -eq 0 ]; then
  cat <<'FIM'

The four probes that need a working suite (run with --run, or by hand):
   S2. bun test --randomize --seed N, for several N    -> order dependence (BUN-TEST-09)
   S3. bun test --isolate          ; echo "exit=$?"   -> dependence on the shared global
   S4. bun test --rerun-each 20    ; echo "exit=$?"   -> flakiness that is not about order
   S5. bun test --coverage         ; echo "exit=$?"   -> does the gate actually FAIL?
FIM
  exit 0
fi

# S0: the baseline. Every later probe is read against it — a red baseline makes S4 and S5 red too.
titulo "S0. Baseline" "plain bun test, in discovery order"
printf '   $ bun test\n'
if bun test >/dev/null 2>&1; then BASE=0; echo "   -> exit=0 (green)"; else BASE=1; echo "   -> exit!=0 (RED) — S4 and S5 below inherit this failure; read them as inconclusive"; fi

titulo "S2. Order dependence" "BUN-TEST-09 — several seeds: on a small suite one random order often matches discovery order"
fails=""
for seed in 1 2 3 4 5 6 7 8; do
  bun test --randomize --seed "$seed" >/dev/null 2>&1 || fails="$fails $seed"
done
first="${fails# }"; first="${first%% *}"
if [ -n "$fails" ]; then echo "   -> FAILED with seed(s):$fails — reproduce with: bun test --randomize --seed $first"
else echo "   -> passed with 8 seeds"; fi

roda() { titulo "$1" "$2"; printf '   $ %s\n' "$3"; eval "$3" >/dev/null 2>&1 && echo "   -> exit=0 (passed)" || echo "   -> exit!=0 (FAILED)$4"; }
cascade=""; [ "$BASE" -eq 1 ] && cascade=" — the baseline is red too, so this may be the same failure"
roda "S3. Dependence on the global"        "shared by every file" "bun test --isolate" ""
roda "S4. Flakiness that is not about order" "a missing await, a real timer, concurrency" "bun test --rerun-each 20" "$cascade"
roda "S5. Does the coverage gate fail?"    "BUN-TEST-27, -28" "bun test --coverage" "$cascade"
if grep -qE '^[[:space:]]*coverage[[:space:]]*=[[:space:]]*false' bunfig.toml 2>/dev/null; then
  echo "   ✗ bunfig.toml sets coverage = false: on Bun 1.4.3 that turns --coverage into a no-op — no report, no threshold, exit 0"
fi

cat <<'FIM'

Reading it:
  S0 red .................. fix or explain the baseline first: S4 and S5 inherit any failure from it
  S2 fails ................ the suite only passes in discovery order (BUN-TEST-09); the seed reproduces it
  S2 fails, S3 passes ..... state on the shared globalThis: a spy, a mocked module, module-level state
  S4 fails, S0 green ...... a missing await, a real timer, or concurrency (BUN-TEST-23)
  S5 exit=0 below the threshold  the gate is decorative (BUN-TEST-27/-28) — or coverage = false disabled it

An S1 with a file, or an S5 with an open gate: report it BEFORE reviewing any content.
FIM
