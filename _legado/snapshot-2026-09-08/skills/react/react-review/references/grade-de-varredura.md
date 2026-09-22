# Grade de varredura — na ordem que falha mais

> A ordem não é arbitrária. Ela vai do que **quebra o contrato do React** ao que é
> preferência, e cada nível tem precedência normativa sobre o seguinte
> ([[React.js]] § 7, invariante 3).
>
> Se um nível produz achado que invalida o código do nível seguinte — o Effect inteiro
> não deveria existir — **pare de revisar o interior dele** e reporte a remoção, não a
> correção de detalhe.

---

## Nível 1 — contrato do React (bloqueante)

Checklist da § 5 de [[React - Rules of React]], ordenada por frequência de falha.

| Antipadrão | ID canônico | Satélite |
| --- | --- | --- |
| Hook depois de early return, dentro de `if`, loop ou callback | `REACT-HOOK-01` | [[React - Rules of React]] |
| Hook chamado de função que não é componente nem Hook | `REACT-HOOK-02` | [[React - Rules of React]] |
| Hook customizado que viola as regras internamente | `REACT-HOOK-07` | [[React - Hooks]] |
| `fetch`, `localStorage`, `Date.now()`, `Math.random()` ou log no corpo do render | `REACT-PURE-01` / `REACT-PURE-02` | [[React - Rules of React]] |
| `.push`, `.sort`, `.splice` ou atribuição direta em props/estado | `REACT-PURE-03` | [[React - Rules of React]] |
| Valor mutado depois de já ter ido para o JSX | `REACT-PURE-05` | [[React - Rules of React]] |
| `Componente(props)` em vez de `<Componente />` | `REACT-CALL-01` | [[React - Rules of React]] |
| Hook guardado em variável, objeto, ou passado como argumento | `REACT-CALL-02` | [[React - Rules of React]] |
| `ref.current` lido ou escrito no render | `REACT-REF-01` | [[React - Refs e DOM]] |

## Nível 2 — regras críticas (alta)

De [[React.js]] § 6.1: bug latente, não estilo. Race condition, tela branca, endpoint sem autorização.

| Antipadrão | ID canônico | Satélite |
| --- | --- | --- |
| `fetch` em `useEffect` em código novo | `REACT-EFFECT-06` | [[React - Efeitos e Sincronização]] |
| Estado espelhando props/estado via `useEffect` | `REACT-PAT-01` | [[React - Patterns]] |
| Dado remoto guardado em `useState` como fonte de verdade | `REACT-PAT-03` | [[React - Patterns]] |
| Lógica de interação dentro de Effect em vez do handler | `REACT-EFFECT-05` | [[React - Efeitos e Sincronização]] |
| `<Suspense>` esperando fetch feito em `useEffect` | `REACT-ASYNC-03` | [[React - Suspense e Assincronia]] |
| Boundary de Suspense em fronteira de dados sem Error Boundary | `REACT-ASYNC-08` | [[React - Suspense e Assincronia]] |
| Erro esperado lançado para boundary em vez de virar estado | `REACT-ASYNC-09` | [[React - Suspense e Assincronia]] |
| Memoização sem medição | `REACT-PERF-01` | [[React - Performance e Concorrência]] |
| `'use client'` no topo da árvore | `REACT-RSC-03` | [[React - Server Components e Diretivas]] |
| Server Function sem autenticar, validar e autorizar | `REACT-RSC-06` | [[React - Server Components e Diretivas]] |
| HTML de servidor montado com `createRoot` | `REACT-DOM-01` | [[React - Renderização e Entrypoints]] |

## Nível 3 — estrutura (média)

Antipadrões de [[React - Patterns]] § 8 e das famílias dos satélites. Corrigíveis no mesmo PR.

