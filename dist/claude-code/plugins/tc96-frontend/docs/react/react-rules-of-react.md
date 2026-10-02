---
titulo: React - Rules of React
Link: https://react.dev/reference/rules
tags:
  - react
  - rules
  - reference
  - agent-context
source: "Official React documentation — react.dev/reference/rules"
verificado-em: 2026-08-14
---
# React — Rules of React

> The normative base. Everything else in the doc derives from here. An agent that writes or modifies components **must** have this note loaded.

Entry point: [React.js](react-js.md) · API lookup: [React - Hooks](react-hooks.md) · Structural decision: [React - Patterns](react-patterns.md)

---

## 1. Why they exist

React does not just promise to render — it promises to render **when and as many times as it deems necessary**: pause work, discard unfinished renders, repeat a render in development to reveal bugs, reorder updates by priority. None of that is safe if a component changes the world when it runs.

The rules are not style. They are the **contract** that lets React do that work. Breaking one does not produce an immediate, clear error — it produces erratic behavior: stale values, a duplicated render with a duplicated side effect, state showing up in the wrong component.

Direct consequence: the React Compiler can only memoize code that follows the rules. **Code outside the rules is not just risky — it is ineligible for the automatic optimizations.** It is the most practical argument for following them.

---

## 2. Components and Hooks must be pure

