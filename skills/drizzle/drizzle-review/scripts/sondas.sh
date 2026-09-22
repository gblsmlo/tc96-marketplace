#!/usr/bin/env bash
# Sondas de persistência Drizzle — S1 a S3 + varredura de código. Uso: bash sondas.sh [dir]
#
# Em persistência, os piores defeitos são invisíveis à leitura: o schema parece completo,
# a query parece certa, o teste passa — e a API relacional está desligada.
set -uo pipefail

DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.ts' -trx -n --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
ou_vazio() {  # imprime a entrada; se vier vazia, a mensagem
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nada)}"; fi
}

titulo "S0. Linha de versão" "§ 0 do hub — o package.json decide qual API de relations vale"
rg -n --no-messages '"drizzle-orm"|"drizzle-kit"' package.json 2>/dev/null || vazio

titulo "S1. Registro do cliente" "DRZ-REL-05 — schema sem relations() faz \`with\` lançar"
echo "   -- tabelas e relations exportadas:"
"${RG[@]}" -o 'export const (\w+)\s*=\s*(pgTable|relations)\(' "$DIR" | sed -E 's/.*export const ([a-zA-Z0-9_]+).*/   \1/' | sort -u | head -30
echo "   -- o que é passado ao cliente:"
"${RG[@]}" -U 'drizzle\((?s:.{0,300}?)schema' "$DIR" | head -5 | ou_vazio "NÃO ENCONTRADO — sem { schema }, db.query.x é undefined"
echo "   → compare as duas listas. Ausência aqui é o achado que invalida todos os outros."

titulo "S2. Cadeia de snapshots" "migração à mão sem snapshot faz o gerador diffar de estado antigo"
J=$(find . -name '_journal.json' -not -path '*/node_modules/*' 2>/dev/null | head -1)
if [ -n "$J" ]; then
  n_j=$(rg -c --no-messages '"idx"' "$J" 2>/dev/null || echo 0)
  n_s=$(find "$(dirname "$J")" -name '*_snapshot.json' 2>/dev/null | wc -l | tr -d ' ')
  n_sql=$(find "$(dirname "$J")/.." -maxdepth 1 -name '*.sql' 2>/dev/null | wc -l | tr -d ' ')
  echo "   journal: $n_j entradas | snapshots: $n_s | arquivos .sql: $n_sql"
  [ "$n_j" != "$n_s" ] && echo "   DIVERGÊNCIA — rode \`drizzle-kit generate\` num tree limpo e veja se ele propõe SQL"
else
  echo "   sem meta/_journal.json — o projeto usa push? (DRZ-MIG-02/-04)"
fi

titulo "S3. Índices" "prefixo estrito de outro índice = custo de escrita sem leitor"
"${RG[@]}" -o 'index\(([^)]*)\)\.on\(([^)]*)\)' "$DIR" | head -20 | ou_vazio
echo "   → compare as colunas: (a) é redundante se existe (a, b)"

titulo "S4. Leitura que multiplica query" "DRZ-RQB-01 — o achado mais comum e o mais caro"
"${RG[@]}" -U '(map|forEach|for\s*\()(?s:.{0,200}?)(await\s+db|db\.query|db\.select)' "$DIR" || vazio

titulo "S5. Escrita sem where" "DRZ-QUERY-04 — bloqueante"
"${RG[@]}" -U 'db\.(update|delete)\((?s:.{0,150}?)(;|\n\n)' "$DIR" | rg -v 'where' || vazio

titulo "S6. SQL cru como via padrão" "DRZ-QUERY-03"
"${RG[@]}" 'sql`' "$DIR" || vazio
echo "   → interpolação de valor do usuário dentro de sql\`\` é achado de segurança"

titulo "S7. Transaction" "DRZ-TX-01, DRZ-TX-03 — db externo dentro do bloco"
"${RG[@]}" -U 'transaction\(\s*async\s*\((\w+)\)(?s:.{0,400}?)\bdb\.' "$DIR" || vazio

titulo "S8. push em ambiente que não é local" "DRZ-MIG-02, DRZ-MIG-04"
rg -n --no-messages 'drizzle-kit push|"db:push"' package.json .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S9. default × \$default" "DRZ-SCHEMA-04"
"${RG[@]}" '\.default\(\s*(new Date|Date\.now|crypto|uuid|nanoid)' "$DIR" || vazio
echo "   → valor computado por linha é \$default/\$defaultFn; .default() é constante no SQL"

titulo "S10. Zod à mão duplicando colunas" "DRZ-ZOD-01"
"${RG[@]}" -l 'z\.object\(' "$DIR" 2>/dev/null | head -5 | ou_vazio
echo "   → confira se poderiam vir de createInsertSchema/createSelectSchema"

printf '\n\033[1m== Fim.\033[0m S1 falhando: PARE e reporte. Com a API relacional desligada, o resto é consequência.\n'
printf 'S4 (teste de integração vivo) exige banco de pé — declare se não rodou.\n'
