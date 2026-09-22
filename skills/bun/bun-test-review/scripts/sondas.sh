#!/usr/bin/env bash
# `bun test` suite probes — S1 to S7. Usage: bash sondas.sh [--rodar]
#
# Without --rodar it runs only the mechanical probes (S1, partial S5, S6, S7).
# With --rodar it also runs the ones that need a working suite (S2, S3, S4, full S5).
set -uo pipefail

RODAR=0; [ "${1:-}" = "--rodar" ] && RODAR=1
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

if [ "$RODAR" -eq 0 ]; then
  cat <<'FIM'

The four probes that need a working suite (run with --rodar, or by hand):
   S2. bun test --randomize        ; echo "exit=$?"   -> order dependence (BUN-TEST-09)
   S3. bun test --isolate          ; echo "exit=$?"   -> dependence on the shared global
   S4. bun test --rerun-each 20    ; echo "exit=$?"   -> flakiness that is not about order
   S5. bun test --coverage         ; echo "exit=$?"   -> does the gate actually FAIL?
FIM
  exit 0
fi

roda() { titulo "$1" "$2"; printf '   $ %s\n' "$3"; eval "$3" >/dev/null 2>&1 && echo "   -> exit=0 (passed)" || echo "   -> exit!=0 (FAILED)"; }
roda "S2. Order dependence"                "BUN-TEST-09" "bun test --randomize"
roda "S3. Dependence on the global"        "shared by every file" "bun test --isolate"
roda "S4. Flakiness that is not about order" "a missing await, a real timer, concurrency" "bun test --rerun-each 20"
roda "S5. Does the coverage gate fail?"    "BUN-TEST-27, -28" "bun test --coverage"

cat <<'FIM'

Reading it:
  S2 fails ................ the suite only passes in discovery order (BUN-TEST-09)
  S3 fixes what was failing  state on the shared globalThis: a spy, a mocked module
  S4 fails ................ a missing await, a real timer, or concurrency (BUN-TEST-23)
  S5 exit=0 below the threshold  the gate is decorative (BUN-TEST-27/-28)

An S1 with a file, or an S5 with an open gate: report it BEFORE reviewing any content.
FIM
