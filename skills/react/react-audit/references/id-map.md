---
generated-by: skills/react/react-audit/scripts/generate-id-map.sh
generated-at: 2026-10-25
---

# ID map for the audit — `REACT-*`, `REACT-ARCH-*`, `RHF-*`

> Joined from the maps of react-review, react-structure and react-hook-form. Where a rule lives, never what it says.

## Contents
- [`REACT-*`](#react-)
- [`REACT-ARCH-*`](#react-arch-)
- [`RHF-*`](#rhf-)

## `REACT-*`


> A router, not a copy: this file says **where** the rule is declared, never what it says.
> For the text, open the satellite. Regenerate with `bash skills/react/react-review/scripts/generate-id-map.sh`.

### Aliases — never cite one in a review

From [React.js](../../docs/react-js.md) § 6.2. Always cite the canonical ID; an alias in a finding is an invalid finding.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| A derivable value never becomes state | `REACT-PAT-01` | `REACT-STATE-03`, `REACT-EFFECT-04` |
| An expected error is state, not an exception for a boundary | `REACT-ASYNC-09` | `REACT-PAT-07`, `REACT-FORM-03` |
| A Server Function validates and authorizes at the boundary | `REACT-RSC-06` | `REACT-PAT-09`, `REACT-FORM-08` |
| `'use client'` as low as possible | `REACT-RSC-03` | `REACT-PAT-08` |
| Props and state are never mutated | `REACT-PURE-03` | `REACT-STATE-02` |

### Full index

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

## `REACT-ARCH-*`


> An index, not a copy: each rule's text lives in [Feature-Based Architecture](../../docs/feature-based-architecture.md) § 4.
> The **Enforced by** column says whether lint catches it or it depends on human review — that is what decides
> whether a finding comes back in the next PR. Regenerate with `bash skills/react/react-structure/scripts/generate-id-map.sh`.

| ID | Severity | Enforced by | Section of the extended body |
| --- | --- | --- | --- |
| `REACT-ARCH-01` | critical | review | — |
| `REACT-ARCH-02` | critical | review | — |
| `REACT-ARCH-03` | critical | review | — |
| `REACT-ARCH-04` | critical | `noImportCycles` | why the cycle detects it |
| `REACT-ARCH-05` | critical | `noRestrictedImports` | — |
| `REACT-ARCH-06` | critical | `noRestrictedImports` | — |
| `REACT-ARCH-07` | critical | `noRestrictedImports` partial | — |
| `REACT-ARCH-08` | high | review | the third-consumer rule |
| `REACT-ARCH-09` | high | review (see bench test) | bench test |
| `REACT-ARCH-10` | high | `noImportCycles` | — |
| `REACT-ARCH-11` | medium | review | — |
| `REACT-ARCH-12` | medium | review | — |

A row with `—` in the last column: the rule is declared in the § 4 table and has no
extended-body subsection of its own. The others do, and that is where the reasoning lives.

## `RHF-*`


> An index, not a copy: it says **where** the rule is declared, never what it says.
> Regenerate with `bash skills/react/react-hook-form/scripts/generate-id-map.sh`.

### Citing across docs

Inside a form review, the `RHF-*` ID is enough. **When citing across docs**
— a React review that touches a form, or the other way round — use the canonical one,
or whoever fixes it will not find the text. The tables below come from § 6.2 of the hub.


**Citation rule:** inside a review restricted to forms, the `RHF-*` ID is enough and is what the satellites' tables use. **When citing across docs** — a React review that touches a form, or vice versa — use the canonical one, otherwise the reviewer cannot find the text.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| An expected error is state, not an exception for a boundary | `REACT-ASYNC-09` ([React - Suspense and Async](../../docs/react-suspense-and-async.md)) | `RHF-ERR-03`, `REACT-FORM-03`, `REACT-PAT-07` |
| The server revalidates and authorizes at the boundary | `REACT-RSC-06` ([React - Server Components and Directives](../../docs/react-server-components-and-directives.md)) | `RHF-CORE-05`, `REACT-FORM-08`, `REACT-PAT-09` |

**`RHF-BRIDGE-04` is canonical**, with no equivalent in the React corpus: "optimism over a remote cache belongs to the mutation" is a boundary rule between RHF and TanStack Query. `REACT-FORM-07` deals with something else — that `useOptimistic` is not a source of truth — and must not be cited in its place.

Two more React principles that RHF does **not** redefine — cite the React ID:

| Principle | Canonical | Where RHF mentions it |
| --- | --- | --- |
| Remote data never becomes a local snapshot as the source of truth | `REACT-PAT-03` | `RHF-BRIDGE-03` is an alias — static `defaultValues` is exactly that |
| A stale request needs cancellation | `REACT-EFFECT-06` | `RHF-VAL-10` is an alias — async validation has the same race condition |
| A derivable value never becomes its own state | `REACT-PAT-01` | it is **step 1** of the re-render investigation order ("is there a `useState` mirroring a field?"), which appears in three notes without an ID. Cite `REACT-PAT-01` |

And RHF's own internal pairs, where the same norm appears in more than one place:

| Principle | Canonical | Alias |
| --- | --- | --- |
| `field.onChange` never receives `undefined` | `RHF-CORE-06` | `RHF-CTRL-02` |
| Under `FormProvider`, state comes from `useFormState` | `RHF-STATE-01` | `RHF-CTX-01` |
| Global `shouldUnregister` is incompatible with `useFieldArray` | `RHF-ARRAY-03` | `RHF-CTRL-06` |
| An expected error does not bubble up as an exception from `onSubmit` | `RHF-ERR-03` | `RHF-ERR-01` — same norm, same table, two IDs |
| A post-submission `reset` requires a real success signal | `RHF-STATE-02` | `RHF-STATE-09` — the predicate is already in `-02` |
| The form's type derives from the schema | `RHF-VAL-04` | `RHF-STEP-02` |
| Does the component forward `ref`? decides `register` × `Controller` | `RHF-CORE-03` | `RHF-CTRL-08` is the other half of the same predicate |


### Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `RHF-A11Y-01` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-A11Y-02` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-A11Y-03` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-A11Y-04` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-ARRAY-01` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-02` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-03` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-04` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-05` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-06` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-BRIDGE-01` | [React Hook Form](../../docs/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-02` | [React Hook Form](../../docs/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-03` | [React Hook Form](../../docs/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-04` | [React Hook Form](../../docs/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-05` | [React Hook Form](../../docs/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-CORE-01` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-02` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-03` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-04` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-05` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-06` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-CTRL-01` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-02` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-03` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3.5 Rules — `RHF-CTRL-*` |
| `RHF-CTRL-04` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-05` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-06` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-07` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-08` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-09` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-10` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-11` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-12` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-13` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTX-01` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-CTX-02` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-CTX-03` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-CTX-04` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-ERR-01` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-02` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-03` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-04` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-05` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-06` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-07` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-PERF-01` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-PERF-02` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-PERF-03` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-PERF-04` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-REG-01` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-02` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-03` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-04` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-05` | [React Hook Form - Registration and Control](../../docs/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-STATE-01` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-02` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-03` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-04` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-05` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-06` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-07` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-08` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-09` | [React Hook Form](../../docs/react-hook-form.md) | 6. Normative rules |
| `RHF-STATE-10` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-11` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-12` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STEP-01` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-02` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-03` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-04` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-05` | [React Hook Form - State and Performance](../../docs/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-VAL-01` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 2. When to validate |
| `RHF-VAL-02` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-03` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 2. When to validate |
| `RHF-VAL-04` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-05` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-06` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-07` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-08` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 5. Native browser validation |
| `RHF-VAL-09` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 5. Native browser validation |
| `RHF-VAL-10` | [React Hook Form - Validation and Resolvers](../../docs/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
