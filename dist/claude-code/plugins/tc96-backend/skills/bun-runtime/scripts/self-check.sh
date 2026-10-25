#!/usr/bin/env bash
# Self-check of code under the Bun runtime. Usage: bash self-check.sh [code-dir]
# Run it from the project root: it reads package.json, .env* and .github/ from the current directory.
#
# Items marked ✗ are findings; items marked ? are heuristic — the probe points, you confirm by reading.
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
title() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
or_empty() {  # prints the input; when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s\n' "$out"; else echo "   ${1:-(nothing)}"; fi
}
# grep over code files, recursive, with line numbers; never fails the script
code() { grep -rnE --include='*.ts' --include='*.tsx' --include='*.js' --include='*.mjs' --include='*.cjs' "$@" "$DIR" 2>/dev/null || true; }

title "1. Type checking runs somewhere" "BUN-CORE-02 — the runtime transpiles WITHOUT checking types"
# a script named like typecheck that calls tsc, and a CI step that runs tsc or that script
tc_script="$(python3 -c "
import json
try:
    s = json.load(open('package.json')).get('scripts', {})
except Exception:
    s = {}
print('\n'.join(f'{k}: {v}' for k, v in s.items() if 'tsc' in v))" 2>/dev/null)"
[ -n "$tc_script" ] && echo "$tc_script" | sed 's|^|   package.json script  |' || echo "   ✗ no package.json script calls tsc"
names="$(echo "$tc_script" | sed -n 's/:.*//p' | paste -sd'|' -)"
ci="$( { grep -nE "tsc( |$)${names:+|bun run (${names})}" .github/workflows/*.y*ml 2>/dev/null || true; } )"
[ -n "$ci" ] && echo "$ci" | sed 's|^|   CI  |' || echo "   ✗ MISSING in CI — no workflow step runs tsc or that script: the project's types are decorative"

title "2. A dependency the binary already ships" "BUN-CORE-03"
{ grep -nE '"(jest|ts-node|nodemon|dotenv)"' package.json 2>/dev/null || true; } | sed 's|^|   ✗ |' | or_empty "(none of the four)"
echo "   -> each one demands a justification for why the built-in equivalent will not do"

title "3. Blocking calls in a request path" "BUN-RT-08 — one *Sync in a handler stops the whole server"
code '\b(execSync|spawnSync|execFileSync|readFileSync|writeFileSync|existsSync|readdirSync|statSync)\(|Bun\.spawnSync\(' \
  | sed 's|^|   ? |' | or_empty "(no *Sync call)"
echo "   -> a hit inside a route handler, fetch() or a function it calls is a finding; at boot it is fine"

title "4. A shell command built from a string" "BUN-SYS-01 — injection through the value"
code '\b(exec|execSync)\(\s*[`"'"'"'][^)]*(\$\{|"\s*\+|'"'"'\s*\+)' | sed 's|^|   ✗ |' | or_empty "(no concatenated exec)"
code '\$`[^`]*(bash|sh) -c' | sed 's|^|   ✗ nested shell (BUN-SYS-02): |'
echo "   -> pass values through Bun.\$ interpolation or a Bun.spawn argv array; reject a value starting with - (BUN-SYS-03)"

title "5. Subprocess without a limit" "BUN-RT-09"
code 'Bun\.spawn\(' | while IFS= read -r line; do
  f="${line%%:*}"; grep -qE 'timeout|signal' "$f" 2>/dev/null || echo "   ? $line   (no timeout/signal in this file)"
done | or_empty "(every Bun.spawn file mentions timeout or signal)"

title "6. A literal \$ in a .env value" "BUN-RT-07 — Bun expands variables: Sup3r\$ecret arrives as Sup3r"
for f in .env .env.*; do
  [ -f "$f" ] || continue
  grep -nE '^[A-Za-z_][A-Za-z0-9_]*=.*[^\\]\$[A-Za-z_{]' "$f" | grep -vE "^[0-9]+:[A-Za-z_0-9]+='" | sed "s|^|   ✗ $f:|"
done | or_empty "(no unescaped \$ in .env files)"
echo "   -> escape it as \\\$, or move the secret out of the runtime .env (BUN-RT-05)"

title "7. The environment is validated at startup" "BUN-RT-06"
code 'process\.env\.|Bun\.env\.' | head -8 | sed 's|^|   ? |' | or_empty "(no direct env read)"
code '\.(parse|safeParse)\(\s*(process\.env|Bun\.env)' | sed 's|^|   validation: |' | or_empty "✗ no schema parse of process.env — a missing variable arrives as undefined"

title "8. Password hashing" "BUN-RT-10 — Bun.password, never Bun.hash or createHash"
code 'Bun\.password|bcrypt|argon2|createHash\(|Bun\.hash' | sed 's|^|   ? |' | or_empty "(no hashing)"
echo "   -> createHash or Bun.hash for a PASSWORD is a security finding; Bun.password uses argon2id by default"

title "9. --watch × --hot" "BUN-RT-11"
{ grep -nE '\-\-watch|\-\-hot' package.json 2>/dev/null || true; } | sed 's|^|   |' | or_empty
code '^(const|let|var) [a-zA-Z_]+ = new (Map|Set|WeakMap)(<|\()' | sed 's|^|   module-level state: |'
echo "   -> --hot keeps process state; --watch restarts. A server with module-level state changes behavior"

title "10. Flag before the subcommand" "BUN-CORE-07"
{ grep -nE 'bun run [a-z:-]+ --[a-z]' package.json .github/workflows/*.y*ml 2>/dev/null || true; } | sed 's|^|   ✗ |' | or_empty

printf '\n\033[1m== Done.\033[0m Items 3, 4 and 6 are the ones that break production; item 1 is the one that costs most over time.\n'
