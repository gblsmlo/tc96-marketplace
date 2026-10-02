---
titulo: React - State and Reactivity
Link: https://react.dev/reference/react/useState
tags:
  - react
  - state
  - hooks
  - agent-context
source: "Official React documentation — useState, useReducer, useContext, createContext"
verificado-em: 2026-08-14
---

# React — State and Reactivity

> `useState` · `useReducer` · `useContext` · `createContext`
>
> Where state lives and why React re-renders. To decide *whose data it is*, go to [React - Patterns](react-patterns.md) § 2. For signatures, [React - Hooks](react-hooks.md).

Entry point: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Concept: state is a snapshot

State is not a variable you change — it is a **value associated with a position in the tree**, of which each render sees a frozen snapshot.

```tsx
function Counter() {
  const [count, setCount] = useState(0)

  function handleClick() {
    setCount(count + 1)   // count is 0 in this snapshot
    setCount(count + 1)   // still 0 → final result: 1
    console.log(count)    // 0 — it did not change in this run
  }

  return <button onClick={handleClick}>{count}</button>
}
```

The `console.log` prints `0` because `count` is a constant of this render. `setCount` **schedules** a new render; it does not rewrite the variable. Understanding this solves the whole category of "lagging state" bugs at once.

### Updater form

When the next value depends on the previous one, pass a function. React applies the queue of updaters in order over the pending value:

```tsx
setCount((c) => c + 1)   // 0 → 1
setCount((c) => c + 1)   // 1 → 2
```

| ID | Rule |
| --- | --- |
| `REACT-STATE-01` | When the next state depends on the previous one, you **MUST** use the updater form. |
| `REACT-STATE-02` | State is **NEVER** mutated — always a new object/array (`REACT-PURE-03`). |
| `REACT-STATE-03` | State derivable from existing props/state is **NEVER** created (`REACT-PAT-01`). |

### Batching

Multiple `setState` calls in the same interaction produce **one** render. This holds for handlers, Effects and async code. Do not write code that depends on an intermediate render — it does not happen. When you need real synchronization with the DOM, see `flushSync` in [React - Refs and DOM](react-refs-and-dom.md).

### Lazy initialization

```tsx
// WRONG — createInitialState() runs on EVERY render, and the return value is discarded
const [state, setState] = useState(createInitialState(items))

// RIGHT — the function is called only on mount
const [state, setState] = useState(() => createInitialState(items))
```

| ID | Rule |
| --- | --- |
| `REACT-STATE-04` | An expensive initializer **MUST** be passed as a function, not as an already computed value. |

---

## 2. `useState` × `useReducer`

```tsx
const [state, setState] = useState(initialState)
const [state, dispatch] = useReducer(reducer, initialArg, init?)
```

Migrate to `useReducer` when:

- several pieces of state change **together** in the same interaction;
- there are states that **cannot coexist** (`isLoading` and `error` at the same time, for example);
- the transition logic has grown too large to fit readably in the handlers;
- you want to test the transitions without rendering.

```tsx
type State =
  | { status: 'idle' }
  | { status: 'uploading'; sent: number }
  | { status: 'error'; message: string }
  | { status: 'done'; url: string }

type Action =
  | { type: 'start' }
  | { type: 'progress'; sent: number }
  | { type: 'fail'; message: string }
  | { type: 'succeed'; url: string }

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'start':    return { status: 'uploading', sent: 0 }
    case 'progress': return state.status === 'uploading'
                       ? { ...state, sent: action.sent }
                       : state
    case 'fail':     return { status: 'error', message: action.message }
    case 'succeed':  return { status: 'done', url: action.url }
  }
}
```

The real gain is in the **discriminated union**: contradictory states stop being representable, and TypeScript starts demanding that each case be handled. It is the argument of taken to the type.

**The reducer is a pure function** — same inputs, same output, no side effects. `REACT-PURE-01` and `REACT-PURE-02` apply. In `<StrictMode>` it runs twice in development precisely to reveal impurity.

| ID | Rule |
| --- | --- |
| `REACT-STATE-05` | The reducer **MUST** be pure; no request, log or write inside it. |
| `REACT-STATE-06` | Mutually exclusive states **MUST** be modeled as a discriminated union, not as parallel booleans. |

---

## 3. Context

Context solves **one** problem: delivering a value to a subtree without forwarding it through props at every level. It is not a state manager.

### Current API

```tsx
import { createContext, useContext } from 'react'

type Theme = 'light' | 'dark'
const ThemeContext = createContext<Theme>('light')

// React 19: the context itself is the provider
function App() {
  return (
    <ThemeContext value="dark">
      <Page />
    </ThemeContext>
  )
}

function Button() {
  const theme = useContext(ThemeContext)
  return <button className={theme}>OK</button>
}
```

Three version notes verified at the source:

- **Starting with React 19**, `<SomeContext value={...}>` works as a provider. `<SomeContext.Provider>` is still valid and is what you use in earlier versions.
- **`<SomeContext.Consumer>` is the legacy form** — the documentation explicitly recommends `useContext` in new code.
- **The default value of `createContext` is static** and never changes; it is the last resort when there is no provider above.

### The cost

Every consumer re-renders when the provider's `value` changes by identity. An object created inline during render changes identity on every render:

```tsx
// WRONG — new object on every App render: all consumers always re-render
<AuthContext value={{ user, login, logout }}>

// RIGHT — stable identity
const auth = useMemo(() => ({ user, login, logout }), [user, login, logout])
<AuthContext value={auth}>
```

| ID | Rule |
| --- | --- |
| `REACT-STATE-07` | A provider value built inline **MUST** have its identity stabilized when there are expensive consumers. This is an explicit exception to `REACT-PERF-01`: it does not require prior measurement, because the cost is structural. |
| `REACT-STATE-08` | Context is **NEVER** used for frequently written state — use an external store. |

### Context × external store

| Criterion | Context | External store |
| --- | --- | --- |
| Writes | rare (theme, session, locale) | frequent |
| Granularity | the whole subtree re-renders | selection by slice |
| Tree dependency | yes — needs a provider | no |

Rule of thumb: Context for **environmental dependencies**; a store for **state that changes a lot**. For remote data, neither.

---

## 4. Antipatterns

### Derived state

```tsx
// WRONG — two sources of truth, an extra render, guaranteed desync
const [items, setItems] = useState<Item[]>([])
const [total, setTotal] = useState(0)
useEffect(() => setTotal(items.length), [items])

// RIGHT
const [items, setItems] = useState<Item[]>([])
const total = items.length
```

### State mirroring props

```tsx
// WRONG — reads the prop only on mount; later changes are ignored
function Form({ initialName }: { initialName: string }) {
  const [name, setName] = useState(initialName)
}
```

If the intent is an **initial value**, make it explicit in the name (`initialName`) and document it. If the intent is to **reset when the identity changes**, use `key` — see [React - Patterns](react-patterns.md) § 2.

### One `useState` per field in a large object

Five fields that always change together are an object or a reducer, not five Hooks. Five independent fields are five Hooks. The criterion is the coupling of the transitions, not the count.

### Keeping in state what does not redraw

Timer id, observer instance, value from the last render for comparison — none of this should trigger a render. It is `useRef`. See [React - Refs and DOM](react-refs-and-dom.md).

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)

## Sources consulted

Verified on 2026-08-14:

- [useState](https://react.dev/reference/react/useState) · [useReducer](https://react.dev/reference/react/useReducer)
- [useContext](https://react.dev/reference/react/useContext) · [createContext](https://react.dev/reference/react/createContext)
