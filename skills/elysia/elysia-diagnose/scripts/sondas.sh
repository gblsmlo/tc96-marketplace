#!/usr/bin/env bash
# Sondas de lifecycle Elysia — por que o hook não afeta a rota. Uso: bash sondas.sh [dir]
#
# Sonda aponta o arquivo; a prova é o teste de escopo (references/prova-de-escopo.md).
set -uo pipefail

DIR="${1:-src}"; [ -d "$DIR" ] || DIR=.
RG=(rg --type-add 'rx:*.{ts,tsx}' -trx -n --no-messages)
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nada)"; }

titulo "S1. Hook registrado DEPOIS da rota" "ELYSIA-CORE-01 — a primeira hipótese, sempre"
rg -l --no-messages -g '*.ts' 'new Elysia\(' "$DIR" 2>/dev/null | while read -r f; do
  rota=$(rg -n --no-messages '\.(get|post|put|patch|delete|all)\(' "$f" | head -1 | cut -d: -f1)
  hook=$(rg -n --no-messages '\.(onRequest|onParse|onTransform|onBeforeHandle|onAfterHandle|onError|onResponse|derive|resolve|guard|use)\(' "$f" | tail -1 | cut -d: -f1)
  [ -n "${rota:-}" ] && [ -n "${hook:-}" ] && [ "$hook" -gt "$rota" ] && \
    echo "   $f: primeira rota na linha $rota, último hook/plugin na linha $hook"
done | grep . || vazio

titulo "S2. Escopo não declarado em plugin" "ELYSIA-LIFE-01 — o default é local e não atravessa"
"${RG[@]}" '\.(onBeforeHandle|onRequest|onAfterHandle|onError|derive|resolve)\(\s*[^{]' "$DIR" \
  | rg -v "as:\s*'(scoped|global)'" || vazio
echo "   -- plugins com \`name\` declarado (sem name, o lifecycle roda uma vez só — ELYSIA-LIFE-03):"
"${RG[@]}" 'new Elysia\(\s*\{[^}]*name:' "$DIR" || echo "   NENHUM plugin declara name"

titulo "S3. derive usado para decisão de auth" "ELYSIA-LIFE-02 — derive roda ANTES da validação"
"${RG[@]}" -U 'derive\((?s:.{0,300}?)(auth|token|session|sessao|jwt|permission|role|autoriz)' "$DIR" || vazio

titulo "S4. onRequest lendo body/query/params/cookie" "ELYSIA-LIFE-04 — PreContext não os tem"
"${RG[@]}" -U 'onRequest\((?s:.{0,200}?)\b(body|query|params|cookie)\b' "$DIR" || vazio

titulo "S5. store desestruturado no parâmetro" "ELYSIA-LIFE-06 — o primitivo congela"
"${RG[@]}" 'store:\s*\{' "$DIR" || vazio

titulo "S6. decorate mutado" "ELYSIA-LIFE-05 — decorate é imutável; mutável é state"
"${RG[@]}" 'decorate\(' "$DIR" || vazio

titulo "S7. Hook anônimo em app instrumentada" "ELYSIA-LIFE-11 — span vira 'anonymous'"
"${RG[@]}" '\.(onBeforeHandle|onAfterHandle|onRequest|onError)\(\s*(\(|async\s*\()' "$DIR" || vazio

titulo "S8. cors com origin default" "ELYSIA-LIFE-12 / HTTP-CORS-02 — '*' com credentials é inválido"
"${RG[@]}" 'cors\(' "$DIR" || vazio

titulo "S9. macro sinalizando falha com throw" "ELYSIA-LIFE-10 — throw vira 500 e perde a inferência"
"${RG[@]}" -U 'macro\((?s:.{0,400}?)throw ' "$DIR" || vazio

titulo "S10. Plugin como callback (app) => app" "ELYSIA-LIFE-07 — troque por instância"
"${RG[@]}" '=\s*\(app(:\s*\w+)?\)\s*=>' "$DIR" || vazio

printf '\n\033[1m== Fim.\033[0m Antes de investigar escopo, confira a ORDEM (S1). É a causa mais comum.\n'
printf 'A prova de ELYSIA-LIFE-01 é um teste na instância CONSUMIDORA — ver references/prova-de-escopo.md.\n'
