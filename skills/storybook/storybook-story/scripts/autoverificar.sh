#!/usr/bin/env bash
# Autoverificação de story — os 14 itens do Passo 6. Uso: bash autoverificar.sh <arquivo-ou-dir>
set -uo pipefail
ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -nU --no-messages)
n=0
mau() { n=$((n+1)); s="$("${RG[@]}" "$4" "$ALVO" 2>/dev/null)"
  if [ -n "$s" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; echo "$s" | sed 's|^|      |' | head -6
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }
semB() { n=$((n+1)); alvos="$("${RG[@]}" -l "$4" "$ALVO" 2>/dev/null)"; falta=""
  for f in $alvos; do rg -q --no-messages "$5" "$f" || falta="$falta$f\n"; done
  if [ -n "$falta" ]; then printf '\033[1m%2d. ✗ %s\033[0m  (%s)\n' "$n" "$2" "$3"; printf "$falta" | sed 's|^|      |'
  else printf '%2d. ✓ %s\n' "$n" "$2"; fi; }

echo "Autoverificação de story — $ALVO"
semB 1 "satisfies Meta<…> no meta"                    SB-CSF-02 'const meta' 'satisfies Meta'
semB 2 "StoryObj<typeof meta> nas stories"            SB-CSF-02 'const meta' 'StoryObj<typeof meta>'
mau  3 "import de Meta/StoryObj do pacote do framework" SB-CORE-02 "from '@storybook/react'"
mau  4 "title literal (sem interpolação nem variável)" SB-CSF-03 'title:\s*[`$]'
mau  5 "nenhum argTypes que o docgen já inferiria"    SB-CSF-08 'argTypes:\s*\{'
mau  6 "nenhuma mutação de Story.args"                SB-CSF-05 '\w+\.args\s*(\.|\[)[^=]*='
mau  7 "ambiente não passa por args"                  SB-CTX-03 'args:\s*\{[^}]*(router|theme|queryClient|provider)'
mau  8 "sem efeito colateral no corpo do módulo"      SB-CORE-06 '^(?!.*(export|import|const meta|type ))\s*\w+\([^)]*\)\s*;\s*$'
mau  9 "nenhuma story dependendo de outra"            SB-CORE-05 'Default\.(play|args)\s*\('
echo
cat <<'FIM'
Itens que exigem leitura:
  · cada story é um ESTADO NOMEADO, não uma demo ......... SB-CSF-04
  · o que distingue as stories é `args` .................. SB-CSF-04
  · descrição de prop só no JSDoc ........................ SB-DOC-02
  · valor não serializável passa por `mapping` ........... SB-CSF-06
  · export que não é story está em excludeStories ........ SB-CSF-09
  · estados vazio e de erro existem, ou a ausência foi decidida  (TS-TIPO-02)

Depois, SUBA e olhe a sidebar: glob que não casa NÃO dá erro — dá sidebar vazia (SB-CFG-02).
E abra a página de docs: controles vazios são o sintoma de SB-CSF-04 violada.
FIM