| Antipadrão | ID canônico | Satélite |
| --- | --- | --- |
| Estado elevado acima do ancestral comum mais próximo | `REACT-PAT-02` | [[React - Patterns]] |
| Prop booleana nova por variação de conteúdo | `REACT-PAT-04` | [[React - Patterns]] |
| Componente extraído sem justificativa conceitual | `REACT-PAT-05` | [[React - Patterns]] |
| Error Boundary só na raiz | `REACT-PAT-06` | [[React - Patterns]] |
| Boundary sem caminho de recuperação | `REACT-ASYNC-11` | [[React - Suspense e Assincronia]] |
| Filtro/aba/paginação em `useState` em vez da URL | `REACT-PAT-10` | [[React - Patterns]] |
| `setState(x + 1)` onde o valor anterior importa | `REACT-STATE-01` | [[React - Estado e Reatividade]] |
| Booleanos paralelos onde cabe union discriminada | `REACT-STATE-06` | [[React - Estado e Reatividade]] |
| Context para estado de escrita frequente | `REACT-STATE-08` | [[React - Estado e Reatividade]] |
| Effect sem cleanup em subscription/timer/listener | `REACT-EFFECT-01` | [[React - Efeitos e Sincronização]] |
| `eslint-disable` em `exhaustive-deps` | `REACT-EFFECT-03` | [[React - Efeitos e Sincronização]] |
| `useEffect(async …)` | `REACT-EFFECT-12` | [[React - Efeitos e Sincronização]] |
| `memo` sem estabilização das props | `REACT-PERF-03` | [[React - Performance e Concorrência]] |
| `useMemo` usado para identidade obrigatória | `REACT-PERF-05` | [[React - Performance e Concorrência]] |
| Lista de milhares de itens tratada com memoização | `REACT-PERF-09` | [[React - Performance e Concorrência]] |
| Transição controlando campo de texto | `REACT-PERF-10` | [[React - Performance e Concorrência]] |
| `forwardRef` em código atual | `REACT-REF-03` | [[React - Refs e DOM]] |
| Portal sem foco, `Esc` e `aria-modal` | `REACT-REF-07` | [[React - Refs e DOM]] |
| `e.preventDefault()` com `<form action>` | `REACT-FORM-01` | [[React - Formulários e Actions]] |
| Campo sem `name` lido por `FormData` | `REACT-FORM-02` | [[React - Formulários e Actions]] |
| `useFormStatus` no componente que renderiza o `<form>` | `REACT-FORM-05` | [[React - Formulários e Actions]] |
| `useOptimistic` sobre dado que vive no cache da Query | `REACT-FORM-07` | [[React - Formulários e Actions]] |
| Client Component importando Server Component | `REACT-RSC-04` | [[React - Server Components e Diretivas]] |
| Prop não serializável cruzando a fronteira | `REACT-RSC-05` | [[React - Server Components e Diretivas]] |
| `cache` usado como cache entre requests | `REACT-RSC-08` | [[React - Server Components e Diretivas]] |
| Render ramificando em `typeof window` | `REACT-DOM-03` | [[React - Renderização e Entrypoints]] |
| `<StrictMode>` removido para "consertar" execução dupla | `REACT-DOM-06` | [[React - Renderização e Entrypoints]] |
| ID de acessibilidade sem `useId` | `REACT-UTIL-01` | [[React - Hooks Utilitários]] |
| `subscribe` com identidade instável em `useSyncExternalStore` | `REACT-UTIL-04` | [[React - Hooks Utilitários]] |
| `index` como `key` em lista reordenável | sem ID — [[React - Patterns]] § 8 | [[React - Patterns]] |

## Nível 4 — satélite do domínio

Só agora, e só para o domínio que o código realmente toca, descoberto por [[React.js]] § 4.
Abrir satélite antes disso é gasto de contexto sem retorno.

## Nível 5 — estilo e legibilidade

Por último e subordinado aos anteriores. **Nunca** proponha refatoração cosmética em cima
de código que viola o Nível 1: reporte a violação primeiro.

---

## Duas passagens de bastão

| Se a varredura revelar… | A revisão não continua aqui |
| --- | --- |
| o problema é **onde o arquivo mora** ou quem importa quem | [[react-structure]], família `REACT-ARCH-*` |
| o componente está **confirmadamente lento** e precisa de fix medido | `react-component-performance` (instalada em `~/.claude/skills/`) |

---

## Relacionados

- `sondas.md` — o que rodar antes desta grade
- `severidade-e-relatorio.md` — como classificar e reportar
- `mapa-de-ids.md` — onde cada ID está declarado
