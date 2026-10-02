---
titulo: React - Effects and Synchronization
Link: https://react.dev/reference/react/useEffect
tags:
  - react
  - effects
  - hooks
  - agent-context
source: "Official React documentation — useEffect, useLayoutEffect, useInsertionEffect, useEffectEvent"
verificado-em: 2026-08-14
---

# React — Effects and Synchronization

> `useEffect` · `useLayoutEffect` · `useInsertionEffect` · `useEffectEvent`
>
> The most important satellite for reviewing AI-generated code: **most `useEffect` calls an agent writes should not exist.**

Entry: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Concept: an Effect is synchronization, not "code that runs afterwards"

An Effect exists to **synchronize React with an external system** — something that lives outside the component tree: a connection, a browser subscription, a timer, an unmanaged DOM node, a third-party library.

It is not a lifecycle hook. It is not "where to put code that needs to run after render". Rephrasing the question changes the answer:

> ❌ "When should this run?"
> ✅ "What external system does this keep in sync, and how is that synchronization undone?"

If the second question has no answer, it is not an Effect.

### The cycle is synchronize / desynchronize

An Effect has no "mount" and "unmount" — it has **start synchronizing** and **stop synchronizing**. Cleanup is not optional, and it is not only for unmount: it runs before every re-run too.

```tsx
useEffect(() => {
  const connection = createConnection(serverUrl, roomId)
  connection.connect()
  return () => connection.disconnect()   // undoes exactly what the setup did
}, [serverUrl, roomId])
```

When `roomId` changes: React disconnects from the old room and connects to the new one. The same code covers mount, update and unmount — because it describes synchronization, not lifecycle events.

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-01` | Every Effect that creates a subscription, connection, timer, listener **or in-flight request** **MUST** return a cleanup that undoes exactly the setup. |

### The Effect callback is never `async`

```tsx
// WRONG — the async function returns a Promise, and React interprets
// that return value as if it were the cleanup function
useEffect(async () => {
  const data = await load()
  setData(data)
}, [])

// RIGHT — async inside, real cleanup outside
useEffect(() => {
  let active = true
  load().then((data) => { if (active) setData(data) })
  return () => { active = false }
}, [])
```

React expects the setup to return **a cleanup function or nothing**. An `async` function always returns a Promise, so the cleanup silently disappears — no error, no warning.

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-12` | The `useEffect` callback is **NEVER** `async` — declare the async function inside it. |

### Why `<StrictMode>` runs the Effect twice

In development, React mounts, unmounts and remounts every component to check that the cleanup really undoes the setup. If something breaks with the double run, the cleanup is incomplete — **it is the bug being revealed, not a React bug**. The fix is never to suppress the behavior.

---

## 2. The dependency array

It **describes** what the Effect reads. It is not a "when to run" selector.

Every reactive value (props, state, and anything derived from them) used inside the Effect **must** be in the list. The `react-hooks/exhaustive-deps` linter computes this correctly; disagreeing with it is almost always being wrong.

| List | Meaning |
| --- | --- |
| omitted | runs after every render |
| `[]` | runs on mount and on the unmount cleanup |
| `[a, b]` | re-synchronizes when `a` or `b` change by identity |

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-02` | Dependencies **MUST** list every reactive value read by the Effect. |
| `REACT-EFFECT-03` | `eslint-disable` on `exhaustive-deps` is **NEVER** the fix — it is a sign the Effect is wrong. |

### How to really remove a dependency

Do not delete it from the list. Make the value stop being read:

| Situation | Fix |
| --- | --- |
| Object/function recreated on every render | move it outside the component, or inside the Effect |
| Only needs the previous state value | updater form: `setX(x => ...)` |
| Value read but **must not** re-synchronize | `useEffectEvent` (§ 4) |
| It is derived state | not an Effect — compute it during render |

---

## 3. When **not** to use an Effect

The table that fixes the most generated code.

| Intent | ❌ Effect | ✅ Correct |
| --- | --- | --- |
| Derive a value from props/state | `useEffect(() => setB(f(a)), [a])` | `const b = f(a)` during render |
| Expensive calculation | Effect + state | `useMemo(() => f(a), [a])` |
| Reset state when switching items | Effect comparing props | `key` on the component |
| Adjust state when a prop changes | Effect | compute during render, or rethink ownership |
| Respond to a click/submit | Effect watching state | event handler |
| Fetch data | `useEffect` + `fetch` | TanStack Query |
| Notify the parent of a change | Effect calling `onChange` | call it in the handler that caused it |

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-04` | An Effect **NEVER** derives state from other state or a prop. |
| `REACT-EFFECT-05` | Logic that responds to a specific interaction **MUST** live in the event handler. |

### Data fetching: why it is the worst case

```tsx
// WRONG — no cancellation, no cache, no dedupe, with a race condition
useEffect(() => {
  fetch(`/api/users/${id}`)
    .then((r) => r.json())
    .then(setUser)
}, [id])
```

If `id` changes quickly, the response to the first request can arrive **after** the second and overwrite the correct data. The acceptable minimum is to ignore stale responses:

```tsx
useEffect(() => {
  let active = true
  fetch(`/api/users/${id}`)
    .then((r) => r.json())
    .then((data) => { if (active) setUser(data) })
  return () => { active = false }
}, [id])
```

With `AbortController`, the stale request is actually cancelled, not just ignored:

