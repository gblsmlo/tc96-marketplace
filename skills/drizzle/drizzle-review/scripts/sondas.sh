#!/usr/bin/env bash
# Drizzle persistence probes — S1 to S3 + a code scan. Usage: bash sondas.sh [dir]
#
# In persistence the worst defects are invisible to reading: the schema looks complete,
# the query looks right, the test passes — and the relational API is turned off.
set -uo pipefail

DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.ts' -trx -n --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "S0. Version line" "§ 0 of the hub — package.json decides which relations API applies"
rg -n --no-messages '"drizzle-orm"|"drizzle-kit"' package.json 2>/dev/null || vazio

titulo "S1. Client registration" "DRZ-REL-05 — a schema with no relations() makes \`with\` throw"
echo "   -- exported tables and relations:"
"${RG[@]}" -o 'export const (\w+)\s*=\s*(pgTable|relations)\(' "$DIR" | sed -E 's/.*export const ([a-zA-Z0-9_]+).*/   \1/' | sort -u | head -30
echo "   -- what is handed to the client:"
"${RG[@]}" -U 'drizzle\((?s:.{0,300}?)schema' "$DIR" | head -5 | ou_vazio "NOT FOUND — without { schema }, db.query.x is undefined"
echo "   -> compare the two lists. A gap here is the finding that invalidates every other one."

titulo "S2. Snapshot chain" "a hand-written migration with no snapshot makes the generator diff from stale state"
J=$(find . -name '_journal.json' -not -path '*/node_modules/*' 2>/dev/null | head -1)
if [ -n "$J" ]; then
  n_j=$(rg -c --no-messages '"idx"' "$J" 2>/dev/null || echo 0)
  n_s=$(find "$(dirname "$J")" -name '*_snapshot.json' 2>/dev/null | wc -l | tr -d ' ')
  n_sql=$(find "$(dirname "$J")/.." -maxdepth 1 -name '*.sql' 2>/dev/null | wc -l | tr -d ' ')
  echo "   journal: $n_j entries | snapshots: $n_s | .sql files: $n_sql"
  [ "$n_j" != "$n_s" ] && echo "   DIVERGENCE — run \`drizzle-kit generate\` on a clean tree and see whether it proposes SQL"
else
  echo "   no meta/_journal.json — does the project use push? (DRZ-MIG-02/-04)"
fi

titulo "S3. Indexes" "a strict prefix of another index = write cost with no reader"
"${RG[@]}" -o 'index\(([^)]*)\)\.on\(([^)]*)\)' "$DIR" | head -20 | ou_vazio
echo "   -> compare the columns: (a) is redundant when (a, b) exists"

titulo "S4. A read that multiplies queries" "DRZ-RQB-01 — the most common finding, and the most expensive"
"${RG[@]}" -U '(map|forEach|for\s*\()(?s:.{0,200}?)(await\s+db|db\.query|db\.select)' "$DIR" || vazio

titulo "S5. Write with no where" "DRZ-QUERY-04 — blocking"
"${RG[@]}" -U 'db\.(update|delete)\((?s:.{0,150}?)(;|\n\n)' "$DIR" | rg -v 'where' || vazio

titulo "S6. Raw SQL as the default route" "DRZ-QUERY-03"
"${RG[@]}" 'sql`' "$DIR" || vazio
echo "   -> interpolating a user value inside sql\`\` is a security finding"

titulo "S7. Transaction" "DRZ-TX-01, DRZ-TX-03 — the outer db used inside the block"
"${RG[@]}" -U 'transaction\(\s*async\s*\((\w+)\)(?s:.{0,400}?)\bdb\.' "$DIR" || vazio

titulo "S8. push in a non-local environment" "DRZ-MIG-02, DRZ-MIG-04"
rg -n --no-messages 'drizzle-kit push|"db:push"' package.json .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S9. default x \$default" "DRZ-SCHEMA-04"
"${RG[@]}" '\.default\(\s*(new Date|Date\.now|crypto|uuid|nanoid)' "$DIR" || vazio
echo "   -> a per-row computed value is \$default/\$defaultFn; .default() is a constant in the SQL"

titulo "S10. Hand-written Zod duplicating columns" "DRZ-ZOD-01"
"${RG[@]}" -l 'z\.object\(' "$DIR" 2>/dev/null | head -5 | ou_vazio
echo "   -> check whether they could come from createInsertSchema/createSelectSchema"

printf '\n\033[1m== Done.\033[0m If S1 fails: STOP and report. With the relational API off, everything else is a consequence.\n'
printf 'S4 (a live integration test) needs a running database — declare it if you did not run it.\n'
