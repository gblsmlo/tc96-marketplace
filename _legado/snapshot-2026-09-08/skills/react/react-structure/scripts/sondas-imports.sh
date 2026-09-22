#!/usr/bin/env bash
# Sondas de fronteira — rodam ANTES de ler código, na ordem que falha mais.
# Uso: bash sondas-imports.sh [alvo]     (alvo padrão: src)
#
# Sonda não é achado: ela aponta o arquivo. Confirme lendo, e reporte com
# ID de Feature-Based Architecture § 4 + arquivo:linha.
set -uo pipefail

ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }

titulo "0. Enforcement" "sem isto, todo achado abaixo se repete no próximo PR"
echo "   -- biome.json:"
ls biome.json biome.jsonc 2>/dev/null || echo "   AUSENTE — primeiro achado do relatório"
echo "   -- regras de fronteira ligadas:"
rg -n 'noRestrictedImports|noImportCycles' biome.json biome.jsonc 2>/dev/null || vazio
echo "   -- aliases nos três arquivos (divergência = quebra só no teste):"
for f in tsconfig.json vite.config.ts vitest.config.ts; do
  printf '   %-18s ' "$f"
  rg -c '@features|@components|@libs|@hooks|@routes' "$f" 2>/dev/null || echo "sem alias"
done

titulo "1. Direção invertida" "REACT-ARCH-06 / REACT-ARCH-07 — o achado mais caro"
echo "   -- camada genérica importando domínio:"
GENERICAS=()
for d in components hooks libs types; do [ -d "$ALVO/$d" ] && GENERICAS+=("$ALVO/$d"); done
if [ ${#GENERICAS[@]} -gt 0 ]; then
  "${RG[@]}" -n "from '@(features|routes)/" "${GENERICAS[@]}" || vazio
else vazio; fi
echo "   -- feature importando rota:"
"${RG[@]}" -n "from '@routes/" "$ALVO/features" 2>/dev/null || vazio

titulo "2. Deep import" "REACT-ARCH-05 — três segmentos ou mais depois do alias"
"${RG[@]}" -n "from '@(features|components)/[^/']+/[^/']+/" "$ALVO" || vazio

titulo "3. Alias próprio dentro da feature" "REACT-ARCH-04 — o lint só pega quando fecha ciclo"
"${RG[@]}" -l "from '@features/" "$ALVO/features" 2>/dev/null \
  | while read -r f; do
      dono="$(echo "$f" | sed -E "s|.*features/([^/]+)/.*|\1|")"
      rg -nH "from '@features/$dono" "$f" | sed "s|^|   |"
    done | grep . || vazio

titulo "4. Barrel com lógica" "REACT-ARCH-03 — index.ts só reexporta"
find "$ALVO" -name 'index.ts' -not -path '*/node_modules/*' 2>/dev/null \
  | while read -r f; do
      rg -qv '^\s*(export|import|//|/\*|\*|$)' "$f" && echo "   $f"
    done | grep . || vazio

titulo "5. Rota inchada" "REACT-ARCH-09 — aplique o teste de bancada, não impressão"
find "$ALVO/routes" -name '*.tsx' 2>/dev/null -exec wc -l {} + 2>/dev/null | sort -rn | head -6 || vazio

titulo "6. Convenção de nome" "REACT-ARCH-12 — kebab-case em arquivo e diretório"
find "$ALVO" -name '*[A-Z]*' -not -path '*/node_modules/*' 2>/dev/null | head -10 | sed 's|^|   |' | grep . || vazio

titulo "7. Tipo saindo do barrel sem export type" "REACT-ARCH-11"
find "$ALVO" -name 'index.ts' -not -path '*/node_modules/*' 2>/dev/null \
  | xargs rg -n "^export \{[^}]*\b(Props|Type|Dto|Schema)\b" 2>/dev/null || vazio

printf '\n\033[1m== Fim.\033[0m Achado de estrutura vem antes de achado de interior: mover arquivo apaga o segundo.\n'
