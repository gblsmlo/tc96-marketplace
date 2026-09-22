#!/usr/bin/env bash
# Sondas da FORMA da suíte — S1 a S9 de teste-review. Uso: bash sondas-suite.sh [raiz]
#
# Medem o conjunto, não os testes. Sonda não é achado: achado de forma exige o NÚMERO
# colado no relatório. S2 e S4 exigem rodar/ler o CI — este script prepara, não conclui.
set -uo pipefail

RAIZ="${1:-.}"
cd "$RAIZ" 2>/dev/null || { echo "raiz inexistente: $RAIZ" >&2; exit 1; }
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
CASO='^\s*(test|it)\s*[(.]'

titulo "S1. A forma da suíte" "TS-NIV-04 — massa em E2E é ice-cream cone"
total=0
for d in e2e tests test src packages apps; do
  [ -d "$d" ] || continue
  n=$(rg -c --no-messages -g '*.{spec,test}.*' "$CASO" "$d" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  [ "$n" -gt 0 ] && { printf '   %-12s %5d casos\n' "$d/" "$n"; total=$((total+n)); }
done
[ "$total" -eq 0 ] && vazio || echo "   ─── total: $total casos"
echo "   -- arquivos por sufixo:"
rg -l --no-messages -g '*.{spec,test}.*' "$CASO" . 2>/dev/null \
  | sed -E 's|.*/||; s|.*\.(spec\|test)\..*|\1|' | sort | uniq -c | sed 's|^|   |' | head -6

titulo "S2. Duração" "TS-SUI-* — suíte que ninguém roda antes do PR deixou de ser portão"
echo "   não automatizável sem rodar. Meça CADA nível separadamente:"
echo "     time bun test            # unidade/integração"
echo "     time bunx playwright test  # e2e"

titulo "S3. A camada estática conta?" "TS-TIPO-08 — a camada mais barata, e frequentemente desligada"
rg -n --no-messages '"strict"|noUncheckedIndexedAccess|noImplicitAny' tsconfig*.json 2>/dev/null || vazio
echo "   -- no-floating-promises (bloqueante se houver Playwright):"
rg -n --no-messages 'no-floating-promises|noFloatingPromises' .eslintrc* eslint.config.* biome.json* 2>/dev/null || echo "   AUSENTE"

titulo "S4. O portão fecha?" "TS-PROC-03 — passo que roda e não reprova é decorativo"
rg -n --no-messages 'continue-on-error|\|\| true|exit 0' .github/workflows/*.y*ml 2>/dev/null || vazio
echo "   -- passos de teste no CI (confira o exit code de cada um, não a presença):"
rg -n --no-messages 'run:.*(test|playwright|coverage)' .github/workflows/*.y*ml 2>/dev/null | head -10 || vazio

titulo "S5. Portão de cobertura como META?" "TS-CORE-05 — meta de cobertura é achado, não virtude"
rg -n --no-messages 'coverageThreshold|coverageSkipTestFiles|codecov|--coverage' \
   package.json bunfig.toml vitest.config.* jest.config.* .github/workflows/*.y*ml 2>/dev/null || vazio

titulo "S6. Classes de risco sem teste" "TS-TIPO-02 — o estado de erro é o mais ausente"
for termo in loading carregando empty vazio error erro retry recupera; do
  n=$(rg -ilc --no-messages -g '*.{spec,test}.*' "$termo" . 2>/dev/null | wc -l | tr -d ' ')
  printf '   %-12s %3s arquivos\n' "$termo" "$n"
done

titulo "S7. Atributo não funcional" "TS-TIPO-05 — requisito sem número não é verificado"
rg -ln --no-messages 'p95|percentil|lighthouse|\bk6\b|axe-core|@axe|toHaveNoViolations' . 2>/dev/null | head -8 || vazio

titulo "S8. Escape" "TS-CORE-06 — defeito de produção sem teste volta"
git log --oneline -i --grep='fix\|hotfix' --since='6 months ago' 2>/dev/null | wc -l \
  | sed 's|^|   commits de correção nos últimos 6 meses: |'
echo "   cruze com: git show --stat <sha> | rg '\\.(spec|test)\\.' — correção sem teste é o achado"

titulo "S9. skip e dívida" "TS-SUI-11 — skip sem motivo é dívida anônima"
rg -n --no-messages -g '*.{spec,test}.*' '\.(skip|todo|failing)\(|fixme' . 2>/dev/null || vazio

printf '\n\033[1m== Fim.\033[0m S1 invertida ou S4 sem reprovação: reporte ANTES de auditar o interior.\n'
