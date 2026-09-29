---
titulo: React - Hooks
Link: https://react.dev/reference/react/hooks
tags:
  - react
  - hooks
  - reference
  - agent-context
source: "Documentação oficial do React — react.dev/reference/react/hooks"
verificado-em: 2026-08-14
---

# React — Hooks

> Estrutura de **consulta de API**: assinatura, parâmetros, retorno e caveats de cada Hook. Para decidir *qual* Hook usar, vá às árvores de decisão em [React.js](react-js.md) § 5. Para decidir *como estruturar* o componente ao redor, vá a [React - Patterns](react-patterns.md).

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. As três regras que valem para todos

Antes de qualquer assinatura. Violá-las quebra a correspondência entre chamadas e estado interno, e o resultado é estado trocado entre Hooks — não um erro claro.

| ID | Regra |
| --- | --- |
| `REACT-HOOK-01` | Chamar **apenas no topo**. Nunca em loop, condicional, função aninhada ou depois de um early return. |
| `REACT-HOOK-02` | Chamar **apenas** de componentes React ou de outros Hooks. Nunca de função comum. |
| `REACT-HOOK-03` | `use` é a única exceção: pode ser chamado condicionalmente — e é uma API, não um Hook. |

O motivo de `REACT-HOOK-01`: o React identifica cada Hook pela **ordem da chamada** dentro do render, não pelo nome. Uma chamada condicional desloca a ordem e o estado do Hook seguinte passa a ser lido do slot errado.

```tsx
// ERRADO — REACT-HOOK-01
function Profile({ userId }: { userId?: string }) {
  if (!userId) return null          // early return antes dos Hooks
  const [name, setName] = useState('')
  // ...
}

// CERTO — Hooks no topo, condicional depois
function Profile({ userId }: { userId?: string }) {
  const [name, setName] = useState('')
  if (!userId) return null
  // ...
}
```

---

## 2. Índice completo

Assinaturas conforme o reference oficial. A coluna **Detalhe** aponta o satélite com exemplos, boas práticas e antipadrões.

### Estado

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useState` | `const [state, setState] = useState(initialState)` | [React - Estado e Reatividade](react-estado-e-reatividade.md) |
| `useReducer` | `const [state, dispatch] = useReducer(reducer, initialArg, init?)` | [React - Estado e Reatividade](react-estado-e-reatividade.md) |

### Contexto

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useContext` | `const value = useContext(SomeContext)` | [React - Estado e Reatividade](react-estado-e-reatividade.md) |

### Refs

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useRef` | `const ref = useRef(initialValue)` | [React - Refs e DOM](react-refs-e-dom.md) |
| `useImperativeHandle` | `useImperativeHandle(ref, createHandle, dependencies?)` | [React - Refs e DOM](react-refs-e-dom.md) |

### Efeitos

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useEffect` | `useEffect(setup, dependencies?)` | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useLayoutEffect` | `useLayoutEffect(setup, dependencies?)` | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useInsertionEffect` | `useInsertionEffect(setup, dependencies?)` | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useEffectEvent` | `const onEvent = useEffectEvent(callback)` | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |

### Performance e concorrência

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useMemo` | `const cached = useMemo(calculateValue, dependencies)` | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useCallback` | `const cachedFn = useCallback(fn, dependencies)` | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useTransition` | `const [isPending, startTransition] = useTransition()` | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useDeferredValue` | `const deferred = useDeferredValue(value, initialValue?)` | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |

### Formulários e Actions

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useActionState` | `const [state, formAction, isPending] = useActionState(action, initialState, permalink?)` | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `useOptimistic` | `const [optimistic, setOptimistic] = useOptimistic(value, reducer?)` | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `useFormStatus` | `const { pending, data, method, action } = useFormStatus()` — de `react-dom` | [React - Formulários e Actions](react-formularios-e-actions.md) |

### Utilitários

| Hook | Assinatura | Detalhe |
| --- | --- | --- |
| `useId` | `const id = useId()` | [React - Hooks Utilitários](react-hooks-utilitarios.md) |
| `useSyncExternalStore` | `const snap = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)` | [React - Hooks Utilitários](react-hooks-utilitarios.md) |
| `useDebugValue` | `useDebugValue(value, format?)` | [React - Hooks Utilitários](react-hooks-utilitarios.md) |

> `useFormStatus` é o único Hook exportado por `react-dom`, não por `react`. Todos os demais vêm de `react`.

---

## 3. Escolha rápida

Quando a dúvida é entre dois Hooks próximos. As árvores completas estão em [React.js](react-js.md) § 5.