```tsx
useEffect(() => {
  const controller = new AbortController()

  fetch(`/api/users/${id}`, { signal: controller.signal })
    .then((r) => r.json())
    .then(setUser)
    .catch((err) => {
      if (err.name === 'AbortError') return   // cancellation is not an error
      setError(err)
    })

  return () => controller.abort()
}, [id])
```

The `catch` has to filter `AbortError` explicitly — otherwise every cleanup becomes an error on screen.

Even fixed, it still has no cache, no revalidation, no dedupe and no retry. **Bridge:** in my stack this is TanStack Query — and.

### "My fetch fires twice in dev"

It is `<StrictMode>` doing what it should: mounting, unmounting and remounting to check the cleanup. With `AbortController` or a flag in the cleanup, the duplicate is harmless. **Without cleanup, the double run is the warning that a race condition is waiting for a real user.** Do not remove StrictMode — see [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md) § 3.

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-06` | Fetch in `useEffect` **NEVER** goes into new code. If it is unavoidable, it **MUST** handle the race condition with a flag or `AbortController`. |

**What counts as "unavoidable"** — without a criterion, the rule becomes negotiable in a PR. Accept only: (a) the project does not have and will not adopt a data fetching library, a decision already made and recorded; (b) it is a one-off call, with no cache, no revalidation and no other consumer of the same data — telemetry, health check, warm-up. Outside that, "it would be a lot of work to migrate" is not unavoidability. For legacy code that already works, the rule does not force a refactor: it forbids repeating it, and requires fixing the race condition if the Effect is touched.

---

## 4. `useEffectEvent`

```tsx
const onEvent = useEffectEvent(callback)
```

It solves one specific conflict: the Effect needs to **read** a value, but changes to that value **must not** re-synchronize.

```tsx
function ChatRoom({ roomId, theme }: { roomId: string; theme: Theme }) {
  const onConnected = useEffectEvent(() => {
    showNotification('Connected!', theme)   // always reads the latest theme
  })

  useEffect(() => {
    const connection = createConnection(roomId)
    connection.on('connected', () => onConnected())
    connection.connect()
    return () => connection.disconnect()
  }, [roomId])   // theme left out of the list, correctly
}
```

Without `useEffectEvent`, including `theme` would reconnect the chat on every theme change; omitting `theme` would show the notification with the old theme. The Effect Event always reads the latest values from the render and is **excluded from dependencies by definition**.

### Restrictions (quoted from the source)

> "you can only call it **at the top level of your component** or your own Hooks. You can't call it inside loops or conditions."

> "Effect Events can only be called from inside Effects or other Effect Events. Do not call them during rendering or pass them to other components or Hooks."

> "Effect Event functions do not have a stable identity. Their identity intentionally changes on every render."

And the warning that matters most:

> "Do not use `useEffectEvent` to avoid specifying dependencies in your Effect's dependency array. This hides bugs and makes your code harder to understand. Only use it for logic that is genuinely an event fired from Effects."

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-07` | An Effect Event is **NEVER** called during render, nor passed as a prop to another component or Hook. |
| `REACT-EFFECT-08` | An Effect Event **NEVER** goes into the dependency array. |
| `REACT-EFFECT-09` | `useEffectEvent` is **NEVER** used to silence the linter — only for logic that is genuinely an event fired by an Effect. |

`eslint-plugin-react-hooks` enforces these restrictions.

---

## 5. The three variants

| Hook | When it runs | Use when |
| --- | --- | --- |
| `useEffect` | after paint, without blocking | **general case** |
| `useLayoutEffect` | after commit, **before** paint | you need to measure layout and adjust before the user sees it |
| `useInsertionEffect` | before React touches the DOM | **only CSS-in-JS libraries** injecting `<style>` |

```tsx
// Legitimate useLayoutEffect case: measure to position without flicker
useLayoutEffect(() => {
  const { height } = ref.current!.getBoundingClientRect()
  setTooltipHeight(height)
}, [])
```

`useLayoutEffect` **blocks paint**. Using it out of habit degrades visible performance. `useInsertionEffect` should not appear in application code — there is no access to refs, and updates cannot be scheduled from it.

| ID | Rule |
| --- | --- |
| `REACT-EFFECT-10` | `useLayoutEffect` **MUST** be justified by measuring layout before paint. |
| `REACT-EFFECT-11` | `useInsertionEffect` **NEVER** appears in application code. |

---

## 6. Review checklist

- [ ] Is there a real external system? If not → the Effect should not exist
- [ ] Does setup with a subscription/timer/listener have a symmetric cleanup? → `REACT-EFFECT-01`
- [ ] Are all reactive dependencies listed, with no `eslint-disable`? → `REACT-EFFECT-02/03`
- [ ] Does the Effect call `setState` with a value derived from props/state? → `REACT-EFFECT-04`
- [ ] Is there a `fetch` inside? → `REACT-EFFECT-06`
- [ ] `useLayoutEffect` without layout measurement? → `REACT-EFFECT-10`
- [ ] Effect Event called outside an Effect or passed along? → `REACT-EFFECT-07`

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)

## Sources consulted

Verified on 2026-08-14:

- [useEffect](https://react.dev/reference/react/useEffect) · [useLayoutEffect](https://react.dev/reference/react/useLayoutEffect) · [useInsertionEffect](https://react.dev/reference/react/useInsertionEffect)
- [useEffectEvent](https://react.dev/reference/react/useEffectEvent) — confirmed as stable, with no experimental marking
- [Rules of React](https://react.dev/reference/rules)
