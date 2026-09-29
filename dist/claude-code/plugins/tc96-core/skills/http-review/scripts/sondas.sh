#!/usr/bin/env bash
# HTTP contract probes — S1 to S8. They run against a RUNNING service.
# Usage: bash sondas.sh <base-url> [read-route] [write-route] [allowed-origin]
#   e.g.: bash sondas.sh https://api.local /invoices/42 /invoices/42 http://localhost:5173
#
# curl does NOT do CORS — and that is exactly why it helps: it shows what the server
# answers, without the browser in the way.
set -uo pipefail

BASE="${1:-}"
[ -z "$BASE" ] && { echo "usage: bash sondas.sh <base-url> [route] [write-route] [origin]" >&2; exit 1; }
LEI="${2:-/}"; ESC="${3:-$LEI}"; ORI="${4:-http://localhost:5173}"
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
cab() { grep -iE "^(HTTP/|$1)" | sed 's|^|   |'; }

titulo "S1. Headers of a read" "HTTP-CACHE-01, HTTP-CORE-03"
"${CURL[@]}" "$BASE$LEI" | cab 'cache-control|etag|vary|content-type|last-modified'

titulo "S2. Does HEAD answer?" "HTTP-METH-06 — HEAD missing where GET answers"
"${CURL[@]}" -X HEAD "$BASE$LEI" | cab 'content-length|content-type'

titulo "S3. Unsupported method" "HTTP-METH-07 — 405 with Allow, not 404"
"${CURL[@]}" -X PATCH "$BASE$ESC" -H 'Content-Type: application/json' -d '{}' | cab 'allow'
echo "   in Hono, without the methodNotAllowed middleware this returns 404"

titulo "S4. Conditional" "HTTP-CACHE-07 — does it emit an ETag and ignore If-None-Match?"
ETAG=$("${CURL[@]}" "$BASE$LEI" | grep -i '^etag:' | tr -d '\r' | cut -d' ' -f2-)
if [ -n "$ETAG" ]; then
  echo "   ETag emitted: $ETAG"
  "${CURL[@]}" -H "If-None-Match: $ETAG" "$BASE$LEI" | cab 'content-length'
  echo "   -> expected 304 with no body (HTTP-CACHE-06)"
else
  echo "   no ETag — the route cannot be revalidated (HTTP-CACHE-05)"
fi

titulo "S5. Concurrent write" "HTTP-CACHE-08 — the gravest, and the least run"
"${CURL[@]}" -X PUT -H 'If-Match: "obsoleto-de-proposito"' -H 'Content-Type: application/json' \
  -d '{}' "$BASE$ESC" | cab 'etag'
echo "   -> expected 412. If the write was applied, there is SILENT data loss under concurrency."

titulo "S6. Preflight" "HTTP-CORS-05, HTTP-CORS-06"
"${CURL[@]}" -X OPTIONS "$BASE$ESC" -H "Origin: $ORI" \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,authorization' | cab 'access-control'

titulo "S7. REFUSED origin" "HTTP-CORS-01, HTTP-CORS-03 — the one almost nobody runs"
"${CURL[@]}" "$BASE$LEI" -H 'Origin: https://malicious.example' | cab 'access-control|vary'
echo "   -> if the origin was echoed, it is blind reflection (HTTP-CORS-01)"
echo "   -> without Vary: Origin, the cache serves one origin's response to another (HTTP-CORS-03)"

titulo "S8. Error body" "HTTP-SPEC-08 — one format across the whole API"
for r in "$LEI/does-not-exist-on-purpose"; do
  echo "   -- $BASE$r"
  curl -sS -m 10 "$BASE$r" | head -c 300 | sed 's|^|   |'; echo
done

printf '\n\033[1m== Done.\033[0m S5 applying the write, or S8 with two formats: report BEFORE going on.\n'
printf 'A probe that did not run is "not verified", never "no finding".\n'
