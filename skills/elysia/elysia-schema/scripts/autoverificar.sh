#!/usr/bin/env bash
# Schema and Eden self-check — the 14 items of Step 7. Usage: bash autoverificar.sh <target>
set -uo pipefail

ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}
ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
n=0
semB() { n=$((n+1)); alvos="$("${RG[@]}" -l "$4" "$ALVO" 2>/dev/null)"
  falta=""
  for f in $alvos; do rg -q --no-messages "$5" "$f" || falta="$falta$f\n"; done
  if [ -n "$falta" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; printf "$falta" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }
mau() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$s" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Elysia self-check — schema and Eden — $ALVO"
mau 1 "an upload not validated by a declared content-type" ELYSIA-TYPE-02 't\.File\(|content-type.*(png|jpe?g|pdf)'
mau 2 "header name in lowercase in the schema"            ELYSIA-TYPE-03 'headers:\s*t\.Object\(\s*\{[^}]*[A-Z]'
mau 3 "t.Number in the body counting on coercion"         ELYSIA-TYPE-04 'body:\s*t\.Object\((?s:.{0,300}?)t\.Number\('
semB 4 "an additive guard declares schema: standalone"   ELYSIA-TYPE-05 'guard\(\s*\{' "schema:\s*'standalone'"
mau 5 "Eden's data used without checking error"           ELYSIA-TYPE-08 'const\s*\{\s*data\s*\}\s*=\s*await'
mau 6 "parseDate left on while feeding Query"             ELYSIA-TYPE-10 'parseDate:\s*true'
mau 7 "allowUnsafeValidationDetails turned off"           ELYSIA-TYPE-12 'allowUnsafeValidationDetails'
mau 8 "no @elysiajs/swagger"                              ELYSIA-APP-07  '@elysiajs/swagger'
echo
echo "-- response as a per-status map (ELYSIA-TYPE-06): declarations found"
"${RG[@]}" 'response:\s*\{' "$ALVO" | head -8 | ou_vazio "NONE — a multi-status route without a map makes the error arrive as unknown in Eden"
echo
echo "-- queryFn/mutationFn calling Eden (ELYSIA-TYPE-09): check that they ALL throw"
"${RG[@]}" -U '(queryFn|mutationFn):(?s:.{0,300}?)await api\.' "$ALVO" | head -8 | ou_vazio "(none)"
echo
cat <<'FIM'
Items that require reading:
  · the type derived through `typeof S.static`, not rewritten .... ELYSIA-TYPE-01
  · a Zod/Valibot route has `mapJsonSchema` in the plugin ........ ELYSIA-TYPE-07
  · the same `elysia` version on both sides ...................... ELYSIA-TYPE-11
  · a paginated listing returns an envelope, not a bare array .... ELYSIA-TYPE-13
  · `strict: true` and TS >= 5.0 on both sides ................... ELYSIA-APP-04

Run:
  tsc --noEmit         # in BOTH packages — it is Eden's only contract check
  and force an error: the query must land in isError, not in success (ELYSIA-TYPE-09)
FIM
