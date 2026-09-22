#!/usr/bin/env bash
# Mede a taxa de flakiness de uma suíte. Uso:
#   bash medir-flakiness.sh "<comando de teste>" [execuções]     (padrão: 20)
#   bash medir-flakiness.sh --inventario                          (só o levantamento)
#
# Sem a taxa não há diagnóstico — há impressão (TS-CORE-04). O limiar em que uma suíte
# perde valor é ~1%; o índice do Google é ~0,15%.
set -uo pipefail

titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }

inventario() {
  titulo "Anestésicos já instalados" "cada um esconde uma causa (TS-SUI-03, -09, -11)"
  echo "   -- retry configurado:"
  rg -n --no-messages 'retries|retry:|--retry|--rerun' \
     playwright.config.* bunfig.toml vitest.config.* package.json .github/workflows/*.y*ml 2>/dev/null || vazio
  echo "   -- workers/paralelismo forçado a 1:"
  rg -n --no-messages 'workers:\s*1|--workers[= ]1|maxConcurrency:\s*1|--concurrency[= ]1' \
     playwright.config.* vitest.config.* package.json .github/workflows/*.y*ml 2>/dev/null || vazio
  echo "   -- skip / todo acumulado (TS-SUI-11):"
  rg -c --no-messages -g '*.{spec,test}.*' '\.(skip|todo|failing)\(' . 2>/dev/null || vazio
  echo "   -- espera por tempo fixo, a causa nº 1 (TS-SUI-07):"
  rg -n --no-messages -g '*.{spec,test}.*' 'waitForTimeout|sleep\(|setTimeout\(.*(resolve|done)' . 2>/dev/null | head -10 || vazio
  echo "   -- relógio real em teste sobre tempo (TS-DUB-05):"
  rg -ln --no-messages -g '*.{spec,test}.*' 'new Date\(\)|Date\.now\(\)|Math\.random\(\)' . 2>/dev/null | head -8 || vazio
  echo "   -- prefixo numérico codificando ordem (§ 8.4 do satélite):"
  rg --files --no-messages -g '*[0-9][0-9]-*.{spec,test}.*' . 2>/dev/null | head -5 || vazio
  echo "   -- try/catch no corpo do teste, invisível em revisão (§ 5 do satélite):"
  rg -nU --no-messages -g '*.{spec,test}.*' '(test|it)\((?s:.{0,200}?)try\s*\{' . 2>/dev/null | head -5 || vazio
}

if [ "${1:-}" = "--inventario" ] || [ $# -eq 0 ]; then
  inventario
  [ $# -eq 0 ] && printf '\n\033[1m== Fim.\033[0m Passe o comando de teste para medir a taxa: bash medir-flakiness.sh "bun test" 20\n'
  exit 0
fi

CMD="$1"; N="${2:-20}"
inventario

titulo "Taxa de flakiness" "$N execuções de: $CMD"
falhas=0
for i in $(seq 1 "$N"); do
  if eval "$CMD" >/dev/null 2>&1; then printf '.'; else printf 'F'; falhas=$((falhas+1)); fi
done
echo
taxa=$(awk -v f="$falhas" -v n="$N" 'BEGIN{printf "%.1f", (f/n)*100}')
echo "   execuções: $N | falhas: $falhas | taxa: ${taxa}%"
awk -v t="$taxa" -v n="$N" 'BEGIN{
  if (t == 0)       print "   0% em " n " execuções não prova ausência de flake de 1 em 50 — repita mais, ou use o histórico do CI."
  else if (t < 1)   print "   abaixo de ~1%: a suíte está sã. Retry residual é legítimo aqui (TS-SUI-03)."
  else              print "   ACIMA DE ~1%: a suíte perdeu valor. O vermelho verdadeiro passa junto com os falsos (TS-CORE-04)."
}'

titulo "Separar as hipóteses" "rode e compare — mudança de comportamento aponta a causa"
cat <<'FIM'
   sozinho ................ dependência de outro teste
   com 1 worker ........... estado compartilhado / paralelismo (TS-SUI-09)
   em ordem aleatória ..... dependência de ordem
   20× o mesmo teste ...... confirma que é intermitente
   container da imagem CI . paridade de ambiente
FIM
printf '\n\033[1m== Fim.\033[0m Diagnosticar não é consertar: 1 worker faz sumir o sintoma e mantém o acoplamento.\n'
