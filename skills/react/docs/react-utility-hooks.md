---
titulo: React - Utility Hooks
Link: https://react.dev/reference/react/useId
tags:
  - react
  - hooks
  - agent-context
source: "Official React documentation — useId, useSyncExternalStore, useDebugValue"
verificado-em: 2026-08-14
---

# React — Utility Hooks

> `useId` · `useSyncExternalStore` · `useDebugValue`
>
> Three Hooks for occasional use. Each one solves a specific problem and is often used for the wrong thing.

Entry: [React.js](react-js.md) · Normative basis: [React - Hooks](react-hooks.md)

---

## 1. `useId`

```tsx
const id = useId()
```

Generates a unique ID that is **stable between server and client** — that is what sets it apart from any homemade generator.

```tsx
function PasswordField() {
  const id = useId()
  return (
    <>
      <label htmlFor={`${id}-password`}>Password</label>
      <input id={`${id}-password`} type="password" aria-describedby={`${id}-hint`} />
      <p id={`${id}-hint`}>Minimum of 12 characters.</p>
    </>
  )
}
```

A global counter or `Math.random()` would produce different values on the server and on the client, causing a hydration error — see [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) § 1. `useId` is generated from the **component's position in the tree**, so it is the same on both sides.

**One `useId` per component, with suffixes**, is the recommended pattern when there are several related elements — as in the example above. Calling the Hook several times works, but is unnecessary.

| ID | Rule |
| --- | --- |
| `REACT-UTIL-01` | Accessibility IDs (`htmlFor`, `aria-describedby`, `aria-labelledby`) **MUST** come from `useId`, not from a counter or random. |
| `REACT-UTIL-02` | `useId` is **NEVER** used as a list `key` — the key must come from the data's identity. |

`REACT-UTIL-02` is the most common mistake with this Hook. `key` identifies **which piece of data** that item is across renders; `useId` identifies a **position in the tree**. Using `useId` as a key does not solve the problem the key exists to solve. See [React - Patterns](react-patterns.md) § 8.

---

## 2. `useSyncExternalStore`

```tsx
const snapshot = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)
```

Subscribes to a store **outside** React safely under concurrent rendering.

| Parameter | What it is |
| --- | --- |
| `subscribe` | receives a callback, registers the listener and **returns the unsubscribe function** |
| `getSnapshot` | returns the store's current value |
| `getServerSnapshot?` | value used in SSR and in the initial hydration |

```tsx
function useWindowWidth() {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('resize', callback)
      return () => window.removeEventListener('resize', callback)
    },
    () => window.innerWidth,
    () => 1024,   // no window on the server
  )
}
```

### The problem it solves

The naive alternative — `useEffect` + `useState` — allows **tearing**: during an interruptible concurrent render, parts of the tree can read different values from the same store in the same frame. `useSyncExternalStore` guarantees consistency.

### The central trap

**`getSnapshot` must return a value with stable identity as long as nothing changes.** Returning a new object on every call causes an infinite render loop.

```tsx
// WRONG — new object on every call → infinite loop
() => ({ width: window.innerWidth, height: window.innerHeight })

// RIGHT — primitive value
() => window.innerWidth

// RIGHT — object cached in the store, with a new identity only when it changes
() => store.getCachedState()
```

| ID | Rule |
| --- | --- |
| `REACT-UTIL-03` | `getSnapshot` **MUST** return an immutable value with stable identity as long as the store does not change. |
| `REACT-UTIL-04` | `subscribe` **MUST** have a stable identity — define it outside the component or memoize it, or React resubscribes on every render. |
| `REACT-UTIL-05` | In an app with SSR, `getServerSnapshot` **MUST** be provided, without accessing browser APIs. |

### When you need it

Almost never directly. State libraries (Redux) already use it internally. Use it by hand for browser APIs (`navigator.onLine`, `matchMedia`, `localStorage`) or a small store of your own.

For remote data, it is not the tool.

---

## 3. `useDebugValue`

```tsx
useDebugValue(value, format?)
```

The custom Hook's label in React DevTools. That is all.

```tsx
function useOnlineStatus() {
  const online = useSyncExternalStore(subscribe, () => navigator.onLine, () => true)
  useDebugValue(online ? 'Online' : 'Offline')
  return online
}
```

The second parameter defers formatting — the function only runs when the Hook is inspected in DevTools, avoiding the cost on every render:

```tsx
useDebugValue(date, (d) => d.toISOString())
```

| ID | Rule |
| --- | --- |
| `REACT-UTIL-06` | `useDebugValue` **MUST** appear only in shared custom Hooks; in a Hook used in a single place it is noise. |
| `REACT-UTIL-07` | Costly formatting **MUST** go in the second parameter, not computed inline. |

It does not affect behavior in production and does not replace logging or tests.

---

## 4. Antipatterns

| Antipattern | Fix |
| --- | --- |
| `useId` as a list `key` | domain id · `REACT-UTIL-02` |
| Accessibility ID from a global counter | `useId` · `REACT-UTIL-01` |
| `getSnapshot` returning a new object | primitive or cached value · `REACT-UTIL-03` |
| `subscribe` recreated on every render | define it outside the component · `REACT-UTIL-04` |
| `useSyncExternalStore` for remote data | TanStack Query |
| `useEffect` + `useState` to subscribe to a store | `useSyncExternalStore` (avoids tearing) |
| `useDebugValue` in every Hook | only in shared Hooks · `REACT-UTIL-06` |

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - State and Reactivity](react-state-and-reactivity.md) · [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md)

## Sources consulted

Verified on 2026-08-14:

- [useId](https://react.dev/reference/react/useId)
- [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore)
- [useDebugValue](https://react.dev/reference/react/useDebugValue)
