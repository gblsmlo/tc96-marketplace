---
titulo: React.js
Link: https://react.dev/reference/react
tags:
  - react
  - frontend
  - reference
  - agent-context
source: "Official React documentation — react.dev/reference"
verificado-em: 2026-08-14
---
# React.js — guided reference

> **What this note is.** The single entry point for React in this vault: for me when consulting, and for coding agents when generating or reviewing React. It is not a linear summary of the documentation — it is a **router**. It decides what to load, offers the mental model that makes the rest make sense, and exposes citable rules that a skill or a code review can reference by ID.
>
> **What it is not.** It does not replace the source. When they diverge, [react.dev/reference](https://react.dev/reference/react) wins, and this note must be corrected.
>
> **A self-contained family.** These notes live inside the `react` skill family, not in the tc96 knowledge base, so the family can move without it. Names in code spans — `TanStack Query`, `TanStack Router`, `Storybook`, `Monorepo com Bun - estrutura e tooling` — and IDs from other families (`TSQ-*`, `TSR-*`, `SB-*`, `PW-*`) belong to the tc96 knowledge base: useful context when it is installed, never required to apply a `REACT-*`, `RHF-*` or `REACT-ARCH-*` rule.

Inventory verified directly on react.dev on **2026-08-14**.
See [Sources consulted](#sources-consulted).

---

## 1. How to use this doc

### For a human

Read section 2 (mental model) once. Then use section 4 as an index and section 5 when you are torn between two APIs. The satellites are for on-demand reading, not in order.

### For a coding agent

Load in this order, stopping as soon as you have enough:

| Step | Load                             | When                                                                      |
| ---- | -------------------------------- | ------------------------------------------------------------------------- |
| 1    | This note (sections 2, 5, 6)     | Whenever the task involves React                                          |
| 2    | [React - Rules of React](react-rules-of-react.md)       | Whenever you are going to **write or modify** components/Hooks            |
| 3    | The satellite for the specific domain | When the task touches a concrete API — use section 4 to find out which |
| 4    | [React - Patterns](react-patterns.md)             | Structural decisions: where state lives, how to compose, what to extract  |
| 5    | [React - Hooks](react-hooks.md)                | Reference for a Hook's signature, parameters and caveats                  |

**Context economy rule:** never load all the satellites.

### Conventions and vocabulary

**All examples are TypeScript.** The doc assumes TS across the whole corpus (annotations, discriminated unions, generics). In JS, ignore the annotations — no rule depends on types.

Terms used without redefinition in the satellites:

| Term | Meaning in this doc |
| --- | --- |
| **reactive value** | props, state, context, and anything calculated from them |
| **snapshot** | the frozen value of a piece of state inside a specific render |
| **identity** (referential) | whether two references are the same object (`Object.is`). An object, array or function created in render has a **new** identity on every render, even with equal content — this is why `memo` fails and why dependencies fire |
| **shallow equality** | comparing each top-level prop by identity, without descending into the structure. It is what `memo` does |
| **lifting** (lifting state) | moving state to the common ancestor of the components that read it |
| **prop drilling** | passing a prop through intermediate levels that do not use it |
| **server state** | remote data that someone else can change without you knowing; the opposite of client state |
| **race condition** | two in-flight requests whose arrival order flips, and the old response overwrites the new one |
| **tearing** | parts of the tree reading different values from the same store in the same frame |
| **virtualization** (windowing) | rendering only the visible rows of a long list, instead of all of them |

### The two satellite structures

Besides the thematic satellites, two notes work as standalone sub-indexes and point back here:

- **[React - Hooks](react-hooks.md)**: the API surface per Hook: signature, parameters, return, caveats. It is a lookup reference.
- **[React - Patterns](react-patterns.md)**: composition and architecture patterns, connecting the official reference to the structural decisions. It is a decision reference.

---

## 2. Mental model

Five statements. Almost every React mistake an agent makes violates one of them.

**1. A component is a pure function of its inputs.** Given the same props, state and context, it produces the same JSX. React assumes this so it can render, pause, discard and repeat work freely. It is the normative basis of [React - Rules of React](react-rules-of-react.md) .

**2. State is a snapshot, not a variable.** Inside a render, the state value is fixed. `setState` does not change the current variable — it **schedules** a new render. That is why `setCount(count + 1)` twice in a row increments once, and the updater form `setCount(c => c + 1)` increments twice.

**3. Render and commit are distinct phases.** Render is the pure calculation of the JSX; commit is when React applies the changes to the DOM. Effects run **after** the commit. Nothing that observes or touches the outside world belongs in render.

**4. Reactivity comes from values, not from declared dependencies.** Props, state and everything derived from them are reactive values. An Effect's dependency array is not a "when to run" control — it **describes** what the Effect reads. Adjusting the list to avoid a loop treats the symptom; the problem is almost always that the Effect should not exist.

**5. An Effect is synchronization with an external system — not "code that runs afterwards".** If there is no system outside React (unmanaged DOM, subscription, timer, socket, analytics), it is probably not an Effect. This eliminates most of the `useEffect`s an agent writes out of habit.

> **Fetching data from the network is the exception that confuses.** Technically the network is an external system, but fetch in `useEffect` is explicitly forbidden in new code by `REACT-EFFECT-06` — it does not solve race conditions, cache, dedupe or retry. Use a data fetching library. See § 6.1 and [React - Effects and Synchronization](react-effects-and-synchronization.md) § 3.

---

## 3. Package boundaries

Knowing where something is imported from avoids half of the import mistakes.

| Package | Contains | Runs where |
| --- | --- | --- |
| `react` | Hooks, built-in components, component definition APIs | Client and server |
| `react-dom` | Portals, synchronous flush, resource preloading, `useFormStatus` | Client |
| `react-dom/client` | `createRoot`, `hydrateRoot` | Client |
| `react-dom/server` | Rendering to stream/string | Server |
| `react-dom/static` | Static pre-rendering | Build/server |

`use` is an **API**, not a Hook — and that is why it is the only thing on the list that can be called conditionally. See [React - Suspense and Async](react-suspense-and-async.md).

---

## 4. API map

Active surface of the official reference — what is used in new code. The **Satellite** column says what to load.

**Deliberately left out of this map:** legacy or rarely used APIs that the doc does not cover — `createElement`, `cloneElement`, `isValidElement`, `Children`, `createRef`, `Component`, `PureComponent`, and the reference's Legacy APIs section. If the task requires one of them, consult react.dev directly: absence here means "not verified in this doc", not "does not exist".

### `react` — Hooks

| Hook | What it is for | Satellite |
| --- | --- | --- |
| `useState` | Local state declared directly | [React - State and Reactivity](react-state-and-reactivity.md) |
| `useReducer` | Local state with transitions in a reducer | [React - State and Reactivity](react-state-and-reactivity.md) |
| `useContext` | Read and subscribe to a context | [React - State and Reactivity](react-state-and-reactivity.md) |
| `useRef` | Mutable value that does not trigger render; DOM ref | [React - Refs and DOM](react-refs-and-dom.md) |
| `useImperativeHandle` | Customize the ref exposed by a component (rare) | [React - Refs and DOM](react-refs-and-dom.md) |
| `useEffect` | Synchronize with an external system | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useLayoutEffect` | Measure layout before paint | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useInsertionEffect` | Insert dynamic CSS (CSS-in-JS libraries) | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useEffectEvent` | Extract non-reactive logic from inside an Effect | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useMemo` | Cache an expensive calculation between renders | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useCallback` | Cache a function's identity between renders | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useTransition` | Mark an update as non-blocking, with a pending flag | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useDeferredValue` | Defer updating a non-critical part of the UI | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useActionState` | State, action and pending status of an Action | [React - Forms and Actions](react-forms-and-actions.md) |
| `useOptimistic` | Optimistic state during a pending Action | [React - Forms and Actions](react-forms-and-actions.md) |
| `useId` | Unique, stable ID, aligned between server and client | [React - Utility Hooks](react-utility-hooks.md) |
| `useSyncExternalStore` | Subscribe to an external store safely under concurrency | [React - Utility Hooks](react-utility-hooks.md) |
| `useDebugValue` | Custom Hook label in DevTools | [React - Utility Hooks](react-utility-hooks.md) |

### `react` — Built-in components

| Component | What it is for | Satellite |
| --- | --- | --- |
| `<Fragment>` (`<>...</>`) | Group nodes without creating a DOM element. You only need the long form `<Fragment key={…}>` when rendering a list — the short form `<>` does not accept `key` | — |
| `<Suspense>` | Show a fallback while children load | [React - Suspense and Async](react-suspense-and-async.md) |
| `<StrictMode>` | Extra checks in development | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| `<Profiler>` | Measure render performance programmatically | [React - Performance and Concurrency](react-performance-and-concurrency.md) · how to turn it into a measurement: [React - Performance Measurement](react-performance-measurement.md) |
| `<Activity>` | Hide and restore UI **preserving internal state** | [React - Performance and Concurrency](react-performance-and-concurrency.md) |

### `react` — APIs

| API | What it is for | Satellite |
| --- | --- | --- |
| `createContext` | Create a context | [React - State and Reactivity](react-state-and-reactivity.md) |
| `memo` | Skip re-render when props do not change | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `lazy` | Defer loading a component's code | [React - Suspense and Async](react-suspense-and-async.md) |
| `use` | Read a Promise or a context — can be conditional | [React - Suspense and Async](react-suspense-and-async.md) |
| `startTransition` | Mark an update as non-urgent, outside a component | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `act` | Wrap render/interaction in tests | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| `forwardRef` | **No longer necessary** — `ref` is a prop since React 19 | [React - Refs and DOM](react-refs-and-dom.md) |

### `react-dom`

| API | What it is for | Satellite |
| --- | --- | --- |
| `createPortal` | Render children at another point of the DOM tree | [React - Refs and DOM](react-refs-and-dom.md) |
| `flushSync` | Force a synchronous flush of an update | [React - Refs and DOM](react-refs-and-dom.md) |
| `useFormStatus` | Read the status of the ancestor `<form>` | [React - Forms and Actions](react-forms-and-actions.md) |
| `<form action>` | Submission managed by React, with `FormData` | [React - Forms and Actions](react-forms-and-actions.md) |
| `ref` as a prop / ref callback with cleanup | Access to a DOM node (React 19) | [React - Refs and DOM](react-refs-and-dom.md) |
| `suppressHydrationWarning` | Silence a hydration mismatch on a node | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| Error Boundary | Isolate a render failure — **not exported by React** | [React - Suspense and Async](react-suspense-and-async.md) |
| `preload`, `preinit`, `preloadModule`, `preinitModule`, `preconnect`, `prefetchDNS` | Signal resources to the browser ahead of time | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |

### `react-dom/client`, `/server`, `/static`

| API | Runtime | Satellite |
| --- | --- | --- |
| `createRoot`, `hydrateRoot` | Browser | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| `renderToPipeableStream`, `resumeToPipeableStream` | Node Streams (recommended on Node) | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| `renderToReadableStream`, `resume` | Web Streams (Deno, edge, browser) | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| `renderToString`, `renderToStaticMarkup` | No streaming — **legacy**, limited functionality | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |
| `prerender`, `prerenderToNodeStream` | Static generation | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |

### RSC and React Compiler

| Item | What it is for | Satellite |
| --- | --- | --- |
| `'use client'` | Marks the boundary from which code goes to the client | [React - Server Components and Directives](react-server-components-and-directives.md) |
| `'use server'` | Marks server functions callable by the client | [React - Server Components and Directives](react-server-components-and-directives.md) |
| `cache` | Memoize a function by arguments within a server render pass | [React - Server Components and Directives](react-server-components-and-directives.md) |
| `experimental_taintObjectReference`, `experimental_taintUniqueValue` | Prevent sensitive data from crossing to the client — **experimental, not for production** | [React - Server Components and Directives](react-server-components-and-directives.md) |
| `'use memo'` / `'use no memo'` | Per-function compilation opt-in / opt-out | [React - Performance and Concurrency](react-performance-and-concurrency.md) |

---

## 5. Decision trees

The goal here is to map **symptom → correct API**, because that choice is where generated React code usually goes wrong.

### I need to keep a value. Where?

Two questions, in this order: **which mechanism** and **in which component**. Skipping the second is the most common cause of prop drilling and global re-render.

**A. Which mechanism?** The origin check comes first — getting it wrong here violates `REACT-PAT-03`.

```
Does the data come from the server?
├── YES → it is not client state. Do not use useState as the source of truth.
│         → TanStack Query. See § 8
└── NO
    └── Is it derivable from props/state that already exist?
        ├── YES → calculate it in render. Do not create state.
        │         Truly expensive (measured)? → useMemo
        │ →
        └── NO
            └── Should changing it redraw the UI?
                ├── NO → useRef
                └── YES
                    ├── Belongs to the URL (filter, tab, pagination,
                    │   anything that should survive a
                    │   refresh and be shareable by link)
                    │   → route state. See § 8
                    ├── Comes from a store outside React
                    │   → useSyncExternalStore
                    ├── Several related transitions, or states
                    │   that cannot coexist → useReducer
                    └── General case → useState
```

**B. In which component?**

```
How many components read this state?
├── One → in that component itself (colocation)
├── Several siblings → in the NEAREST common ancestor, and stop there
│   └── Is the lift crossing levels that do not use the data?
│       → composition (children/slots) before Context
└── The whole tree, frequent reads and rare writes → Context
    └── Frequent writes? → external store
```

And a derived value consumed by more than one sibling: **calculate it once in the state owner** and pass the result down; do not repeat the same `filter` in each child. Detail and examples in [React - Patterns](react-patterns.md) § 2.

### I need to run a side effect. Where?

```
Does the code respond to a specific user interaction?
└── YES → event handler. Not an Effect. Stop here.

No. Then: is there an external system to synchronize
(unmanaged DOM, subscription, timer, socket, analytics)?
├── NO → it probably should not exist.
│         Derived state → calculate in render
│         Reacting to a prop change → calculate or use key
│         Fetching data → data fetching library
└── YES
    ├── Needs to measure layout before paint → useLayoutEffect
    ├── Injects CSS (library) → useInsertionEffect
    └── General case → useEffect
        └── Reads a value that should NOT re-run the Effect
            → extract it with useEffectEvent
```

### The UI freezes during an update

**Do not start with memoization.** The order below goes from cheapest to most expensive and is normative — it is detailed in [React - Performance and Concurrency](react-performance-and-concurrency.md) § 1.

```
0. DID YOU MEASURE? Profiler or DevTools. Without a measurement, stop here. (REACT-PERF-01)
   └── React Compiler active in the project? Then manual memoization
       is redundant — solve it through steps 1-3. (REACT-PERF-02)

1. Are you creating unnecessary state? → calculate in render
2. Is the state too high in the tree? → move it down to its real owner
3. Does composition solve it? → moving state into a smaller component,
   or passing children as a prop, eliminates re-render WITHOUT memoizing

4. Still slow? How many nodes are being rendered?
   ├── Thousands of rows/items in the DOM
   │   → the cost is volume, not calculation. Concurrency does NOT solve it.
   │   → reduce what is rendered: virtualization or pagination
   └── Few nodes, but heavy calculation on every keystroke/update
       ├── I want to deprioritize the UPDATE I trigger
       │   ├── and I need a pending flag → useTransition
       │   └── and I am outside a component → startTransition
       └── I want the heavy CONSUMER to lag behind while
           the input responds immediately → useDeferredValue
           (+ memo on the derived calculation, otherwise the work runs anyway)

5. Unnecessary child re-render, confirmed in the Profiler
   → memo + prop stability (useCallback / useMemo)
```

> **`useTransition` × `useDeferredValue`.** The documentation's criterion is access to the `set`: *"You can wrap an update into a Transition only if you have access to the `set` function of that state. If you want to start a Transition in response to some prop or a custom Hook value, try `useDeferredValue` instead."* Without access to the `set` — the value arrives as a prop or from a third-party Hook — only `useDeferredValue` remains.
>
> When you **do** have access and both are possible (a search field is the typical case), what decides is the target: `useTransition` marks **the update** as interruptible and gives you `isPending`; `useDeferredValue` lets **the heavy consumer** show the old value while the input responds immediately. For a controlled input + expensive list, `useDeferredValue` is the usual choice — and note the official caveat that transitions **do not** work for controlling text inputs.

### I need to handle something asynchronous

```
Remote data in a client app → TanStack Query
Heavy component to load on demand → lazy + <Suspense>
Promise created on the server, read on the client → use + <Suspense>
Form submission with pending status and error → useActionState
Immediate feedback before the response arrives
  ├── the data lives in a query's cache → optimistic mutation, NOT useOptimistic
  │ →
  └── it does not → useOptimistic
Render failure to isolate → Error Boundary
  →
```

> The optimistic feedback branch matters: `useOptimistic` and an optimistic mutation solve the same problem at different layers, and using both on the same data produces two diverging sources of truth (`REACT-FORM-07`).

---

## 6. Normative rules

Rules citable by ID. A skill, a review prompt or a PR comment can reference `REACT-PURE-01` without repeating the text. The full body of each family lives in the corresponding satellite; the inviolable ones stay here.

**Convention:** `MUST` / `NEVER` are normative. A violation is a bug, not a matter of style.

### `REACT-PURE-*` — purity (source: Rules of React)

| ID | Rule |
| --- | --- |
| `REACT-PURE-01` | A component **MUST** return the same output for the same props, state and context. |
| `REACT-PURE-02` | Side effects **NEVER** run during render — only in event handlers or Effects. |
| `REACT-PURE-03` | Props and state are **NEVER** mutated directly. |
| `REACT-PURE-04` | Values passed to a Hook are **NEVER** modified afterwards. |
| `REACT-PURE-05` | Values used in JSX are **NEVER** mutated after the JSX is created. |

### `REACT-CALL-*` — who calls what

| ID | Rule |
| --- | --- |
| `REACT-CALL-01` | Components are **NEVER** called as regular functions; only used in JSX. |
| `REACT-CALL-02` | Hooks are **NEVER** passed around as values. |

### `REACT-HOOK-*` — Rules of Hooks

| ID | Rule |
| --- | --- |
| `REACT-HOOK-01` | Hooks **MUST** be called at the top level, never in loops, conditions, nested functions or after an early return. |
| `REACT-HOOK-02` | Hooks **MUST** be called only from components or from other Hooks. |
| `REACT-HOOK-03` | `use` is the **only** exception to `REACT-HOOK-01`: it can be called conditionally. |

### 6.1 Critical rules from the satellites

The full families live in the satellites, but **these need to travel with the minimal path** — they are the ones that show up most in generated code and cannot depend on the agent having opened the right satellite.

| ID | Rule | Satellite |
| --- | --- | --- |
| `REACT-PAT-01` | A derivable value **NEVER** becomes its own state. | [React - Patterns](react-patterns.md) |
| `REACT-PAT-03` | Remote data is **NEVER** `useState` as the source of truth. | [React - Patterns](react-patterns.md) |
| `REACT-EFFECT-04` | An Effect **NEVER** derives state from another state or prop. | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `REACT-EFFECT-05` | Logic that responds to an interaction **MUST** stay in the event handler. | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `REACT-EFFECT-06` | Fetch in `useEffect` **NEVER** in new code. | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `REACT-ASYNC-03` | `<Suspense>` **NEVER** works with fetch in `useEffect`. | [React - Suspense and Async](react-suspense-and-async.md) |
| `REACT-ASYNC-08` | A Suspense boundary at a data boundary **MUST** have an Error Boundary. | [React - Suspense and Async](react-suspense-and-async.md) |
| `REACT-ASYNC-09` | An expected error is **NEVER** thrown to a boundary — it is state. | [React - Suspense and Async](react-suspense-and-async.md) |
| `REACT-PERF-01` | Memoization **MUST** have a measured justification. | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `REACT-FORM-03` | An expected error **MUST** be returned in the action's state, never thrown. | [React - Forms and Actions](react-forms-and-actions.md) |
| `REACT-RSC-03` | `'use client'` **MUST** sit as low as possible in the tree. | [React - Server Components and Directives](react-server-components-and-directives.md) |
| `REACT-RSC-06` | A Server Function **MUST** authenticate, validate and authorize — it is a public endpoint. | [React - Server Components and Directives](react-server-components-and-directives.md) |
| `REACT-DOM-01` | Server HTML **MUST** be hydrated with `hydrateRoot`. | [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) |

### 6.2 Canonical IDs

Five principles appear in more than one satellite, with different IDs, because each satellite needs to stand on its own. **When citing, always use the canonical ID** — the others are aliases and should not appear in review.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| A derivable value never becomes state | `REACT-PAT-01` | `REACT-STATE-03`, `REACT-EFFECT-04` |
| An expected error is state, not an exception for a boundary | `REACT-ASYNC-09` | `REACT-PAT-07`, `REACT-FORM-03` |
| A Server Function validates and authorizes at the boundary | `REACT-RSC-06` | `REACT-PAT-09`, `REACT-FORM-08` |
| `'use client'` as low as possible | `REACT-RSC-03` | `REACT-PAT-08` |
| Props and state are never mutated | `REACT-PURE-03` | `REACT-STATE-02` |

### Full families in the satellites

`REACT-STATE-*` · `REACT-EFFECT-*` · `REACT-REF-*` · `REACT-PERF-*` · `REACT-ASYNC-*` · `REACT-FORM-*` · `REACT-RSC-*` · `REACT-DOM-*` · `REACT-PAT-*` · `REACT-UTIL-*`

---

## 7. Skill contract

How a React skill should consume this doc.

### What a React skill should load

```
ALWAYS:   react-js.md § 2 (mental model)
          react-js.md § 5 (decision trees)
          react-js.md § 6 + § 6.1 (normative and critical rules)

WHEN WRITING/EDITING components:
          react-rules-of-react.md

ON DEMAND, via § 4 (API map):
          the satellite for the domain the task touches

IN A STRUCTURAL DECISION:
          react-patterns.md

NEVER:    all the satellites at once
```

### How to cite

Review findings cite the rule ID and the satellite, they do not paraphrase:

> `REACT-EFFECT-04` — `useEffect` used to derive state. Calculate in render.
> See [React - Effects and Synchronization](react-effects-and-synchronization.md).

### Invariants the skill must enforce

1. **Verify before asserting.** If an API is not in section 4, it has not been verified in this doc. Consult react.dev and update the note — do not invent behavior.
2. **The source wins.** A divergence between this note and react.dev is a bug in this note.
3. **Rule before style.** A violation of `REACT-PURE-*` or `REACT-HOOK-*` takes precedence over any aesthetic preference.
4. **Do not optimize without measurement.** `memo`, `useMemo` and `useCallback` require evidence of a problem. See `REACT-PERF-*`; what counts as a measurement is [React - Performance Measurement](react-performance-measurement.md).
5. **Prefer the bridge.** When section 8 indicates the stack solves the problem, use the stack instead of React's raw primitive.

### When creating a new React skill

Derive it from a satellite, not from this whole note: a skill focused on forms loads [React - Forms and Actions](react-forms-and-actions.md) + § 2 + § 6, and nothing else. Record at the start of the skill which satellite is its source, so that doc updates propagate.

---

## 8. Bridges to the stack

The body of this doc is pure React, faithful to react.dev. But in my stack (`TanStack Router`, `TanStack Query`, TanStack Start, `Tailwind CSS`, `TypeScript`) several raw React practices are replaced. The satellites mark these points as a *bridge*.

| Problem | Raw React primitive | What to use in the stack |
| --- | --- | --- |
| Fetch remote data | `useEffect` + `useState` | TanStack Query — |
| Data cache and freshness | manual | `staleTime`, invalidation — |
| Optimistic update | `useOptimistic` | the Query's optimistic mutation |
| Navigation and URL state | `useState` + history | TanStack Router — `TanStack Router - Routing Concepts` |
| Mutation on the server | Server Function | always validate at the boundary |
| Global client state | Context | when there are frequent writes |
| Boundary validation | manual | a schema (Zod) at the boundary — [React - Forms and Actions](react-forms-and-actions.md) § 3 |
| Complex form: per-field validation, arrays, wizard | `useState` per field | React Hook Form — [React Hook Form](react-hook-form.md) |

**Criterion — Actions in a Vite SPA.** Separate two things that are often confused:

- **`useActionState` and `<form action>` work in pure React, with no framework** (verified at the source). Only `permalink` requires RSC. They are the recommended way to submit a form even in a Vite SPA: they replace the four `useState`s for pending/error/data.
- **`useOptimistic` is React's answer when the data does not live in a cache.** If the data is in the TanStack Query cache, the optimism belongs to the Query's mutation, with explicit snapshot and rollback. Do not stack the two: they become two diverging sources of truth.

**`useActionState` + `useMutation` together?** Pick one owner for the submission. If the operation invalidates cache, let the Query's mutation be the owner and use a plain `<form>` with a handler. If it is an isolated submission with no cache to invalidate, `useActionState` alone is enough.

---

## Related

- [React - Hooks](react-hooks.md) — API surface per Hook
- [React - Patterns](react-patterns.md) — composition and architecture patterns
- [React - Rules of React](react-rules-of-react.md) — normative basis
- [React - Performance Measurement](react-performance-measurement.md) — baseline, render-count gate, results file (`REACT-PERF-11..19`)
- [React Hook Form](react-hook-form.md) — complex forms; its § 5.4 decides between RHF and native Actions
- `Frontend roadmap` — study track that consumes these notes
- `Next.js` · `TanStack Router` · `Tailwind CSS` · `TypeScript`

## Sources consulted

Verified directly on **2026-08-14**:

- [React Reference Overview](https://react.dev/reference/react)
- [Hooks](https://react.dev/reference/react/hooks) · [Components](https://react.dev/reference/react/components) · [APIs](https://react.dev/reference/react/apis)
- [Rules of React](https://react.dev/reference/rules)
- [react-dom](https://react.dev/reference/react-dom) · [react-dom/server](https://react.dev/reference/react-dom/server) · [react-dom hooks](https://react.dev/reference/react-dom/hooks)
- [Server Components](https://react.dev/reference/rsc/server-components) · [Directives](https://react.dev/reference/rsc/directives)
- [React Compiler Directives](https://react.dev/reference/react-compiler/directives)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)

**Verification notes** — points where the source contradicts what is assumed out of habit:

- `useEffectEvent` appears in the Hooks index as **stable**, with no experimental marking.
- **`forwardRef` is not deprecated yet.** The banner says it "is no longer necessary" and that it "will be deprecated in a future release" — those are different things.
- **React Compiler is stable 1.0 since 2025-10-07** ([announcement](https://react.dev/blog/2025/10/07/react-compiler-1)), compatible with React 17+. The reference's configuration page does not state a status; I had to go to the blog.
- **`useActionState` works without a framework.** Only `permalink` requires RSC.
- **The taint APIs are experimental** (`experimental_taintObjectReference`), and the doc itself warns against treating them as a security mechanism.
- **`startTransition` accepts an `async` function**; the restriction applies only to `setState` after an `await`.
- `renderToString` and `renderToStaticMarkup` are marked as legacy, with limited functionality.

**About review:** this structure went through a reading test with four agents without context (forms, data fetching, state colocation, performance) and a contradiction audit, on 2026-08-14. The corrections applied included: inverting the order of the state tree (the data's origin became the first question), promoting the satellites' critical rules to § 6.1, creating the canonical IDs table, and fixing three wrong ID citations. When editing this doc, repeating the test is cheaper than trusting a re-read.
