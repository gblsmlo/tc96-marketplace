#!/usr/bin/env bash
# Form probes — they run BEFORE reading any code. Usage: bash sondas.sh [target]
#
# A probe is not a finding: it points at the file. Confirm by reading, and report with
# an `RHF-*` ID (canonical — see references/mapa-de-ids.md) + file:line + a concrete fix.
set -uo pipefail

ALVO="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "0. Environment" "the version decides what is citable"
rg -n '"react-hook-form"|"@hookform/resolvers"|"zod"' package.json 2>/dev/null || vazio
echo "   -- forms in the target:"
"${RG[@]}" -l 'useForm\(' "$ALVO" 2>/dev/null || vazio

titulo "1. watch() at the root" "RHF-PERF-01 — the whole form re-renders on every keystroke"
"${RG[@]}" -n 'watch\(\s*\)' "$ALVO" || vazio

titulo "2. watch(callback)" "RHF-PERF-02 — deprecated; use subscribe"
"${RG[@]}" -n 'watch\(\s*\(' "$ALVO" || vazio

titulo "3. useForm without defaultValues" "RHF-CORE-01 — a missing field compares against undefined"
"${RG[@]}" -nU 'useForm[<(](?s:.{0,300}?)\)' "$ALVO" 2>/dev/null \
  | rg -v 'defaultValues' | head -20 | ou_vazio

titulo "4. formState from useFormContext" "RHF-STATE-01 — freezes after the first render"
"${RG[@]}" -n 'formState[^=]*\}\s*=\s*useFormContext' "$ALVO" || vazio

titulo "5. Two owners of the submission" "RHF-BRIDGE-01 — <form action> together with onSubmit"
"${RG[@]}" -lU '<form(?s:.{0,200}?)action=' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'onSubmit=' "$f" && echo "   $f"; done | grep . || vazio

titulo "6. reset inside onSubmit" "RHF-STATE-02 — belongs in an Effect with isSubmitSuccessful"
"${RG[@]}" -nU 'handleSubmit\((?s:.{0,400}?)\breset\(' "$ALVO" || vazio

titulo "7. useFieldArray key" "RHF-ARRAY-01 — key={field.id}, never the index"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$ALVO" || vazio

titulo "8. Double registration" "RHF-CORE-04 — files with both Controller AND register"
"${RG[@]}" -l '<Controller|useController\(' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q '\bregister\(' "$f" && echo "   $f"; done | grep . || vazio

titulo "9. useState mirroring a field" "REACT-PAT-01 — step 1 of the re-render investigation"
"${RG[@]}" -l 'useForm\(' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'useState' "$f" && echo "   $f"; done | grep . || vazio

titulo "10. Optimism in the form" "RHF-BRIDGE-04 — it belongs to the mutation, not the form"
"${RG[@]}" -l 'useForm\(' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'useOptimistic|onMutate' "$f" && echo "   $f"; done | grep . || vazio

titulo "11. Two waiting states" "isSubmitting || isPending — nobody decided the owner"
"${RG[@]}" -n 'isSubmitting\s*\|\||\|\|\s*isPending' "$ALVO" || vazio

titulo "12. Error accessibility" "RHF-A11Y-01 — aria-invalid, aria-describedby, role=alert"
"${RG[@]}" -l 'errors\.' "$ALVO" 2>/dev/null \
  | while read -r f; do rg -q 'aria-invalid' "$f" || echo "   no aria-invalid: $f"; done | grep . || vazio

printf '\n\033[1m== Done.\033[0m Probes 3 and 9 have a high false-positive rate: read before reporting.\n'