Source: [Components and Hooks must be pure](https://react.dev/reference/rules/components-and-hooks-must-be-pure).

### `REACT-PURE-01` — idempotency

> "React components are assumed to always return the same output with respect to their inputs – props, state, and context."

The same inputs produce the same output. That excludes from render: `Date.now()`, `Math.random()`, reading `window` without a guard, external counters, `fetch`.

```tsx
// WRONG — output changes on every render without anything having changed
function Clock() {
  return <span>{new Date().toLocaleTimeString()}</span>
}

// RIGHT — time is state, updated by external synchronization
function Clock() {
  const [now, setNow] = useState(() => new Date())
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(id)
  }, [])
  return <span>{now.toLocaleTimeString()}</span>
}
```

### `REACT-PURE-02` — side effects outside render

> "Side effects should not run in render, as React can render components multiple times to create the best possible user experience."

Where they belong, in order of preference:

1. **Event handler** — if it responds to a specific interaction. That is where most of them go.
2. **Effect** — if it synchronizes with an external system.
3. **Nowhere** — if the value was derivable.

**Two exceptions authorized by the documentation itself**, and only these:

- **Preloading APIs** (`preload`, `preconnect`, `preinit`…) may be called during render — they are idempotent and exist precisely to get the network ahead at the moment React knows what is coming. See [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) § 4.
- **`async`/`await` in the render of a Server Component** is legitimate, because there is no concurrent re-render on the server side. It does not apply to Client Components. See [React - Server Components and Directives](react-server-components-and-directives.md) § 1.

```tsx
// WRONG — write during render
function Cart({ items }: { items: Item[] }) {
  localStorage.setItem('count', String(items.length))
  return <span>{items.length}</span>
}

// RIGHT — synchronization is an Effect
function Cart({ items }: { items: Item[] }) {
  useEffect(() => {
    localStorage.setItem('count', String(items.length))
  }, [items.length])
  return <span>{items.length}</span>
}
```

> **Bridge:** for real persistence in the browser — the example above is didactic, not a production pattern.

### `REACT-PURE-03` — props and state are immutable

> "A component's props and state are immutable snapshots with respect to a single render. Never mutate them directly."

```tsx
// WRONG — mutation; React does not detect it and the UI does not update
items.push(newItem)
setItems(items)

// RIGHT — new value
setItems([...items, newItem])
```

The subtle point: within a render, state is a **frozen snapshot**. `setState` does not change the current variable — it schedules a new render. That is why the updater form exists:

```tsx
// Increments ONCE: both read the same snapshot
setCount(count + 1)
setCount(count + 1)

// Increments TWICE: each updater receives the pending value
setCount((c) => c + 1)
setCount((c) => c + 1)
```

### `REACT-PURE-04` — Hook arguments and return values are immutable

> "Once values are passed to a Hook, you should not modify them. Like props in JSX, values become immutable when passed to a Hook."

An object passed to `useState`, `useMemo` or a custom Hook belongs to React from then on. Mutating it later hides the change from the reconciliation system.

### `REACT-PURE-05` — values are immutable after being passed to JSX

> "Don't mutate values after they've been used in JSX. Move the mutation before the JSX is created."

```tsx
// WRONG
const element = <Row item={item} />
item.selected = true

// RIGHT — mutation before the JSX exists, or better: a new object
const next = { ...item, selected: true }
const element = <Row item={next} />
```

### Where mutation is legitimate

**Local** mutation — of an object created inside the render itself and not yet exposed — is allowed and idiomatic:

```tsx
function List({ items }: { items: Item[] }) {
  const rows = []                 // created here, nobody else sees it
  for (const item of items) rows.push(<Row key={item.id} item={item} />)
  return <ul>{rows}</ul>
}
```

---

## 3. React is the one that calls components and Hooks

Source: [React calls Components and Hooks](https://react.dev/reference/rules/react-calls-components-and-hooks).

### `REACT-CALL-01` — never call a component as a function

> "Components should only be used in JSX. Don't call them as regular functions."

```tsx
// WRONG — becomes part of the parent's render: no state of its own,
// no Hooks of its own, no position in the tree, no reconciliation.
function Page() {
  return <div>{Header({ title: 'Profile' })}</div>
}

// RIGHT
function Page() {
  return <div><Header title="Profile" /></div>
}
```

Calling it directly is not "an equivalent shortcut": the called component's Hooks start counting as the caller's Hooks, which breaks `REACT-HOOK-01` at the first conditional.

### `REACT-CALL-02` — Hooks are not values

> "Hooks should only be called inside of components. Never pass it around as a regular value."

```tsx
// WRONG — Hook as an argument, called dynamically
function useData(hook: () => Data) {
  return hook()
}

// RIGHT — call Hooks directly and compose the result
function useData() {
  const a = useA()
  const b = useB()
  return { a, b }
}
```

This also applies to Hooks inside objects, arrays or rendered dynamically by lookup.

---

## 4. Rules of Hooks

Source: [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks). Details and examples in [React - Hooks](react-hooks.md).

### `REACT-HOOK-01` — only at the top level

> "Don't call Hooks inside loops, conditions, or nested functions. Instead, always use Hooks at the top level of your React function, before any early returns."

**Before any early return** is the part that slips most in generated code.

### `REACT-HOOK-02` — only from React functions

> "Don't call Hooks from regular JavaScript functions."

Valid: components and custom Hooks. Invalid: utility functions, handlers defined outside the component, `map` callbacks that are not components.

### `REACT-HOOK-03` — the `use` exception

`use` is an **API**, not a Hook, and can be called conditionally and inside blocks. It still holds that it can only be called from inside a component or Hook. See [React - Suspense and Async](react-suspense-and-async.md).

---

## 5. Review checklist

Order of checks when reviewing a component. The first ones fail most.

- [ ] Any Hook after an early return, inside an `if`, loop or callback? → `REACT-HOOK-01`
- [ ] `fetch`, `localStorage`, `Date.now()`, `Math.random()` or a log in the render body? → `REACT-PURE-01` / `REACT-PURE-02`
- [ ] `.push`, `.sort`, `.splice` or direct assignment on props/state? → `REACT-PURE-03`
- [ ] `setState(x + 1)` where it should be `setState(c => c + 1)`? → `REACT-STATE-01` (it is not mutation: it is reading a stale snapshot)
- [ ] Component invoked as `Component(props)` instead of `<Component />`? → `REACT-CALL-01`
- [ ] Hook stored in a variable, object or passed as an argument? → `REACT-CALL-02`
- [ ] Hook called from a function that is neither a component nor a Hook? → `REACT-HOOK-02`
- [ ] `eslint-disable` on `react-hooks/exhaustive-deps`? → almost always indicates an Effect that should not exist

**Tool:** `eslint-plugin-react-hooks` covers most of `REACT-HOOK-*` and part of `REACT-CALL-*` automatically. `<StrictMode>` reveals purity violations in development by rendering and running Effects twice — see [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md).

---

## 6. Use by an agent

When generating React, check the checklist in § 5 **before** delivering. When reviewing, cite the ID:

> `REACT-PURE-02` — `localStorage.setItem` in the render body. Move it to an Effect or to the handler that causes the change.

A violation of these rules takes **precedence over any style or organization preference**. Do not negotiate a purity break in the name of conciseness.

---

## Related

- [React.js](react-js.md) — hub, API map and decision trees
- [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md)

## Sources consulted

Verified on 2026-08-14, with the rules quoted literally:

- [Rules of React](https://react.dev/reference/rules)
- [Components and Hooks must be pure](https://react.dev/reference/rules/components-and-hooks-must-be-pure)
- [React calls Components and Hooks](https://react.dev/reference/rules/react-calls-components-and-hooks)
- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
