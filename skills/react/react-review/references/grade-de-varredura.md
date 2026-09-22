# Scan grid — in the order that fails most

> The order is not arbitrary. It goes from what **breaks React's contract** to what is
> preference, and each level has normative precedence over the next
> ([React.js](../../../../knowledge-base/docs/react-js.md) § 7, invariant 3).
>
> If one level produces a finding that invalidates the next level's code — the whole Effect
> should not exist — **stop reviewing its interior** and report the removal, not the
> detail fix.

---

## Level 1 — React's contract (blocking)

The § 5 checklist of [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md), ordered by failure frequency.

| Antipattern | Canonical ID | Satellite |
| --- | --- | --- |
| A Hook after an early return, inside an `if`, loop or callback | `REACT-HOOK-01` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| A Hook called from a function that is neither a component nor a Hook | `REACT-HOOK-02` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| A custom Hook that violates the rules internally | `REACT-HOOK-07` | [React - Hooks](../../../../knowledge-base/docs/react-hooks.md) |
| `fetch`, `localStorage`, `Date.now`, `Math.random` or a log in the render body | `REACT-PURE-01` / `REACT-PURE-02` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| `.push`, `.sort`, `.splice` or direct assignment to props/state | `REACT-PURE-03` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| A value mutated after it already went into the JSX | `REACT-PURE-05` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| `Component(props)` instead of `<Component />` | `REACT-CALL-01` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| A Hook stored in a variable or object, or passed as an argument | `REACT-CALL-02` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) |
| `ref.current` read or written in the render | `REACT-REF-01` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) |

## Level 2 — critical rules (high)

From [React.js](../../../../knowledge-base/docs/react-js.md) § 6.1: a latent bug, not style. A race condition, a white screen, an endpoint with no authorization.

| Antipattern | Canonical ID | Satellite |
| --- | --- | --- |
| A `fetch` in a `useEffect` in new code | `REACT-EFFECT-06` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) |
| State mirroring props/state through a `useEffect` | `REACT-PAT-01` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| Remote data kept in `useState` as the source of truth | `REACT-PAT-03` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| Interaction logic inside an Effect instead of the handler | `REACT-EFFECT-05` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) |
| A `<Suspense>` waiting on a fetch done in a `useEffect` | `REACT-ASYNC-03` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) |
| A Suspense boundary at a data boundary with no Error Boundary | `REACT-ASYNC-08` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) |
| An expected error thrown to a boundary instead of becoming state | `REACT-ASYNC-09` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) |
| Memoization without measurement | `REACT-PERF-01` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) |
| `'use client'` at the top of the tree | `REACT-RSC-03` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) |
| A Server Function without authenticating, validating and authorizing | `REACT-RSC-06` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) |
| Server HTML mounted with `createRoot` | `REACT-DOM-01` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) |

## Level 3 — structure (medium)

Antipatterns from [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 and from the satellites' families. Fixable in the same PR.

| Antipattern | Canonical ID | Satellite |
| --- | --- | --- |
| State lifted above the nearest common ancestor | `REACT-PAT-02` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| A new boolean prop for a content variation | `REACT-PAT-04` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| A component extracted with no conceptual justification | `REACT-PAT-05` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| An Error Boundary only at the root | `REACT-PAT-06` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| A boundary with no recovery path | `REACT-ASYNC-11` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) |
| Filter/tab/pagination in `useState` instead of the URL | `REACT-PAT-10` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |
| `setState(x + 1)` where the previous value matters | `REACT-STATE-01` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) |
| Parallel booleans where a discriminated union fits | `REACT-STATE-06` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) |
| Context for frequently written state | `REACT-STATE-08` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) |
| An Effect with no cleanup on a subscription/timer/listener | `REACT-EFFECT-01` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) |
| `eslint-disable` on `exhaustive-deps` | `REACT-EFFECT-03` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) |
| `useEffect(async …)` | `REACT-EFFECT-12` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) |
| `memo` without stabilizing the props | `REACT-PERF-03` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) |
| `useMemo` used for required identity | `REACT-PERF-05` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) |
| A list of thousands of items treated with memoization | `REACT-PERF-09` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) |
| A transition controlling a text field | `REACT-PERF-10` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) |
| `forwardRef` in current code | `REACT-REF-03` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) |
| A portal without focus, `Esc` and `aria-modal` | `REACT-REF-07` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) |
| `e.preventDefault` with `<form action>` | `REACT-FORM-01` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) |
| A field with no `name` read through `FormData` | `REACT-FORM-02` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) |
| `useFormStatus` in the component that renders the `<form>` | `REACT-FORM-05` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) |
| `useOptimistic` over data that lives in Query's cache | `REACT-FORM-07` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) |
| A Client Component importing a Server Component | `REACT-RSC-04` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) |
| A non-serializable prop crossing the boundary | `REACT-RSC-05` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) |
| `cache` used as a cache across requests | `REACT-RSC-08` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) |
| A render branching on `typeof window` | `REACT-DOM-03` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) |
| `<StrictMode>` removed to "fix" double execution | `REACT-DOM-06` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) |
| An accessibility ID without `useId` | `REACT-UTIL-01` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) |
| A `subscribe` with unstable identity in `useSyncExternalStore` | `REACT-UTIL-04` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) |
| `index` as the `key` in a reorderable list | no ID — [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) |

## Level 4 — the domain's satellite

Only now, and only for the domain the code actually touches, discovered through [React.js](../../../../knowledge-base/docs/react-js.md) § 4.
Opening a satellite before that is context spent with no return.

## Level 5 — style and legibility

Last and subordinate to the previous ones. **Never** propose a cosmetic refactor on top of
code that violates Level 1: report the violation first.

---

## Two handoffs

| If the scan reveals… | The review does not continue here |
| --- | --- |
| the problem is **where the file lives** or who imports whom | `react-structure`, the `REACT-ARCH-*` family |
| the component is **confirmed slow** and needs a measured fix | *(vague route — see `memory/STACK.md`)* |

---

## Related

- `sondas.md` — what to run before this grid
- `severidade-e-relatorio.md` — how to classify and report
- `mapa-de-ids.md` — where each ID is declared
