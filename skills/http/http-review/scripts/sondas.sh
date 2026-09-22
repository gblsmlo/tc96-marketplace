#!/usr/bin/env bash
# Sondas de contrato HTTP — S1 a S8. Rodam contra o serviço DE PÉ.
# Uso: bash sondas.sh <base-url> [rota-de-leitura] [rota-de-escrita] [origem-permitida]
#   ex: bash sondas.sh https://api.local /faturas/42 /faturas/42 http://localhost:5173
#
# curl NÃO faz CORS — e é por isso que ele serve: mostra o que o servidor responde,
# sem o browser no meio.
set -uo pipefail

BASE="${1:-}"
[ -z "$BASE" ] && { echo "uso: bash sondas.sh <base-url> [rota] [rota-escrita] [origem]" >&2; exit 1; }
LEI="${2:-/}"; ESC="${3:-$LEI}"; ORI="${4:-http://localhost:5173}"
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
cab() { grep -iE "^(HTTP/|$1)" | sed 's|^|   |'; }

titulo "S1. Headers de uma leitura" "HTTP-CACHE-01, HTTP-CORE-03"
"${CURL[@]}" "$BASE$LEI" | cab 'cache-control|etag|vary|content-type|last-modified'

titulo "S2. HEAD responde?" "HTTP-METH-06 — HEAD ausente onde GET responde"
"${CURL[@]}" -X HEAD "$BASE$LEI" | cab 'content-length|content-type'

titulo "S3. Método não suportado" "HTTP-METH-07 — 405 com Allow, não 404"
"${CURL[@]}" -X PATCH "$BASE$ESC" -H 'Content-Type: application/json' -d '{}' | cab 'allow'
echo "   em Hono, sem o middleware methodNotAllowed isto devolve 404"

titulo "S4. Condicional" "HTTP-CACHE-07 — emite ETag e ignora If-None-Match?"
ETAG=$("${CURL[@]}" "$BASE$LEI" | grep -i '^etag:' | tr -d '\r' | cut -d' ' -f2-)
if [ -n "$ETAG" ]; then
  echo "   ETag emitido: $ETAG"
  "${CURL[@]}" -H "If-None-Match: $ETAG" "$BASE$LEI" | cab 'content-length'
  echo "   → esperado 304 sem corpo (HTTP-CACHE-06)"
else
  echo "   sem ETag — a rota não é revalidável (HTTP-CACHE-05)"
fi

titulo "S5. Escrita concorrente" "HTTP-CACHE-08 — a mais grave e a menos rodada"
"${CURL[@]}" -X PUT -H 'If-Match: "obsoleto-de-proposito"' -H 'Content-Type: application/json' \
  -d '{}' "$BASE$ESC" | cab 'etag'
echo "   → esperado 412. Se aplicou a escrita, há PERDA SILENCIOSA de dado sob concorrência."

titulo "S6. Preflight" "HTTP-CORS-05, HTTP-CORS-06"
"${CURL[@]}" -X OPTIONS "$BASE$ESC" -H "Origin: $ORI" \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,authorization' | cab 'access-control'

titulo "S7. Origem RECUSADA" "HTTP-CORS-01, HTTP-CORS-03 — a que quase ninguém roda"
"${CURL[@]}" "$BASE$LEI" -H 'Origin: https://malicioso.example' | cab 'access-control|vary'
echo "   → se a origem foi ecoada, é reflexo cego (HTTP-CORS-01)"
echo "   → sem Vary: Origin, o cache serve a resposta de uma origem para outra (HTTP-CORS-03)"

titulo "S8. Corpo de erro" "HTTP-SPEC-08 — um formato só na API inteira"
for r in "$LEI/nao-existe-de-proposito"; do
  echo "   -- $BASE$r"
  curl -sS -m 10 "$BASE$r" | head -c 300 | sed 's|^|   |'; echo
done

printf '\n\033[1m== Fim.\033[0m S5 aplicando a escrita, ou S8 com dois formatos: reporte ANTES de continuar.\n'
printf 'Sonda que não rodou é "não verificado", nunca "sem achado".\n'
