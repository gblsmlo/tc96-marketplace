#!/usr/bin/env bash
# Self-check of an Elysia route/handler — the 15 items of Step 6. Usage: bash autoverificar.sh <target>
set -uo pipefail
ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
n=0
mau() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$s" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }
semB() { n=$((n+1)); alvos="$("${RG[@]}" -l "$4" "$ALVO" 2>/dev/null)"
  falta=""
  for f in $alvos; do rg -q --no-messages "$5" "$f" || falta="$falta$f\n"; done
  if [ -n "$falta" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; printf "$falta" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }
bom() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -z "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s) — not found\n' "$n" "$2" "$3"
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Elysia self-check — route and handler — $ALVO"
mau 1 "no \`error\` from the context (dropped in 1.4; it is \`status\`)" ELYSIA-APP-02 '\{[^}]*\berror\b[^}]*\}\s*\)\s*=>'
mau 2 "no handler as an annotated external function"      ELYSIA-CORE-02 '\.(get|post|put|patch|delete)\([^,]+,\s*[a-zA-Z_$][\w$]*\s*[,)]'
bom 3 "export type App = typeof app"                      ELYSIA-APP-05  'export type \w+\s*=\s*typeof '
mau 4 "no @elysiajs/swagger"                              ELYSIA-APP-07  '@elysiajs/swagger'
mau 5 "process.env not read directly"                     ELYSIA-APP-09  'process\.env\.'
mau 6 "the secret is not a literal"                       ELYSIA-APP-08  "(secret|secrets)\s*:\s*'[^']{8,}'"
mau 7 "no set.status where a response schema exists"      ELYSIA-CORE-04 'set\.status\s*='
mau 8 "onError does not return error.message"             ELYSIA-CORE-07 'onError\((?s:.{0,300}?)error\.message'
semB 9 "the session cookie declares httpOnly"            ELYSIA-CORE-05 'cookie\.\w+\.value\s*=' 'httpOnly'
mau 10 "the test does not start a server over the network" ELYSIA-CORE-09 '\.listen\(\s*\d+\s*\)[\s\S]{0,200}fetch\('
bom 11 "the test awaits app.modules"                      ELYSIA-CORE-10 'await\s+\w+\.modules'
echo
cat <<'FIM'
Items that require reading (grep does not decide):
  · unbroken method chaining, never split into statements ........ ELYSIA-APP-01
  · an expected error is `return status(...)`, not `throw` ....... ELYSIA-CORE-03
  · a recurring domain error registered in `.error({...})` ....... ELYSIA-CORE-08
  · `set.headers` untouched after the first `yield` .............. ELYSIA-CORE-06
  · hooks/plugins registered BEFORE the routes they affect ....... ELYSIA-CORE-01
    (elysia-diagnose's S1 probe measures this by line order)

Run:
  tsc --noEmit         # Bun transpiles without checking types (BUN-CORE-02)
  bun test             # test through app.handle, not over the network
FIM
