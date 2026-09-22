#!/usr/bin/env bash
# Autoverificação de rota/handler Elysia — os 15 itens do Passo 6. Uso: bash autoverificar.sh <alvo>
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
  if [ -z "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s) — não encontrado\n' "$n" "$2" "$3"
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Autoverificação Elysia — rota e handler — $ALVO"
mau 1 "nenhum \`error\` do contexto (removido em 1.4; é \`status\`)" ELYSIA-APP-02 '\{[^}]*\berror\b[^}]*\}\s*\)\s*=>'
mau 2 "nenhum handler como função externa anotada"        ELYSIA-CORE-02 '\.(get|post|put|patch|delete)\([^,]+,\s*[a-zA-Z_$][\w$]*\s*[,)]'
bom 3 "export type App = typeof app"                      ELYSIA-APP-05  'export type \w+\s*=\s*typeof '
mau 4 "nenhum @elysiajs/swagger"                          ELYSIA-APP-07  '@elysiajs/swagger'
mau 5 "process.env não lido direto"                       ELYSIA-APP-09  'process\.env\.'
mau 6 "segredo não é literal"                             ELYSIA-APP-08  "(secret|secrets)\s*:\s*'[^']{8,}'"
mau 7 "nenhum set.status onde há schema de response"      ELYSIA-CORE-04 'set\.status\s*='
mau 8 "onError não devolve error.message"                 ELYSIA-CORE-07 'onError\((?s:.{0,300}?)error\.message'
semB 9 "cookie de sessão declara httpOnly"               ELYSIA-CORE-05 'cookie\.\w+\.value\s*=' 'httpOnly'
mau 10 "teste não sobe servidor por rede"                 ELYSIA-CORE-09 '\.listen\(\s*\d+\s*\)[\s\S]{0,200}fetch\('
bom 11 "teste aguarda app.modules"                        ELYSIA-CORE-10 'await\s+\w+\.modules'
echo
cat <<'FIM'
Itens que exigem leitura (grep não decide):
  · method chaining contínuo, sem quebrar em statements .......... ELYSIA-APP-01
  · erro esperado é `return status(...)`, não `throw` ............ ELYSIA-CORE-03
  · erro de domínio recorrente registrado em `.error({...})` ..... ELYSIA-CORE-08
  · `set.headers` não alterado depois do primeiro `yield` ........ ELYSIA-CORE-06
  · hook/plugin registrados ANTES das rotas que afetam ........... ELYSIA-CORE-01
    (a sonda S1 de elysia-diagnose mede isso por ordem de linha)

Rode:
  tsc --noEmit         # Bun transpila sem checar tipo (BUN-CORE-02)
  bun test             # teste por app.handle, não por rede
FIM
