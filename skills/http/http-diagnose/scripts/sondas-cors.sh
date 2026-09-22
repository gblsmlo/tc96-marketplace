#!/usr/bin/env bash
# The five CORS and negotiation probes. Usage: bash sondas-cors.sh <url> [origin]
#
# curl does NOT do CORS. That is exactly why it helps: it shows what the SERVER answers,
# without the browser in the way — and separates "the server does not answer" from
# "the browser blocked it".
set -uo pipefail

URL="${1:-}"; ORI="${2:-http://localhost:5173}"
[ -z "$URL" ] && { echo "usage: bash sondas-cors.sh <url> [origin]" >&2; exit 1; }
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "1. Does the server answer?" "rules out the first node of the tree"
"${CURL[@]}" "$URL" | head -1 | sed 's|^|   |'

titulo "2. Is the preflight handled?" "the probe that pays off most"
"${CURL[@]}" -X OPTIONS "$URL" -H "Origin: $ORI" \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,authorization' \
  | grep -iE '^(HTTP/|access-control)' | sed 's|^|   |'
echo "   -> a 401, 404 or 405 here: the problem is the PREFLIGHT, not the real call"

titulo "3. Is the origin echoed, and is there a Vary?" "HTTP-CORS-03"
"${CURL[@]}" "$URL" -H "Origin: $ORI" | grep -iE 'access-control|vary' | sed 's|^|   |'

titulo "4. And when the origin is REFUSED?" "the one almost nobody runs — it catches HTTP-CORS-03"
"${CURL[@]}" "$URL" -H 'Origin: https://malicious.example' | grep -iE 'access-control|vary' | sed 's|^|   |'
echo "   -> an origin echoed here = blind reflection (HTTP-CORS-01)"

titulo "5. Charset" "HTTP-CORE-03 / HTTP-NEG-*"
"${CURL[@]}" "$URL" | grep -i 'content-type' | sed 's|^|   |'
echo "   -> text/* without charset is a broken accent waiting to happen"

cat <<'FIM'

Reading it:
  1 fails ................. it is not CORS: the server does not answer
  2 returns 401/404/405 ... the preflight is not handled (HTTP-CORS-05/-06)
  3 no access-control ..... the origin is not allowed
  4 with access-control ... blind reflection: any origin gets through (HTTP-CORS-01)
  3/4 without Vary: Origin  the cache mixes responses across origins (HTTP-CORS-03)

And what is NEVER the answer: touching the client. CORS is the SERVER's decision.
FIM
