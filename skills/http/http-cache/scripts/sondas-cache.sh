#!/usr/bin/env bash
# Sondas de frescor e condicional. Uso: bash sondas-cache.sh <url> [rota-de-escrita]
#
# As duas últimas são as que mais falham — e nenhuma dá erro quando não implementada:
# a condicional devolve 200 com o corpo inteiro, e a escrita concorrente apaga o
# trabalho de outra pessoa.
set -uo pipefail

URL="${1:-}"; ESC="${2:-$URL}"
[ -z "$URL" ] && { echo "uso: bash sondas-cache.sh <url> [rota-de-escrita]" >&2; exit 1; }
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "1. A política existe?" "HTTP-CACHE-01, -02, -10"
"${CURL[@]}" "$URL" | grep -iE '^(HTTP/|cache-control|etag|vary|last-modified|age)' | sed 's|^|   |'
cat <<'FIM'
   sem Cache-Control ....... a política é do cache intermediário, não sua (HTTP-CACHE-01)
   público e autenticado ... precisa de private ou no-store (HTTP-CACHE-02)
   sem Vary onde varia ..... o cache serve a resposta errada (HTTP-CACHE-10)
FIM

titulo "2. A condicional é TRATADA?" "HTTP-CACHE-07 — emitir ETag não basta"
ETAG=$("${CURL[@]}" "$URL" | grep -i '^etag:' | tr -d '\r' | cut -d' ' -f2-)
if [ -n "$ETAG" ]; then
  echo "   ETag: $ETAG"
  "${CURL[@]}" -H "If-None-Match: $ETAG" "$URL" | grep -iE '^(HTTP/|content-length|cache-control|etag)' | sed 's|^|   |'
  echo "   → esperado 304 SEM corpo (HTTP-CACHE-06). 200 aqui = ETag decorativo."
else
  echo "   sem ETag: a resposta não é revalidável (HTTP-CACHE-05)"
fi

titulo "3. Escrita concorrente" "HTTP-CACHE-08 — a mais grave"
"${CURL[@]}" -X PUT -H 'If-Match: "obsoleto-de-proposito"' -H 'Content-Type: application/json' \
  -d '{}' "$ESC" | head -1 | sed 's|^|   |'
echo "   → esperado 412 Precondition Failed."
echo "   → 2xx aqui significa perda silenciosa de dado sob concorrência."

titulo "4. ETag forte para If-Match" "HTTP-CACHE-09 — W/ não serve para escrita"
[ -n "${ETAG:-}" ] && case "$ETAG" in W/*) echo "   ETag é FRACO ($ETAG) — inválido para If-Match";; *) echo "   ETag forte ✓";; esac

printf '\n\033[1m== Fim.\033[0m O cache do TanStack Query é OUTRA camada, com outro dono ([[tanstack-query]]).\n'