| Dúvida | Critério de desempate |
| --- | --- |
| `useState` × `useReducer` | Transições independentes → `useState`. Várias transições relacionadas, ou estados mutuamente exclusivos → `useReducer`. |
| `useState` × `useRef` | Mudar deve redesenhar? → `useState`. Não deve? → `useRef`. |
| `useMemo` × `useCallback` | Cachear o **resultado** → `useMemo`. Cachear a **função** → `useCallback`. `useCallback(fn, d)` ≡ `useMemo(() => fn, d)`. |
| `useTransition` × `useDeferredValue` | Controlo o `setState` → `useTransition`. Só recebo o valor pronto → `useDeferredValue`. |
| `useTransition` × `startTransition` | Preciso da flag `isPending` → `useTransition`. Estou fora de um componente → `startTransition`. |
| `useEffect` × `useLayoutEffect` | Preciso medir layout antes do paint → `useLayoutEffect` (bloqueia o paint, use com parcimônia). Caso geral → `useEffect`. |
| `useEffect` × event handler | O código responde a uma interação específica? → handler, não Effect. |
| `useContext` × store externa | Leitura frequente com escrita rara → Context. Escrita frequente → store externa + `useSyncExternalStore` ou. |
| `useOptimistic` × mutation otimista | O dado vive num cache de query? → mutation otimista, com snapshot e rollback. Não vive? → `useOptimistic`, que funciona sem framework. Nunca os dois no mesmo dado. |

---

## 4. Hooks customizados

Um Hook customizado é uma função cujo nome começa com `use` e que chama outros Hooks. Ele **compartilha lógica com estado, não o estado em si**: dois componentes que usam o mesmo Hook customizado têm instâncias de estado independentes.

```tsx
function useOnlineStatus() {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('online', callback)
      window.addEventListener('offline', callback)
      return () => {
        window.removeEventListener('online', callback)
        window.removeEventListener('offline', callback)
      }
    },
    () => navigator.onLine,
    () => true, // snapshot do servidor
  )
}
```

**Quando extrair.** O critério do vault está em: o Hook se justifica quando existe uma fronteira de sincronização real ou uma repetição real. Extrair cedo demais apenas desloca complexidade.

**Regras de qualidade:**

| ID | Regra |
| --- | --- |
| `REACT-HOOK-04` | O nome **MUST** começar com `use` e expressar a **intenção da feature**, não a implementação — `useOnlineStatus`, não `useEventListener`. |
| `REACT-HOOK-05` | Lógica pura, sem estado, **NEVER** vira Hook — é função comum, testável sem renderizar. |
| `REACT-HOOK-06` | O retorno **MUST** ser pequeno e explícito. Um Hook que devolve dez coisas está escondendo um componente. |
| `REACT-HOOK-07` | Um Hook customizado **MUST** obedecer `REACT-HOOK-01` internamente — ele herda todas as restrições dos Hooks que chama. |

---

## 5. Antipadrões

### Ajustar dependências para calar o linter

```tsx
// ERRADO — a lista mente sobre o que o Effect lê
useEffect(() => {
  setFiltered(items.filter((i) => i.status === status))
}, [items]) // eslint desabilitado, `status` omitido

// CERTO — não é um Effect. É estado derivado.
const filtered = items.filter((i) => i.status === status)
```

A array de dependências **descreve** o que o Effect lê; ela não é um controle de quando rodar. Se remover uma dependência "conserta" um loop, o Effect é o problema..

### Estado espelhando props

```tsx
// ERRADO — dessincroniza na primeira mudança de prop
function Total({ items }: { items: Item[] }) {
  const [total, setTotal] = useState(0)
  useEffect(() => setTotal(items.length), [items])
  return <span>{total}</span>
}

// CERTO
function Total({ items }: { items: Item[] }) {
  return <span>{items.length}</span>
}
```

### `useCallback` / `useMemo` por reflexo

Envolver tudo em `useCallback` não é otimização: adiciona custo de comparação de dependências e ruído, e só tem efeito se o consumidor for `memo` ou se o valor for dependência de outro Hook. Exige medição. Ver `REACT-PERF-*` em [React - Performance e Concorrência](react-performance-e-concorrencia.md) — e verifique antes se o React Compiler já cobre o caso.

### Hook chamado condicionalmente atrás de abstração

```tsx
// ERRADO — viola REACT-HOOK-01 mesmo indiretamente
const value = condition ? useA() : useB()

// CERTO — chame ambos, escolha depois
const a = useA()
const b = useB()
const value = condition ? a : b
```

---

## Relacionados

- [React.js](react-js.md) — hub e árvores de decisão
- [React - Patterns](react-patterns.md) — padrões de composição e arquitetura
- [React - Rules of React](react-rules-of-react.md) — base normativa completa
- · ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [Built-in React Hooks](https://react.dev/reference/react/hooks)
- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
- [react-dom Hooks](https://react.dev/reference/react-dom/hooks)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)
