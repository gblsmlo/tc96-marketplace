#!/usr/bin/env bash
# Autoverificação de código sob o runtime Bun. Uso: bash autoverificar.sh [dir]
set -uo pipefail
DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx,js}' -trx -nU --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
ou_vazio() {  # imprime a entrada; se vier vazia, a mensagem
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nada)}"; fi
}

titulo "1. tsc --noEmit no CI" "BUN-CORE-02 — o runtime transpila SEM checar tipo"
rg -n --no-messages 'tsc --noEmit|tsc -p' package.json .github/workflows/*.y*ml 2>/dev/null | sed 's|^|   |' \
  || echo "   AUSENTE — os tipos do projeto são decorativos"

titulo "2. Dependência que o binário já traz" "BUN-CORE-03"
rg -n --no-messages '"(jest|ts-node|nodemon|dotenv)"' package.json 2>/dev/null | sed 's|^|   |' \
  || echo "   (nenhuma das quatro)"
echo "   → cada uma exige justificar por que o equivalente embutido não serve"

titulo "3. Global Bun fora do processo bun" "BUN-CORE-01"
"${RG[@]}" '\bBun\.' "$DIR" | head -8 | ou_vazio
echo "   → este código só roda sob o processo \`bun\`; declare isso se a lib for publicada"

titulo "4. process.env lido direto" "prefira validar na inicialização"
"${RG[@]}" 'process\.env\.' "$DIR" | head -8 | ou_vazio

titulo "5. Espera por tempo em código de produção"
"${RG[@]}" 'Bun\.sleep\(|setTimeout\(' "$DIR" | head -6 | ou_vazio

titulo "6. Hash de senha" "BUN-RT-* — Bun.password, não implementação própria"
"${RG[@]}" 'Bun\.password|bcrypt|argon2|createHash\(' "$DIR" || vazio
echo "   → createHash para SENHA é achado de segurança; Bun.password usa argon2id por default"

titulo "7. --watch × --hot" "BUN-RT-*"
rg -n --no-messages '\-\-watch|\-\-hot' package.json 2>/dev/null | sed 's|^|   |' | ou_vazio
echo "   → --hot mantém estado do processo; --watch reinicia. Servidor com estado global muda de comportamento"

titulo "8. Flag antes do subcomando" "BUN-CORE-07"
rg -n --no-messages 'bun run [a-z:-]+ --[a-z]' package.json .github/workflows/*.y*ml 2>/dev/null | sed 's|^|   |' | ou_vazio

printf '\n\033[1m== Fim.\033[0m O item 1 é o que mais custa: sem tsc --noEmit, o erro de tipo só aparece em runtime.\n'
