#!/usr/bin/env bash
# Sondas de formulário — rodam ANTES de ler código. Uso: bash sondas.sh [alvo]
#
# Sonda não é achado: aponta o arquivo. Confirme lendo, e reporte com ID `RHF-*`
# (canônico — ver references/mapa-de-ids.md) + arquivo:linha + correção concreta.
set -uo pipefail

ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }
ou_vazio() {  # imprime a entrada; se vier vazia, a mensagem
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nada)}"; fi
}

titulo "0. Ambiente" "versão decide o que é citável"
rg -n '"react-hook-form"|"@hookform/resolvers"|"zod"' package.json 2>/dev/null || vazio
echo "   -- formulários no alvo:"
"${RG[@]}" -l 'useForm\(' "$ALVO" 2>/dev/null || vazio

titulo "1. watch() na raiz" "RHF-PERF-01 — re-render do form inteiro a cada tecla"
"${RG[@]}" -n 'watch\(\s*\)' "$ALVO" || vazio

titulo "2. watch(callback)" "RHF-PERF-02 — deprecado; use subscribe"
"${RG[@]}" -n 'watch\(\s*\(' "$ALVO" || vazio

titulo "3. useForm sem defaultValues" "RHF-CORE-01 — campo ausente compara contra undefined"
"${RG[@]}" -nU 'useForm[<(](?s:.{0,300}?)\)' "$ALVO" 2>/dev/null \
  | rg -v 'defaultValues' | head -20 | ou_vazio

titulo "4. formState de useFormContext" "RHF-STATE-01 — congela após o primeiro render"
"${RG[@]}" -n 'formState[^=]*\}\s*=\s*useFormContext' "$ALVO" || vazio

titulo "5. Dois donos da submissão" "RHF-BRIDGE-01 — <form action> junto com onSubmit"
"${RG[@]}" -lU '<form(?s:.{0,200}?)action=' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'onSubmit=' "$f" && echo "   $f"; done | grep . || vazio

titulo "6. reset dentro do onSubmit" "RHF-STATE-02 — vai em Effect com isSubmitSuccessful"
"${RG[@]}" -nU 'handleSubmit\((?s:.{0,400}?)\breset\(' "$ALVO" || vazio

titulo "7. key de useFieldArray" "RHF-ARRAY-01 — key={field.id}, nunca o índice"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$ALVO" || vazio

titulo "8. Registro duplo" "RHF-CORE-04 — arquivos com Controller E register"
"${RG[@]}" -l '<Controller|useController\(' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q '\bregister\(' "$f" && echo "   $f"; done | grep . || vazio

titulo "9. useState espelhando campo" "REACT-PAT-01 — passo 1 da investigação de re-render"
"${RG[@]}" -l 'useForm\(' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'useState' "$f" && echo "   $f"; done | grep . || vazio

titulo "10. Otimismo no formulário" "RHF-BRIDGE-04 — pertence à mutation, não ao form"
"${RG[@]}" -l 'useForm\(' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'useOptimistic|onMutate' "$f" && echo "   $f"; done | grep . || vazio

titulo "11. Dois estados de espera" "isSubmitting || isPending — ninguém decidiu o dono"
"${RG[@]}" -n 'isSubmitting\s*\|\||\|\|\s*isPending' "$ALVO" || vazio

titulo "12. Acessibilidade do erro" "RHF-A11Y-01 — aria-invalid, aria-describedby, role=alert"
"${RG[@]}" -l 'errors\.' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'aria-invalid' "$f" || echo "   sem aria-invalid: $f"; done | grep . || vazio

printf '\n\033[1m== Fim.\033[0m Sonda 3 e 9 têm falso positivo alto: confirme lendo antes de reportar.\n'
