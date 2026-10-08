#!/usr/bin/env bash
# Form probes — they run BEFORE reading any code. Usage: bash probes.sh [target]
#
# A probe is not a finding: it points at the file. Confirm by reading, and report with
# an `RHF-*` ID (canonical — see references/id-map.md) + file:line + a concrete fix.
set -uo pipefail

TARGET="${1:-src}"
RG=(rg --type-add 'rx:*.{ts,tsx,js,jsx}' -trx)
heading() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
none_found() { echo "   (nothing)"; }
or_empty() {  # prints the input; when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s
' "$out"; else echo "   ${1:-(nothing)}"; fi
}

heading "0. Environment" "the version decides what is citable"
rg -n '"react-hook-form"|"@hookform/resolvers"|"zod"' package.json 2>/dev/null || none_found
echo "   -- forms in the target:"
"${RG[@]}" -l 'useForm\(' "$TARGET" 2>/dev/null || none_found

heading "1. watch() at the root" "RHF-PERF-01 — the whole form re-renders on every keystroke"
"${RG[@]}" -n 'watch\(\s*\)' "$TARGET" || none_found

heading "2. watch(callback)" "RHF-PERF-02 — deprecated; use subscribe"
"${RG[@]}" -n 'watch\(\s*\(' "$TARGET" || none_found

heading "3. useForm without defaultValues" "RHF-CORE-01 — a missing field compares against undefined"
"${RG[@]}" -nU 'useForm[<(](?s:.{0,300}?)\)' "$TARGET" 2>/dev/null \
  | rg -v 'defaultValues' | head -20 | or_empty

heading "4. formState from useFormContext" "RHF-STATE-01 — freezes after the first render"
"${RG[@]}" -n 'formState[^=]*\}\s*=\s*useFormContext' "$TARGET" || none_found

heading "5. Two owners of the submission" "RHF-BRIDGE-01 — <form action> together with onSubmit"
"${RG[@]}" -lU '<form(?s:.{0,200}?)action=' "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q 'onSubmit=' "$f" && echo "   $f"; done | grep . || none_found

heading "6. reset inside onSubmit" "RHF-STATE-02 — belongs in an Effect with isSubmitSuccessful"
"${RG[@]}" -nU 'handleSubmit\((?s:.{0,400}?)\breset\(' "$TARGET" || none_found

heading "7. useFieldArray key" "RHF-ARRAY-01 — key={field.id}, never the index"
"${RG[@]}" -n 'key=\{\s*(i|idx|index)\s*\}' "$TARGET" || none_found

heading "8. Double registration" "RHF-CORE-04 — files with both Controller AND register"
"${RG[@]}" -l '<Controller|useController\(' "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q '\bregister\(' "$f" && echo "   $f"; done | grep . || none_found

heading "9. useState mirroring a field" "REACT-PAT-01 — step 1 of the re-render investigation"
"${RG[@]}" -l 'useForm\(' "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q 'useState' "$f" && echo "   $f"; done | grep . || none_found

heading "10. Optimism in the form" "RHF-BRIDGE-04 — it belongs to the mutation, not the form"
"${RG[@]}" -l 'useForm\(' "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q 'useOptimistic|onMutate' "$f" && echo "   $f"; done | grep . || none_found

heading "11. Two waiting states" "isSubmitting || isPending — nobody decided the owner"
"${RG[@]}" -n 'isSubmitting\s*\|\||\|\|\s*isPending' "$TARGET" || none_found

heading "12. Error accessibility" "RHF-A11Y-01 — aria-invalid, aria-describedby, role=alert"
"${RG[@]}" -l 'errors\.' "$TARGET" 2>/dev/null \
  | while read -r f; do rg -q 'aria-invalid' "$f" || echo "   no aria-invalid: $f"; done | grep . || none_found

printf '\n\033[1m== Done.\033[0m Probes 3 and 9 have a high false-positive rate: read before reporting.\n'
