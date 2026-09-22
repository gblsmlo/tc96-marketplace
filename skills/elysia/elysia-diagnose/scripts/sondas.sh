#!/usr/bin/env bash
# Elysia lifecycle probes — why the hook does not affect the route. Usage: bash sondas.sh [dir]
#
# A probe points at the file; the proof is the scope test (references/prova-de-escopo.md).
set -uo pipefail

DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -n --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }

titulo "S1. Hook registered AFTER the route" "ELYSIA-CORE-01 — always the first hypothesis"
rg -l --no-messages -g '*.ts' 'new Elysia\(' "$DIR" 2>/dev/null | while read -r f; do
  rota=$(rg -n --no-messages '\.(get|post|put|patch|delete|all)\(' "$f" | head -1 | cut -d: -f1)
  hook=$(rg -n --no-messages '\.(onRequest|onParse|onTransform|onBeforeHandle|onAfterHandle|onError|onResponse|derive|resolve|guard|use)\(' "$f" | tail -1 | cut -d: -f1)
  [ -n "${rota:-}" ] && [ -n "${hook:-}" ] && [ "$hook" -gt "$rota" ] && \
    echo "   $f: first route on line $rota, last hook/plugin on line $hook"
done | grep . || vazio

titulo "S2. Scope not declared in a plugin" "ELYSIA-LIFE-01 — the default is local and does not cross"
"${RG[@]}" '\.(onBeforeHandle|onRequest|onAfterHandle|onError|derive|resolve)\(\s*[^{]' "$DIR" \
  | rg -v "as:\s*'(scoped|global)'" || vazio
echo "   -- plugins with a declared \`name\` (without it, the lifecycle runs only once — ELYSIA-LIFE-03):"
"${RG[@]}" 'new Elysia\(\s*\{[^}]*name:' "$DIR" || echo "   NO plugin declares a name"

titulo "S3. derive used for an auth decision" "ELYSIA-LIFE-02 — derive runs BEFORE validation"
"${RG[@]}" -U 'derive\((?s:.{0,300}?)(auth|token|session|sessao|jwt|permission|role|autoriz)' "$DIR" || vazio

titulo "S4. onRequest reading body/query/params/cookie" "ELYSIA-LIFE-04 — PreContext does not have them"
"${RG[@]}" -U 'onRequest\((?s:.{0,200}?)\b(body|query|params|cookie)\b' "$DIR" || vazio

titulo "S5. store destructured in the parameter" "ELYSIA-LIFE-06 — the primitive freezes"
"${RG[@]}" 'store:\s*\{' "$DIR" || vazio

titulo "S6. decorate mutated" "ELYSIA-LIFE-05 — decorate is immutable; the mutable one is state"
"${RG[@]}" 'decorate\(' "$DIR" || vazio

titulo "S7. Anonymous hook in an instrumented app" "ELYSIA-LIFE-11 — the span becomes 'anonymous'"
"${RG[@]}" '\.(onBeforeHandle|onAfterHandle|onRequest|onError)\(\s*(\(|async\s*\()' "$DIR" || vazio

titulo "S8. cors with the default origin" "ELYSIA-LIFE-12 / HTTP-CORS-02 — '*' with credentials is invalid"
"${RG[@]}" 'cors\(' "$DIR" || vazio

titulo "S9. macro signalling failure with throw" "ELYSIA-LIFE-10 — throw becomes a 500 and loses the inference"
"${RG[@]}" -U 'macro\((?s:.{0,400}?)throw ' "$DIR" || vazio

titulo "S10. Plugin as an (app) => app callback" "ELYSIA-LIFE-07 — swap it for an instance"
"${RG[@]}" '=\s*\(app(:\s*\w+)?\)\s*=>' "$DIR" || vazio

printf '\n\033[1m== Done.\033[0m Before investigating scope, check the ORDER (S1). It is the most common cause.\n'
printf 'The proof of ELYSIA-LIFE-01 is a test on the CONSUMING instance — see references/prova-de-escopo.md.\n'
