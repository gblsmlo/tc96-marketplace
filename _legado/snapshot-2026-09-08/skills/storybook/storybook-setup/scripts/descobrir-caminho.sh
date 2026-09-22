#!/usr/bin/env bash
# Descobre o caminho de framework do Storybook e confere os pisos de versão.
# Uso: bash descobrir-caminho.sh [raiz]
#
# É a única estrutura do vault em que PRESCREVER O CAMINHO ERRADO FALHA EM SILÊNCIO:
# sob react-vite, parameters.tanstack.* não tem efeito nenhum (SB-RV-04);
# sob tanstack-react, um decorator com RouterProvider cria um SEGUNDO router (SB-TS-03).
set -uo pipefail

RAIZ="${1:-.}"
cd "$RAIZ" 2>/dev/null || { echo "raiz inexistente: $RAIZ" >&2; exit 1; }
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }

MAIN=$(ls .storybook/main.* 2>/dev/null | head -1)
titulo "1. O campo framework" "SB-CFG-01 — leia ANTES de qualquer prescrição"
if [ -z "$MAIN" ]; then
  echo "   .storybook/main.* NÃO ENCONTRADO — o projeto ainda não tem Storybook"
  CAMINHO="nenhum"
else
  echo "   $MAIN"
  rg -n --no-messages 'framework' "$MAIN" | sed 's|^|   |'
  if rg -q --no-messages 'tanstack-react' "$MAIN"; then CAMINHO="A (tanstack-react)"
  elif rg -q --no-messages 'react-vite' "$MAIN"; then CAMINHO="B (react-vite)"
  else CAMINHO="indeterminado"; fi
fi
printf '\n   \033[1mCAMINHO: %s\033[0m\n' "$CAMINHO"
case "$CAMINHO" in
  A*) echo "   → família SB-TS-* · nota: Storybook - TanStack React"
      echo "   → citar SB-RV-* aqui é ACHADO INVÁLIDO";;
  B*) echo "   → família SB-RV-* · nota: Storybook - React Vite"
      echo "   → citar SB-TS-* aqui é ACHADO INVÁLIDO"
      echo "   → parameters.tanstack.* NÃO TEM EFEITO neste caminho (SB-RV-04)";;
esac

titulo "2. Os pisos de versão" "tanstack-react cobra o piso mais alto da estrutura"
rg -n --no-messages '"(react|vite|storybook|@storybook/[a-z-]+)":' package.json | sed 's|^|   |'
cat <<'FIM'
   tanstack-react ... React >= 18 · Vite >= 7
   react-vite ....... React >= 16.8 · Vite >= 5
   → Vite 5 ou 6 com tanstack-react = migração de Vite ANTES de qualquer story
FIM

titulo "3. Alinhamento de versão dos pacotes" "SB-CORE-*"
rg -n --no-messages '"(storybook|@storybook/[a-z-]+)":' package.json | sed 's|^|   |'
echo "   → todos os pacotes @storybook/* na MESMA versão da CLI"

titulo "4. De onde a config do Vite é herdada"
ls vite.config.* vitest.config.* 2>/dev/null | sed 's|^|   |' || echo "   (nenhum)"
[ -n "$MAIN" ] && rg -n --no-messages 'viteFinal|builder' "$MAIN" | sed 's|^|   |'

titulo "5. Contradição de caminho no código" "o achado que falha em silêncio"
if [ "${CAMINHO:0:1}" = "B" ]; then
  rg -n --no-messages -g '*.{ts,tsx}' 'parameters.*tanstack|tanstack:\s*\{' .storybook src 2>/dev/null \
    && echo "   ACIMA: parameters.tanstack.* sob react-vite — sem efeito, sem erro (SB-RV-04)" \
    || echo "   (nada)"
elif [ "${CAMINHO:0:1}" = "A" ]; then
  rg -n --no-messages -g '*.{ts,tsx}' 'RouterProvider' .storybook src 2>/dev/null \
    && echo "   ACIMA: RouterProvider manual sob tanstack-react — cria um SEGUNDO router (SB-TS-03)" \
    || echo "   (nada)"
fi

printf '\n\033[1m== Fim.\033[0m A escolha é praticamente irreversível: a automigração é unidirecional.\n'
