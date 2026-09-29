#!/usr/bin/env bash
# Freshness and conditional probes. Usage: bash sondas-cache.sh <url> [write-route]
#
# The last two fail most often — and neither errors when it is not implemented:
# the conditional returns 200 with the whole body, and the concurrent write erases
# somebody else's work.
set -uo pipefail

URL="${1:-}"; ESC="${2:-$URL}"
[ -z "$URL" ] && { echo "usage: bash sondas-cache.sh <url> [write-route]" >&2; exit 1; }
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "1. Does the policy exist?" "HTTP-CACHE-01, -02, -10"
"${CURL[@]}" "$URL" | grep -iE '^(HTTP/|cache-control|etag|vary|last-modified|age)' | sed 's|^|   |'
cat <<'FIM'
   no Cache-Control ........ the policy belongs to the intermediate cache, not to you (HTTP-CACHE-01)
   public and authenticated  needs private or no-store (HTTP-CACHE-02)
   no Vary where it varies .. the cache serves the wrong response (HTTP-CACHE-10)
FIM

titulo "2. Is the conditional HANDLED?" "HTTP-CACHE-07 — emitting an ETag is not enough"
ETAG=$("${CURL[@]}" "$URL" | grep -i '^etag:' | tr -d '\r' | cut -d' ' -f2-)
if [ -n "$ETAG" ]; then
  echo "   ETag: $ETAG"
  "${CURL[@]}" -H "If-None-Match: $ETAG" "$URL" | grep -iE '^(HTTP/|content-length|cache-control|etag)' | sed 's|^|   |'
  echo "   -> expected 304 with NO body (HTTP-CACHE-06). A 200 here = a decorative ETag."
else
  echo "   no ETag: the response cannot be revalidated (HTTP-CACHE-05)"
fi

titulo "3. Concurrent write" "HTTP-CACHE-08 — the gravest one"
"${CURL[@]}" -X PUT -H 'If-Match: "obsoleto-de-proposito"' -H 'Content-Type: application/json' \
  -d '{}' "$ESC" | head -1 | sed 's|^|   |'
echo "   -> expected 412 Precondition Failed."
echo "   -> a 2xx here means silent data loss under concurrency."

titulo "4. Strong ETag for If-Match" "HTTP-CACHE-09 — W/ is no good for a write"
[ -n "${ETAG:-}" ] && case "$ETAG" in W/*) echo "   the ETag is WEAK ($ETAG) — invalid for If-Match";; *) echo "   strong ETag ✓";; esac

printf '\n\033[1m== Done.\033[0m The TanStack Query cache is ANOTHER layer, with another owner (skill tanstack-query).\n'
