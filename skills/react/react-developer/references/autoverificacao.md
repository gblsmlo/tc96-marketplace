# Autoverificação antes de entregar

> Três passadas, nesta ordem. Nenhuma delas é opcional, e a entrega não sai com
> ressalva: se um item falha, corrija antes.

---

## Passada 1 — checklist normativa

Ordenada por frequência de falha. É a mesma da § 5 de [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) —
abra-a quando precisar do texto da regra.

- [ ] Hook depois de early return, dentro de `if`, loop ou callback? → `REACT-HOOK-01`
- [ ] `fetch`, `localStorage`, `Date.now`, `Math.random` ou log no corpo do render? → `REACT-PURE-01` / `REACT-PURE-02`
- [ ] Mutação de props ou estado (`push`, `sort`, `splice`, atribuição direta)? → `REACT-PURE-03`
- [ ] Valor mutado **depois** de já ter ido para o JSX? → `REACT-PURE-05`
- [ ] `setState(x + 1)` onde deveria ser a forma updater? → `REACT-STATE-01`
- [ ] Componente chamado como função (`Componente(props)`)? → `REACT-CALL-01`
- [ ] Hook passado como valor, ou chamado de função comum? → `REACT-CALL-02` / `REACT-HOOK-02`
- [ ] `ref.current` lido ou escrito no render? → `REACT-REF-01`
- [ ] Algum `eslint-disable` em `exhaustive-deps`? → `REACT-EFFECT-03` — quase sempre é Effect que não deveria existir

## Passada 2 — a tabela de hábitos

Percorra `habitos-de-ia.md` linha a linha e pergunte: **o código evitou este hábito?**
As seções 1 e 2 (estado e efeitos) pegam a maioria; as 6 e 7 só se aplicam quando o
código toca servidor ou extrai Hook.

## Passada 3 — as três perguntas de fechamento

1. Todo `useState` que sobrou responde "sim" à árvore de estado de [React.js](../../../../knowledge-base/docs/react-js.md) § 5,
 ou algum é **derivável**, **remoto** ou **de URL**?
2. Todo `useEffect` que sobrou sincroniza com um sistema externo **concreto e nomeável**?
 Escreva o nome. Se não sai nome, o Effect não deveria existir.
3. Toda memoização que sobrou tem **medição** por trás — ou React Compiler ativo tornando-a
 redundante?

---

## Sondas executáveis

Rodam contra o que você acabou de escrever. Não substituem as passadas acima — apontam
onde olhar. `$ALVO` é o arquivo ou diretório tocado.

```bash
# 1. Fetch dentro de Effect (REACT-EFFECT-06)
rg -nU --type-add 'rx:*.{ts,tsx}' -trx 'useEffect\((?s:.{0,400}?)\b(fetch|axios)\s*[\(\.]' "$ALVO"

# 2. Estado derivado por Effect: set* como primeira coisa do Effect (REACT-PAT-01)
rg -nU --type-add 'rx:*.{ts,tsx}' -trx 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$ALVO"

# 3. Effect com callback async (REACT-EFFECT-12)
rg -n --type-add 'rx:*.{ts,tsx}' -trx 'useEffect\(\s*async' "$ALVO"

# 4. exhaustive-deps silenciado (REACT-EFFECT-03)
rg -n 'eslint-disable.*exhaustive-deps' "$ALVO"

# 5. setState sem updater onde o anterior importa (REACT-STATE-01)
rg -n --type-add 'rx:*.{ts,tsx}' -trx 'set[A-Z]\w*\(\s*\w+\s*[-+]\s*1\s*\)' "$ALVO"

# 6. index como key (antipadrão de Patterns § 8)
rg -n --type-add 'rx:*.{ts,tsx}' -trx 'key=\{\s*(i|idx|index)\s*\}' "$ALVO"

# 7. forwardRef em código novo (REACT-REF-03)
rg -n --type-add 'rx:*.{ts,tsx}' -trx '\bforwardRef\b' "$ALVO"

# 8. Memoização — conte antes de justificar (REACT-PERF-01)
rg -c --type-add 'rx:*.{ts,tsx}' -trx '\buseMemo\(|\buseCallback\(|\bmemo\(' "$ALVO"

# 9. 'use client' e a que altura está (REACT-RSC-03)
rg -l --sort path --type-add 'rx:*.{ts,tsx}' -trx "^['\"]use client['\"]" "$ALVO"

# 10. Suspense sem Error Boundary no mesmo arquivo (REACT-ASYNC-08)
rg -l --type-add 'rx:*.{ts,tsx}' -trx '<Suspense' "$ALVO" | xargs -I{} sh -c 'rg -q "ErrorBoundary|errorElement" "{}" || echo "sem boundary: {}"'
```

Sonda 8 não tem limiar fixo: **qualquer** ocorrência precisa de resposta à pergunta 3
da Passada 3. Sonda 9 é leitura, não veredito — o que importa é se existe algo acima
da fronteira que poderia ter ficado no servidor.

---

## Antes da primeira linha, não depois

Duas verificações de ambiente que mudam o código que você vai escrever:

```bash
# React Compiler ativo? Muda toda a decisão de memoização (REACT-PERF-02)
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' package.json vite.config.* babel.config.* 2>/dev/null

# rede de lint? ESLint com o plugin, OU Biome com o domínio react ligado
rg -n 'react-hooks' package.json eslint.config.*.eslintrc* 2>/dev/null
rg -n 'domains|useHookAtTopLevel|useExhaustiveDependencies' biome.json* 2>/dev/null
```

Projeto sem rede de lint não é motivo para pular a Passada 1 — é motivo para **mencionar a
ausência** na entrega.

**Em projeto Biome, confira o domínio.** As regras de Hooks (`useHookAtTopLevel`,
`useExhaustiveDependencies`) são recommended **do domínio `react`**: com `preset`/`recommended`
ligado e o domínio desligado, elas **não rodam** — sem erro e sem aviso. A correção é
`"linter": { "domains": { "react": "recommended" } }`.

---

## Relacionados

- [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) § 5 — a checklist normativa, com o texto das regras
- `habitos-de-ia.md` — a segunda passada
- `mapa-de-ids.md` — onde cada ID está declarado
