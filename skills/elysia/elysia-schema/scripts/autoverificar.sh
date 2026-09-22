#!/usr/bin/env bash
# Autoverificação de schema e Eden — os 14 itens do Passo 7. Uso: bash autoverificar.sh <alvo>
set -uo pipefail
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

echo "Autoverificação Elysia — schema e Eden — $ALVO"
mau 1 "upload não validado por content-type declarado"    ELYSIA-TYPE-02 't\.File\(|content-type.*(png|jpe?g|pdf)'
mau 2 "nome de header em minúsculas no schema"            ELYSIA-TYPE-03 'headers:\s*t\.Object\(\s*\{[^}]*[A-Z]'
mau 3 "t.Number no body contando com coerção"             ELYSIA-TYPE-04 'body:\s*t\.Object\((?s:.{0,300}?)t\.Number\('
semB 4 "guard que soma declara schema: standalone"       ELYSIA-TYPE-05 'guard\(\s*\{' "schema:\s*'standalone'"
mau 5 "data do Eden usado sem checar error"               ELYSIA-TYPE-08 'const\s*\{\s*data\s*\}\s*=\s*await'
mau 6 "parseDate não fica ligado alimentando o Query"     ELYSIA-TYPE-10 'parseDate:\s*true'
mau 7 "allowUnsafeValidationDetails desligado"            ELYSIA-TYPE-12 'allowUnsafeValidationDetails'
mau 8 "nenhum @elysiajs/swagger"                          ELYSIA-APP-07  '@elysiajs/swagger'
echo
echo "-- response como mapa por status (ELYSIA-TYPE-06): declarações encontradas"
"${RG[@]}" 'response:\s*\{' "$ALVO" | head -8 || echo "   NENHUMA — rota multi-status sem mapa faz o erro chegar como unknown no Eden"
echo
echo "-- queryFn/mutationFn que chamam Eden (ELYSIA-TYPE-09): confira se TODAS lançam"
"${RG[@]}" -U '(queryFn|mutationFn):(?s:.{0,300}?)await api\.' "$ALVO" | head -8 || echo "   (nenhuma)"
echo
cat <<'FIM'
Itens que exigem leitura:
  · tipo derivado por `typeof S.static`, não reescrito ........... ELYSIA-TYPE-01
  · rota com Zod/Valibot tem `mapJsonSchema` no plugin ........... ELYSIA-TYPE-07
  · mesma versão de `elysia` nos dois lados ...................... ELYSIA-TYPE-11
  · listagem paginada devolve envelope, não array cru ............ ELYSIA-TYPE-13
  · `strict: true` e TS >= 5.0 nos dois lados .................... ELYSIA-APP-04

Rode:
  tsc --noEmit         # nos DOIS pacotes — é a única verificação de contrato do Eden
  e force um erro: a query tem de ficar em isError, não em success (ELYSIA-TYPE-09)
FIM
