---
titulo: React - Hooks
Link: https://react.dev/reference/react/hooks
tags:
  - react
  - hooks
  - reference
  - agent-context
source: "Official React documentation — react.dev/reference/react/hooks"
verificado-em: 2026-08-14
---

# React — Hooks

> **API lookup** structure: signature, parameters, return and caveats of each Hook. To decide *which* Hook to use, go to the decision trees in [React.js](react-js.md) § 5. To decide *how to structure* the component around it, go to [React - Patterns](react-patterns.md).

Entry: [React.js](react-js.md) · Normative basis: [React - Rules of React](react-rules-of-react.md)

---

## 1. The three rules that apply to all of them

Before any signature. Violating them breaks the correspondence between calls and internal state, and the result is state swapped between Hooks — not a clear error.

| ID | Rule |
| --- | --- |
| `REACT-HOOK-01` | Call **only at the top level**. Never in a loop, condition, nested function or after an early return. |
| `REACT-HOOK-02` | Call **only** from React components or from other Hooks. Never from a regular function. |
| `REACT-HOOK-03` | `use` is the only exception: it can be called conditionally — and it is an API, not a Hook. |

The reason for `REACT-HOOK-01`: React identifies each Hook by the **order of the call** within the render, not by name. A conditional call shifts the order and the next Hook's state starts being read from the wrong slot.

```tsx
// WRONG — REACT-HOOK-01
function Profile({ userId }: { userId?: string }) {
  if (!userId) return null          // early return before the Hooks
  const [name, setName] = useState('')
  // ...
}

// RIGHT — Hooks at the top, condition afterwards
function Profile({ userId }: { userId?: string }) {
  const [name, setName] = useState('')
  if (!userId) return null
  // ...
}
```

---

## 2. Full index

Signatures as in the official reference. The **Detail** column points to the satellite with examples, good practices and antipatterns.

### State

| Hook | Signature | Detail |
| --- | --- | --- |
| `useState` | `const [state, setState] = useState(initialState)` | [React - State and Reactivity](react-state-and-reactivity.md) |
| `useReducer` | `const [state, dispatch] = useReducer(reducer, initialArg, init?)` | [React - State and Reactivity](react-state-and-reactivity.md) |

### Context

| Hook | Signature | Detail |
| --- | --- | --- |
| `useContext` | `const value = useContext(SomeContext)` | [React - State and Reactivity](react-state-and-reactivity.md) |

### Refs

| Hook | Signature | Detail |
| --- | --- | --- |
| `useRef` | `const ref = useRef(initialValue)` | [React - Refs and DOM](react-refs-and-dom.md) |
| `useImperativeHandle` | `useImperativeHandle(ref, createHandle, dependencies?)` | [React - Refs and DOM](react-refs-and-dom.md) |

### Effects

| Hook | Signature | Detail |
| --- | --- | --- |
| `useEffect` | `useEffect(setup, dependencies?)` | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useLayoutEffect` | `useLayoutEffect(setup, dependencies?)` | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useInsertionEffect` | `useInsertionEffect(setup, dependencies?)` | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| `useEffectEvent` | `const onEvent = useEffectEvent(callback)` | [React - Effects and Synchronization](react-effects-and-synchronization.md) |

### Performance and concurrency

| Hook | Signature | Detail |
| --- | --- | --- |
| `useMemo` | `const cached = useMemo(calculateValue, dependencies)` | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useCallback` | `const cachedFn = useCallback(fn, dependencies)` | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useTransition` | `const [isPending, startTransition] = useTransition()` | [React - Performance and Concurrency](react-performance-and-concurrency.md) |
| `useDeferredValue` | `const deferred = useDeferredValue(value, initialValue?)` | [React - Performance and Concurrency](react-performance-and-concurrency.md) |

### Forms and Actions

| Hook | Signature | Detail |
| --- | --- | --- |
| `useActionState` | `const [state, formAction, isPending] = useActionState(action, initialState, permalink?)` | [React - Forms and Actions](react-forms-and-actions.md) |
| `useOptimistic` | `const [optimistic, setOptimistic] = useOptimistic(value, reducer?)` | [React - Forms and Actions](react-forms-and-actions.md) |
| `useFormStatus` | `const { pending, data, method, action } = useFormStatus()` — from `react-dom` | [React - Forms and Actions](react-forms-and-actions.md) |

### Utilities

| Hook | Signature | Detail |
| --- | --- | --- |
| `useId` | `const id = useId()` | [React - Utility Hooks](react-utility-hooks.md) |
| `useSyncExternalStore` | `const snap = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)` | [React - Utility Hooks](react-utility-hooks.md) |
| `useDebugValue` | `useDebugValue(value, format?)` | [React - Utility Hooks](react-utility-hooks.md) |

