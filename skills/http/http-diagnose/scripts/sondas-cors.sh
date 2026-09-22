#!/usr/bin/env bash
# As cinco sondas de CORS e negociação. Uso: bash sondas-cors.sh <url> [origem]
#
# curl NÃO faz CORS. É por isso que ele serve: mostra o que o SERVIDOR responde,
# sem o browser no meio — e separa "servidor não responde" de "browser bloqueou".
set -uo pipefail

URL="${1:-}"; ORI="${2:-http://localhost:5173}"
[ -z "$URL" ] && { echo "uso: bash sondas-cors.sh <url> [origem]" >&2; exit 1; }
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "1. O servidor responde?" "elimina o primeiro nó da árvore"
"${CURL[@]}" "$URL" | head -1 | sed 's|^|   |'

titulo "2. O preflight é tratado?" "a sonda que mais rende"
"${CURL[@]}" -X OPTIONS "$URL" -H "Origin: $ORI" \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,authorization' \
  | grep -iE '^(HTTP/|access-control)' | sed 's|^|   |'
echo "   → 401, 404 ou 405 aqui: o problema é o PREFLIGHT, não a chamada real"

titulo "3. A origem é ecoada, e há Vary?" "HTTP-CORS-03"
"${CURL[@]}" "$URL" -H "Origin: $ORI" | grep -iE 'access-control|vary' | sed 's|^|   |'

titulo "4. E quando a origem é RECUSADA?" "a que quase ninguém roda — pega HTTP-CORS-03"
"${CURL[@]}" "$URL" -H 'Origin: https://malicioso.example' | grep -iE 'access-control|vary' | sed 's|^|   |'
echo "   → origem ecoada aqui = reflexo cego (HTTP-CORS-01)"

titulo "5. Charset" "HTTP-CORE-03 / HTTP-NEG-*"
"${CURL[@]}" "$URL" | grep -i 'content-type' | sed 's|^|   |'
echo "   → text/* sem charset é acento quebrado esperando acontecer"

cat <<'FIM'

Leitura:
  1 falha ................. não é CORS: o servidor não responde
  2 devolve 401/404/405 ... o preflight não é tratado (HTTP-CORS-05/-06)
  3 sem access-control .... a origem não está permitida
  4 com access-control .... reflexo cego: qualquer origem passa (HTTP-CORS-01)
  3/4 sem Vary: Origin .... o cache mistura respostas entre origens (HTTP-CORS-03)

E o que NUNCA é a resposta: mexer no cliente. CORS é decisão do SERVIDOR.
FIM
