#!/usr/bin/env bash
# Enumera os módulos node:* usados pelo código E pelas dependências transitivas.
# Uso: bash enumerar.sh [dir-de-código]
#
# BUN-SYS-07: é o passo que não se pode pular. A segunda busca é a que muda o plano.
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

titulo "1. No próprio código" "o que você controla"
saida=$({ rg -no "from ['\"]node:[a-z_/]+" "$DIR" 2>/dev/null; rg -no "require\(['\"]node:[a-z_/]+" "$DIR" 2>/dev/null; } \
  | sed -E "s/.*node:([a-z_/]+).*/\1/" | sort | uniq -c | sort -rn)
[ -n "$saida" ] && echo "$saida" | sed 's|^|   |' || echo "   (nenhum módulo node:* no código)"

titulo "2. Nas dependências transitivas" "a metade que costuma faltar"
if [ -d node_modules ]; then
  rg -ho "require\(['\"](node:)?(async_hooks|worker_threads|crypto|vm|cluster|dgram|inspector|perf_hooks|v8|repl|child_process|http2|tls|net)['\"]" node_modules 2>/dev/null \
    | sed -E "s/.*['\"](node:)?([a-z_2]+)['\"].*/\2/" | sort | uniq -c | sort -rn | head -20 | sed 's|^|   |' || echo "   (nada)"
else
  echo "   node_modules ausente — rode \`bun install\` antes; sem isso a enumeração é parcial"
fi

titulo "3. As quatro lacunas que importam" "confira cada uma na página oficial (BUN-CORE-05)"
cat <<'FIM'
   async_hooks .... stub que NÃO LANÇA: o código roda e o resultado é silenciosamente errado
   crypto ......... completo em quase tudo, com lacunas por cifra — confira a que você usa
   worker_threads . parcial
   vm / cluster ... parcial ou ausente

   "Funciona no Node" NÃO é evidência de que funciona no Bun.
FIM

titulo "4. O que não vai para produção"
rg -n --no-messages 'node-gyp|\.node"' package.json 2>/dev/null | sed 's|^|   |' || echo "   (sem addon nativo aparente)"

titulo "5. Container" "encerrar sem derrubar requisição"
ls Dockerfile* 2>/dev/null | sed 's|^|   |' || echo "   sem Dockerfile"
[ -f Dockerfile ] && rg -n --no-messages 'FROM|CMD|ENTRYPOINT|STOPSIGNAL|--smol' Dockerfile | sed 's|^|   |'
echo "   → sem tratamento de SIGTERM, o container encerra no meio da requisição"

printf '\n\033[1m== Fim.\033[0m A busca 2 decide a viabilidade da migração, e não aparece no código do projeto.\n'