> `useFormStatus` is the only Hook exported by `react-dom`, not by `react`. All the others come from `react`.

---

## 3. Quick choice

When the doubt is between two neighboring Hooks. The full trees are in [React.js](react-js.md) § 5.

| Doubt | Tiebreaker |
| --- | --- |
| `useState` × `useReducer` | Independent transitions → `useState`. Several related transitions, or mutually exclusive states → `useReducer`. |
| `useState` × `useRef` | Should a change redraw? → `useState`. Should it not? → `useRef`. |
| `useMemo` × `useCallback` | Cache the **result** → `useMemo`. Cache the **function** → `useCallback`. `useCallback(fn, d)` ≡ `useMemo(() => fn, d)`. |
| `useTransition` × `useDeferredValue` | I control the `setState` → `useTransition`. I only receive the ready value → `useDeferredValue`. |
| `useTransition` × `startTransition` | I need the `isPending` flag → `useTransition`. I am outside a component → `startTransition`. |
| `useEffect` × `useLayoutEffect` | I need to measure layout before paint → `useLayoutEffect` (blocks paint, use sparingly). General case → `useEffect`. |
| `useEffect` × event handler | Does the code respond to a specific interaction? → handler, not Effect. |
| `useContext` × external store | Frequent reads with rare writes → Context. Frequent writes → external store + `useSyncExternalStore` or. |
| `useOptimistic` × optimistic mutation | Does the data live in a query cache? → optimistic mutation, with snapshot and rollback. Does it not? → `useOptimistic`, which works without a framework. Never both on the same data. |

---

## 4. Custom Hooks

A custom Hook is a function whose name starts with `use` and that calls other Hooks. It **shares stateful logic, not the state itself**: two components that use the same custom Hook have independent state instances.

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
    () => true, // server snapshot
  )
}
```

**When to extract.** The vault's criterion is in: the Hook is justified when there is a real synchronization boundary or real repetition. Extracting too early only shifts complexity around.

**Quality rules:**

| ID | Rule |
| --- | --- |
| `REACT-HOOK-04` | The name **MUST** start with `use` and express the **feature's intent**, not the implementation — `useOnlineStatus`, not `useEventListener`. |
| `REACT-HOOK-05` | Pure, stateless logic **NEVER** becomes a Hook — it is a regular function, testable without rendering. |
| `REACT-HOOK-06` | The return **MUST** be small and explicit. A Hook that returns ten things is hiding a component. |
| `REACT-HOOK-07` | A custom Hook **MUST** obey `REACT-HOOK-01` internally — it inherits all the restrictions of the Hooks it calls. |

---

## 5. Antipatterns

### Adjusting dependencies to silence the linter

```tsx
// WRONG — the list lies about what the Effect reads
useEffect(() => {
  setFiltered(items.filter((i) => i.status === status))
}, [items]) // eslint disabled, `status` omitted

// RIGHT — it is not an Effect. It is derived state.
const filtered = items.filter((i) => i.status === status)
```

The dependency array **describes** what the Effect reads; it is not a control for when to run. If removing a dependency "fixes" a loop, the Effect is the problem..

### State mirroring props

```tsx
// WRONG — goes out of sync on the first prop change
function Total({ items }: { items: Item[] }) {
  const [total, setTotal] = useState(0)
  useEffect(() => setTotal(items.length), [items])
  return <span>{total}</span>
}

// RIGHT
function Total({ items }: { items: Item[] }) {
  return <span>{items.length}</span>
}
```

### `useCallback` / `useMemo` by reflex

Wrapping everything in `useCallback` is not optimization: it adds dependency-comparison cost and noise, and only has an effect if the consumer is `memo` or if the value is a dependency of another Hook. It requires measurement. See `REACT-PERF-*` in [React - Performance and Concurrency](react-performance-and-concurrency.md) — and check first whether the React Compiler already covers the case.

### Hook called conditionally behind an abstraction

```tsx
// WRONG — violates REACT-HOOK-01 even indirectly
const value = condition ? useA() : useB()

// RIGHT — call both, choose afterwards
const a = useA()
const b = useB()
const value = condition ? a : b
```

---

## Related

- [React.js](react-js.md) — hub and decision trees
- [React - Patterns](react-patterns.md) — composition and architecture patterns
- [React - Rules of React](react-rules-of-react.md) — full normative basis

## Sources consulted

Verified on 2026-08-14:

- [Built-in React Hooks](https://react.dev/reference/react/hooks)
- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
- [react-dom Hooks](https://react.dev/reference/react-dom/hooks)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)
