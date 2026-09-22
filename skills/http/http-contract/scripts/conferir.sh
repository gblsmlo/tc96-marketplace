#!/usr/bin/env bash
# Checks an endpoint's contract with curl -i. Usage:
#   bash conferir.sh <base-url> <read-route> [write-route]
#
# Worth more than the fifteen checklist items: actually read the headers.
set -uo pipefail

BASE="${1:-}"; LEI="${2:-/}"; ESC="${3:-$LEI}"
[ -z "$BASE" ] && { echo "usage: bash conferir.sh <base-url> <route> [write-route]" >&2; exit 1; }
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "GET" "HTTP-CORE-03, HTTP-CORE-04, HTTP-CACHE-01"
"${CURL[@]}" "$BASE$LEI" | grep -iE '^(HTTP/|content-type|cache-control|etag|vary)' | sed 's|^|   |'
echo "   -> text/* without charset is HTTP-CORE-03; a response that varies by header needs Vary (HTTP-CORE-04)"

titulo "HEAD" "HTTP-METH-06 — does it answer where GET answers?"
"${CURL[@]}" -X HEAD "$BASE$LEI" | head -1 | sed 's|^|   |'

titulo "Unsupported method" "HTTP-METH-07 — 405 with Allow, never 404"
"${CURL[@]}" -X PATCH "$BASE$ESC" -H 'Content-Type: application/json' -d '{}' \
  | grep -iE '^(HTTP/|allow)' | sed 's|^|   |'

titulo "Creation" "HTTP-STATUS-03 — a 201 carries Location"
"${CURL[@]}" -X POST "$BASE$ESC" -H 'Content-Type: application/json' -d '{}' \
  | grep -iE '^(HTTP/|location|content-type)' | sed 's|^|   |'

titulo "Error" "HTTP-SPEC-08 — one format only; HTTP-CORE-06 — a failure is not a 2xx"
curl -sS -m 10 -i "$BASE$LEI/nao-existe-de-proposito" | head -1 | sed 's|^|   |'
curl -sS -m 10 "$BASE$LEI/nao-existe-de-proposito" | head -c 300 | sed 's|^|   |'; echo

cat <<'FIM'

The items curl does not decide, and that require reading the handler:
  · a safe method writes no state .......................... HTTP-CORE-02, HTTP-METH-01
  · PUT replaces the ENTIRE representation ................. HTTP-METH-03
  · a retryable POST/PATCH accepts an idempotency key ...... HTTP-METH-09
  · nothing sensitive in the query string .................. HTTP-CORE-07
  · header reads are case-insensitive ...................... HTTP-CORE-08
  · a redirect that must preserve the method is 307/308 .... HTTP-STATUS-07/-08
FIM
