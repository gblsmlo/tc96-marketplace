#!/usr/bin/env bash
# Self-check of code under the Bun runtime. Usage: bash autoverificar.sh [dir]
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx,js}' -trx -nU --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "1. tsc --noEmit in CI" "BUN-CORE-02 — the runtime transpiles WITHOUT checking types"
rg -n --no-messages 'tsc --noEmit|tsc -p' package.json .github/workflows/*.y*ml 2>/dev/null | sed 's|^|   |' \
  || echo "   MISSING — the project's types are decorative"

titulo "2. A dependency the binary already ships" "BUN-CORE-03"
rg -n --no-messages '"(jest|ts-node|nodemon|dotenv)"' package.json 2>/dev/null | sed 's|^|   |' \
  || echo "   (none of the four)"
echo "   -> each one demands a justification for why the built-in equivalent will not do"

titulo "3. The Bun global outside the bun process" "BUN-CORE-01"
"${RG[@]}" '\bBun\.' "$DIR" | head -8 | ou_vazio
echo "   -> this code only runs under the \`bun\` process; declare that if the lib is published"

titulo "4. process.env read directly" "prefer validating at startup"
"${RG[@]}" 'process\.env\.' "$DIR" | head -8 | ou_vazio

titulo "5. Waiting on time in production code"
"${RG[@]}" 'Bun\.sleep\(|setTimeout\(' "$DIR" | head -6 | ou_vazio

titulo "6. Password hashing" "BUN-RT-* — Bun.password, not your own implementation"
"${RG[@]}" 'Bun\.password|bcrypt|argon2|createHash\(' "$DIR" || vazio
echo "   -> createHash for a PASSWORD is a security finding; Bun.password uses argon2id by default"

titulo "7. --watch × --hot" "BUN-RT-*"
rg -n --no-messages '\-\-watch|\-\-hot' package.json 2>/dev/null | sed 's|^|   |' | ou_vazio
echo "   -> --hot keeps process state; --watch restarts. A server with global state changes behavior"

titulo "8. Flag before the subcommand" "BUN-CORE-07"
rg -n --no-messages 'bun run [a-z:-]+ --[a-z]' package.json .github/workflows/*.y*ml 2>/dev/null | sed 's|^|   |' | ou_vazio

printf '\n\033[1m== Done.\033[0m Item 1 costs the most: without tsc --noEmit, a type error only shows up at runtime.\n'
