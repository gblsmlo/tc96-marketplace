---
gerado-por: skills/react/react-review/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-22
---

# ID map `REACT-*` — where each rule lives

> A router, not a copy: this file says **where** the rule is declared, never what it says.
> For the text, open the satellite. Regenerate with:
> `bash skills/react/react-review/scripts/gerar-mapa-de-ids.sh`

## Aliases — never cite one in a review

From [React.js](../../../../knowledge-base/docs/react-js.md) § 6.2. Always cite the canonical ID; an alias in a finding is an invalid finding.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| Valor derivável nunca vira estado | `REACT-PAT-01` | `REACT-STATE-03`, `REACT-EFFECT-04` |
| Erro esperado é estado, não exceção para boundary | `REACT-ASYNC-09` | `REACT-PAT-07`, `REACT-FORM-03` |
| Server Function valida e autoriza na fronteira | `REACT-RSC-06` | `REACT-PAT-09`, `REACT-FORM-08` |
| `'use client'` o mais baixo possível | `REACT-RSC-03` | `REACT-PAT-08` |
| Props e estado nunca são mutados | `REACT-PURE-03` | `REACT-STATE-02` |

## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `REACT-ASYNC-01` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 1. Conceito: espera como posição na árvore |
| `REACT-ASYNC-02` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 1. Conceito: espera como posição na árvore |
| `REACT-ASYNC-03` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 1. Conceito: espera como posição na árvore |
| `REACT-ASYNC-04` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 2. `lazy` |
| `REACT-ASYNC-05` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 2. `lazy` |
| `REACT-ASYNC-06` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 3. `use` |
| `REACT-ASYNC-07` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 3. `use` |
| `REACT-ASYNC-08` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 4. Error Boundaries |
| `REACT-ASYNC-09` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 4. Error Boundaries |
| `REACT-ASYNC-10` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 5. Suspense + transições |
| `REACT-ASYNC-11` | [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) | 4. Error Boundaries |
| `REACT-CALL-01` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 3. Quem chama componentes e Hooks é o React |
| `REACT-CALL-02` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 3. Quem chama componentes e Hooks é o React |
| `REACT-DOM-01` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 1. Cliente: `createRoot` × `hydrateRoot` |
| `REACT-DOM-02` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 1. Cliente: `createRoot` × `hydrateRoot` |
| `REACT-DOM-03` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 1. Cliente: `createRoot` × `hydrateRoot` |
| `REACT-DOM-04` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 2. Servidor: `react-dom/server` |
| `REACT-DOM-05` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 2. Servidor: `react-dom/server` |
| `REACT-DOM-06` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 3. `<StrictMode>` |
| `REACT-DOM-07` | [React - Renderização e Entrypoints](../../../../knowledge-base/docs/react-renderizacao-e-entrypoints.md) | 4. Preloading de recursos |
| `REACT-EFFECT-01` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 1. Conceito: Effect é sincronização, não "código que roda depois" |
| `REACT-EFFECT-02` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 2. A array de dependências |
| `REACT-EFFECT-03` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 2. A array de dependências |
| `REACT-EFFECT-04` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 3. Quando **não** usar Effect |
| `REACT-EFFECT-05` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 3. Quando **não** usar Effect |
| `REACT-EFFECT-06` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 3. Quando **não** usar Effect |
| `REACT-EFFECT-07` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 4. `useEffectEvent` |
| `REACT-EFFECT-08` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 4. `useEffectEvent` |
| `REACT-EFFECT-09` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 4. `useEffectEvent` |
| `REACT-EFFECT-10` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 5. As três variantes |
| `REACT-EFFECT-11` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 5. As três variantes |
| `REACT-EFFECT-12` | [React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md) | 1. Conceito: Effect é sincronização, não "código que roda depois" |
| `REACT-FORM-01` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 2. `<form action>` |
| `REACT-FORM-02` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 2. `<form action>` |
| `REACT-FORM-03` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 3. `useActionState` |
| `REACT-FORM-04` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 3. `useActionState` |
| `REACT-FORM-05` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 4. `useFormStatus` |
| `REACT-FORM-06` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 5. `useOptimistic` |
| `REACT-FORM-07` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 5. `useOptimistic` |
| `REACT-FORM-08` | [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) | 6. Ponte com o stack |
| `REACT-HOOK-01` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 4. Rules of Hooks |
| `REACT-HOOK-02` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 4. Rules of Hooks |
| `REACT-HOOK-03` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 4. Rules of Hooks |
| `REACT-HOOK-04` | [React - Hooks](../../../../knowledge-base/docs/react-hooks.md) | 4. Hooks customizados |
| `REACT-HOOK-05` | [React - Hooks](../../../../knowledge-base/docs/react-hooks.md) | 4. Hooks customizados |
| `REACT-HOOK-06` | [React - Hooks](../../../../knowledge-base/docs/react-hooks.md) | 4. Hooks customizados |
| `REACT-HOOK-07` | [React - Hooks](../../../../knowledge-base/docs/react-hooks.md) | 4. Hooks customizados |
| `REACT-PAT-01` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 2. Posse e colocação de estado |
| `REACT-PAT-02` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 2. Posse e colocação de estado |
| `REACT-PAT-03` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 2. Posse e colocação de estado |
| `REACT-PAT-04` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 3. Composição |
| `REACT-PAT-05` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 3. Composição |
| `REACT-PAT-06` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 6. Fronteiras |
| `REACT-PAT-07` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 6. Fronteiras |
| `REACT-PAT-08` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 6. Fronteiras |
| `REACT-PAT-09` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 6. Fronteiras |
| `REACT-PAT-10` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) | 2. Posse e colocação de estado |
| `REACT-PERF-01` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 1. A regra que precede todas |
| `REACT-PERF-02` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 1. A regra que precede todas |
| `REACT-PERF-03` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 3. Memoização |
| `REACT-PERF-04` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 3. Memoização |
| `REACT-PERF-05` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 3. Memoização |
| `REACT-PERF-06` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 4. Concorrência |
| `REACT-PERF-07` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 6. `<Activity>` |
| `REACT-PERF-08` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 7. React Compiler |
| `REACT-PERF-09` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 5. Reduzir o volume renderizado |
| `REACT-PERF-10` | [React - Performance e Concorrência](../../../../knowledge-base/docs/react-performance-e-concorrencia.md) | 4. Concorrência |
| `REACT-PURE-01` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 2. Componentes e Hooks devem ser puros |
| `REACT-PURE-02` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 2. Componentes e Hooks devem ser puros |
| `REACT-PURE-03` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 2. Componentes e Hooks devem ser puros |
| `REACT-PURE-04` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 2. Componentes e Hooks devem ser puros |
| `REACT-PURE-05` | [React - Rules of React](../../../../knowledge-base/docs/react-rules-of-react.md) | 2. Componentes e Hooks devem ser puros |
| `REACT-REF-01` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 1. `useRef`: memória que não redesenha |
| `REACT-REF-02` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 1. `useRef`: memória que não redesenha |
| `REACT-REF-03` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 2. `ref` como prop (React 19) |
| `REACT-REF-04` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 2. `ref` como prop (React 19) |
| `REACT-REF-05` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 3. `useImperativeHandle` |
| `REACT-REF-06` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 3. `useImperativeHandle` |
| `REACT-REF-07` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 4. `createPortal` |
| `REACT-REF-08` | [React - Refs e DOM](../../../../knowledge-base/docs/react-refs-e-dom.md) | 5. `flushSync` |
| `REACT-RSC-01` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 1. Server Components |
| `REACT-RSC-02` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 1. Server Components |
| `REACT-RSC-03` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 2. `'use client'` |
| `REACT-RSC-04` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 2. `'use client'` |
| `REACT-RSC-05` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 2. `'use client'` |
| `REACT-RSC-06` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 3. `'use server'` |
| `REACT-RSC-07` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 3. `'use server'` |
| `REACT-RSC-08` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 4. `cache` |
| `REACT-RSC-09` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 5. Taint — **experimental** |
| `REACT-RSC-10` | [React - Server Components e Diretivas](../../../../knowledge-base/docs/react-server-components-e-diretivas.md) | 5. Taint — **experimental** |
| `REACT-STATE-01` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 1. Conceito: estado é snapshot |
| `REACT-STATE-02` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 1. Conceito: estado é snapshot |
| `REACT-STATE-03` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 1. Conceito: estado é snapshot |
| `REACT-STATE-04` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 1. Conceito: estado é snapshot |
| `REACT-STATE-05` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 2. `useState` × `useReducer` |
| `REACT-STATE-06` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 2. `useState` × `useReducer` |
| `REACT-STATE-07` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 3. Context |
| `REACT-STATE-08` | [React - Estado e Reatividade](../../../../knowledge-base/docs/react-estado-e-reatividade.md) | 3. Context |
| `REACT-UTIL-01` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 1. `useId` |
| `REACT-UTIL-02` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 1. `useId` |
| `REACT-UTIL-03` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 2. `useSyncExternalStore` |
| `REACT-UTIL-04` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 2. `useSyncExternalStore` |
| `REACT-UTIL-05` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 2. `useSyncExternalStore` |
| `REACT-UTIL-06` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 3. `useDebugValue` |
| `REACT-UTIL-07` | [React - Hooks Utilitários](../../../../knowledge-base/docs/react-hooks-utilitarios.md) | 3. `useDebugValue` |
