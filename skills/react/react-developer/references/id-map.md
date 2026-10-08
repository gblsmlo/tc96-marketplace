---
generated-by: skills/react/react-review/scripts/generate-id-map.sh
generated-at: 2026-10-03
---

# ID map `REACT-*` — where each rule lives

> A router, not a copy: this file says **where** the rule is declared, never what it says.
> For the text, open the satellite. Regenerate with `bash skills/react/react-review/scripts/generate-id-map.sh`.

## Aliases — never cite one in a review

From [React.js](../../docs/react-js.md) § 6.2. Always cite the canonical ID; an alias in a finding is an invalid finding.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| A derivable value never becomes state | `REACT-PAT-01` | `REACT-STATE-03`, `REACT-EFFECT-04` |
| An expected error is state, not an exception for a boundary | `REACT-ASYNC-09` | `REACT-PAT-07`, `REACT-FORM-03` |
| A Server Function validates and authorizes at the boundary | `REACT-RSC-06` | `REACT-PAT-09`, `REACT-FORM-08` |
| `'use client'` as low as possible | `REACT-RSC-03` | `REACT-PAT-08` |
| Props and state are never mutated | `REACT-PURE-03` | `REACT-STATE-02` |

## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `REACT-ASYNC-01` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 1. Concept: waiting as a position in the tree |
| `REACT-ASYNC-02` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 1. Concept: waiting as a position in the tree |
| `REACT-ASYNC-03` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 1. Concept: waiting as a position in the tree |
| `REACT-ASYNC-04` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 2. `lazy` |
| `REACT-ASYNC-05` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 2. `lazy` |
| `REACT-ASYNC-06` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 3. `use` |
| `REACT-ASYNC-07` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 3. `use` |
| `REACT-ASYNC-08` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 4. Error Boundaries |
| `REACT-ASYNC-09` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 4. Error Boundaries |
| `REACT-ASYNC-10` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 5. Suspense + transitions |
| `REACT-ASYNC-11` | [React - Suspense and Async](../../docs/react-suspense-and-async.md) | 4. Error Boundaries |
| `REACT-CALL-01` | [React - Rules of React](../../docs/react-rules-of-react.md) | 3. React is the one that calls components and Hooks |
| `REACT-CALL-02` | [React - Rules of React](../../docs/react-rules-of-react.md) | 3. React is the one that calls components and Hooks |
| `REACT-DOM-01` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 1. Client: `createRoot` × `hydrateRoot` |
| `REACT-DOM-02` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 1. Client: `createRoot` × `hydrateRoot` |
| `REACT-DOM-03` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 1. Client: `createRoot` × `hydrateRoot` |
| `REACT-DOM-04` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 2. Server: `react-dom/server` |
| `REACT-DOM-05` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 2. Server: `react-dom/server` |
| `REACT-DOM-06` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 3. `<StrictMode>` |
| `REACT-DOM-07` | [React - Rendering and Entrypoints](../../docs/react-rendering-and-entrypoints.md) | 4. Resource preloading |
| `REACT-EFFECT-01` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 1. Concept: an Effect is synchronization, not "code that runs afterwards" |
| `REACT-EFFECT-02` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 2. The dependency array |
| `REACT-EFFECT-03` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 2. The dependency array |
| `REACT-EFFECT-04` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 3. When **not** to use an Effect |
| `REACT-EFFECT-05` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 3. When **not** to use an Effect |
| `REACT-EFFECT-06` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 3. When **not** to use an Effect |
| `REACT-EFFECT-07` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 4. `useEffectEvent` |
| `REACT-EFFECT-08` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 4. `useEffectEvent` |
| `REACT-EFFECT-09` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 4. `useEffectEvent` |
| `REACT-EFFECT-10` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 5. The three variants |
| `REACT-EFFECT-11` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 5. The three variants |
| `REACT-EFFECT-12` | [React - Effects and Synchronization](../../docs/react-effects-and-synchronization.md) | 1. Concept: an Effect is synchronization, not "code that runs afterwards" |
| `REACT-FORM-01` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 2. `<form action>` |
| `REACT-FORM-02` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 2. `<form action>` |
| `REACT-FORM-03` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 3. `useActionState` |
| `REACT-FORM-04` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 3. `useActionState` |
| `REACT-FORM-05` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 4. `useFormStatus` |
| `REACT-FORM-06` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 5. `useOptimistic` |
| `REACT-FORM-07` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 5. `useOptimistic` |
| `REACT-FORM-08` | [React - Forms and Actions](../../docs/react-forms-and-actions.md) | 6. Bridge to the stack |
| `REACT-HOOK-01` | [React - Rules of React](../../docs/react-rules-of-react.md) | 4. Rules of Hooks |
| `REACT-HOOK-02` | [React - Rules of React](../../docs/react-rules-of-react.md) | 4. Rules of Hooks |
| `REACT-HOOK-03` | [React - Rules of React](../../docs/react-rules-of-react.md) | 4. Rules of Hooks |
| `REACT-HOOK-04` | [React - Hooks](../../docs/react-hooks.md) | 4. Custom Hooks |
| `REACT-HOOK-05` | [React - Hooks](../../docs/react-hooks.md) | 4. Custom Hooks |
| `REACT-HOOK-06` | [React - Hooks](../../docs/react-hooks.md) | 4. Custom Hooks |
| `REACT-HOOK-07` | [React - Hooks](../../docs/react-hooks.md) | 4. Custom Hooks |
| `REACT-PAT-01` | [React - Patterns](../../docs/react-patterns.md) | 2. State ownership and placement |
| `REACT-PAT-02` | [React - Patterns](../../docs/react-patterns.md) | 2. State ownership and placement |
| `REACT-PAT-03` | [React - Patterns](../../docs/react-patterns.md) | 2. State ownership and placement |
| `REACT-PAT-04` | [React - Patterns](../../docs/react-patterns.md) | 3. Composition |
| `REACT-PAT-05` | [React - Patterns](../../docs/react-patterns.md) | 3. Composition |
| `REACT-PAT-06` | [React - Patterns](../../docs/react-patterns.md) | 6. Boundaries |
| `REACT-PAT-07` | [React - Patterns](../../docs/react-patterns.md) | 6. Boundaries |
| `REACT-PAT-08` | [React - Patterns](../../docs/react-patterns.md) | 6. Boundaries |
| `REACT-PAT-09` | [React - Patterns](../../docs/react-patterns.md) | 6. Boundaries |
| `REACT-PAT-10` | [React - Patterns](../../docs/react-patterns.md) | 2. State ownership and placement |
| `REACT-PERF-01` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 1. The rule that comes before all others |
| `REACT-PERF-02` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 1. The rule that comes before all others |
| `REACT-PERF-03` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 3. Memoization |
| `REACT-PERF-04` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 3. Memoization |
| `REACT-PERF-05` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 3. Memoization |
| `REACT-PERF-06` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 4. Concurrency |
| `REACT-PERF-07` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 6. `<Activity>` |
| `REACT-PERF-08` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 7. React Compiler |
| `REACT-PERF-09` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 5. Reduce the rendered volume |
| `REACT-PERF-10` | [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) | 4. Concurrency |
| `REACT-PERF-11` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 1. Two kinds of number |
| `REACT-PERF-12` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 1. Two kinds of number |
| `REACT-PERF-13` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 2. Order: baseline first |
| `REACT-PERF-14` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 2. Order: baseline first |
| `REACT-PERF-15` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 3. Iterations and statistics |
| `REACT-PERF-16` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 4. What travels with the numbers |
| `REACT-PERF-17` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 5. The results file |
| `REACT-PERF-18` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 6. Correctness after memoization |
| `REACT-PERF-19` | [React - Performance Measurement](../../docs/react-performance-measurement.md) | 7. The README section |
| `REACT-PURE-01` | [React - Rules of React](../../docs/react-rules-of-react.md) | 2. Components and Hooks must be pure |
| `REACT-PURE-02` | [React - Rules of React](../../docs/react-rules-of-react.md) | 2. Components and Hooks must be pure |
| `REACT-PURE-03` | [React - Rules of React](../../docs/react-rules-of-react.md) | 2. Components and Hooks must be pure |
| `REACT-PURE-04` | [React - Rules of React](../../docs/react-rules-of-react.md) | 2. Components and Hooks must be pure |
| `REACT-PURE-05` | [React - Rules of React](../../docs/react-rules-of-react.md) | 2. Components and Hooks must be pure |
| `REACT-REF-01` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 1. `useRef`: memory that does not redraw |
| `REACT-REF-02` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 1. `useRef`: memory that does not redraw |
| `REACT-REF-03` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 2. `ref` as a prop (React 19) |
| `REACT-REF-04` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 2. `ref` as a prop (React 19) |
| `REACT-REF-05` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 3. `useImperativeHandle` |
| `REACT-REF-06` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 3. `useImperativeHandle` |
| `REACT-REF-07` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 4. `createPortal` |
| `REACT-REF-08` | [React - Refs and DOM](../../docs/react-refs-and-dom.md) | 5. `flushSync` |
| `REACT-RSC-01` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 1. Server Components |
| `REACT-RSC-02` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 1. Server Components |
| `REACT-RSC-03` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 2. `'use client'` |
| `REACT-RSC-04` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 2. `'use client'` |
| `REACT-RSC-05` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 2. `'use client'` |
| `REACT-RSC-06` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 3. `'use server'` |
| `REACT-RSC-07` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 3. `'use server'` |
| `REACT-RSC-08` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 4. `cache` |
| `REACT-RSC-09` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 5. Taint — **experimental** |
| `REACT-RSC-10` | [React - Server Components and Directives](../../docs/react-server-components-and-directives.md) | 5. Taint — **experimental** |
| `REACT-STATE-01` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 1. Concept: state is a snapshot |
| `REACT-STATE-02` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 1. Concept: state is a snapshot |
| `REACT-STATE-03` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 1. Concept: state is a snapshot |
| `REACT-STATE-04` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 1. Concept: state is a snapshot |
| `REACT-STATE-05` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 2. `useState` × `useReducer` |
| `REACT-STATE-06` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 2. `useState` × `useReducer` |
| `REACT-STATE-07` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 3. Context |
| `REACT-STATE-08` | [React - State and Reactivity](../../docs/react-state-and-reactivity.md) | 3. Context |
| `REACT-UTIL-01` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 1. `useId` |
| `REACT-UTIL-02` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 1. `useId` |
| `REACT-UTIL-03` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 2. `useSyncExternalStore` |
| `REACT-UTIL-04` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 2. `useSyncExternalStore` |
| `REACT-UTIL-05` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 2. `useSyncExternalStore` |
| `REACT-UTIL-06` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 3. `useDebugValue` |
| `REACT-UTIL-07` | [React - Utility Hooks](../../docs/react-utility-hooks.md) | 3. `useDebugValue` |
