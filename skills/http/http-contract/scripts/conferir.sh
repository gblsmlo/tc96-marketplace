#!/usr/bin/env bash
# Confere o contrato de um endpoint com curl -i. Uso:
#   bash conferir.sh <base-url> <rota-de-leitura> [rota-de-escrita]
#
# Vale mais que os quinze itens da checklist: leia os headers de verdade.
set -uo pipefail

BASE="${1:-}"; LEI="${2:-/}"; ESC="${3:-$LEI}"
[ -z "$BASE" ] && { echo "uso: bash conferir.sh <base-url> <rota> [rota-escrita]" >&2; exit 1; }
CURL=(curl -sS -i -m 10)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "GET" "HTTP-CORE-03, HTTP-CORE-04, HTTP-CACHE-01"
"${CURL[@]}" "$BASE$LEI" | grep -iE '^(HTTP/|content-type|cache-control|etag|vary)' | sed 's|^|   |'
echo "   → text/* sem charset é HTTP-CORE-03; resposta que varia por header precisa de Vary (HTTP-CORE-04)"

titulo "HEAD" "HTTP-METH-06 — responde onde GET responde?"
"${CURL[@]}" -X HEAD "$BASE$LEI" | head -1 | sed 's|^|   |'

titulo "Método não suportado" "HTTP-METH-07 — 405 com Allow, nunca 404"
"${CURL[@]}" -X PATCH "$BASE$ESC" -H 'Content-Type: application/json' -d '{}' \
  | grep -iE '^(HTTP/|allow)' | sed 's|^|   |'

titulo "Criação" "HTTP-STATUS-03 — 201 leva Location"
"${CURL[@]}" -X POST "$BASE$ESC" -H 'Content-Type: application/json' -d '{}' \
  | grep -iE '^(HTTP/|location|content-type)' | sed 's|^|   |'

titulo "Erro" "HTTP-SPEC-08 — um formato só; HTTP-CORE-06 — falha não é 2xx"
curl -sS -m 10 -i "$BASE$LEI/nao-existe-de-proposito" | head -1 | sed 's|^|   |'
curl -sS -m 10 "$BASE$LEI/nao-existe-de-proposito" | head -c 300 | sed 's|^|   |'; echo

cat <<'FIM'

Os itens que curl não decide, e exigem leitura do handler:
  · método safe não escreve estado ......................... HTTP-CORE-02, HTTP-METH-01
  · PUT substitui a representação INTEIRA ................. HTTP-METH-03
  · POST/PATCH retentável aceita chave de idempotência .... HTTP-METH-09
  · nada sensível em query string ......................... HTTP-CORE-07
  · leitura de header é case-insensitive .................. HTTP-CORE-08
  · redirect que precisa do método é 307/308 .............. HTTP-STATUS-07/-08
FIM
