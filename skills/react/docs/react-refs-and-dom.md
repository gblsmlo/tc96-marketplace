---
titulo: React - Refs and DOM
Link: https://react.dev/reference/react/useRef
tags:
  - react
  - refs
  - dom
  - agent-context
source: "Official React documentation — useRef, useImperativeHandle, createPortal, flushSync"
verificado-em: 2026-08-14
---

# React — Refs and DOM

> `useRef` · `useImperativeHandle` · `ref` as a prop · `createPortal` · `flushSync`
>
> The emergency exit from the declarative model. Each API here exists for a case React cannot express declaratively — and each one is overused by generated code.

Entry point: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. `useRef`: memory that does not redraw

```tsx
const ref = useRef(initialValue)   // { current: initialValue }
```

A ref is a mutable box that **survives across renders and does not trigger a render** when it changes. Two uses:

**A. A value that does not belong to the UI**

```tsx
const timeoutRef = useRef<number | null>(null)

function start() {
  timeoutRef.current = window.setTimeout(() => { /* ... */ }, 1000)
}
function stop() {
  if (timeoutRef.current !== null) clearTimeout(timeoutRef.current)
}
```

Timer id, observer instance, request controller, retry counter, previous value for comparison. None of these should redraw anything.

**B. A reference to a DOM node**

```tsx
const inputRef = useRef<HTMLInputElement>(null)

function focus() {
  inputRef.current?.focus()
}

return <input ref={inputRef} />
```

### `useState` × `useRef`

| | `useState` | `useRef` |
| --- | --- | --- |
| Change triggers a render | yes | **no** |
| Readable during render | yes | **should not be** |
| Immutable during render | yes (snapshot) | no (mutable) |

| ID | Rule |
| --- | --- |
| `REACT-REF-01` | `ref.current` is **NEVER** read or written during render (violates `REACT-PURE-02`). Only in handlers and Effects. |
| `REACT-REF-02` | If changing the value should update the UI, it **MUST** be state, not a ref. |

The exception to `REACT-REF-01` is lazy, idempotent initialization on the first run — but prefer `useState` with an initializer when possible.

---

## 2. `ref` as a prop (React 19)

Verified at the source — and the distinction matters: `forwardRef` is **not deprecated yet**; it stopped being necessary and will be deprecated in the future. It is still exported and working, with no warning.

> "In React 19, `forwardRef` is no longer necessary. Pass `ref` as a prop instead. `forwardRef` will be deprecated in a future release."

In other words: existing code with `forwardRef` is not broken and does not require urgent migration. `REACT-REF-03` below is a policy for **new** code, not a bug fix.

```tsx
// React 19 — ref is a regular prop
type InputProps = React.ComponentPropsWithRef<'input'> & { label: string }

function TextField({ label, ref, ...props }: InputProps) {
  return (
    <label>
      {label}
      <input ref={ref} {...props} />
    </label>
  )
}

// Usage
<TextField label="Name" ref={inputRef} />
```

| ID | Rule |
| --- | --- |
| `REACT-REF-03` | New code **NEVER** uses `forwardRef`; `ref` is a prop. |

### Ref callback with cleanup

Also new in React 19: the ref callback can **return a cleanup function**.

```tsx
<div ref={(node) => {
  const observer = new ResizeObserver(handleResize)
  if (node) observer.observe(node)
  return () => observer.disconnect()   // called on detach
}} />
```

From the documentation, on the legacy behavior:

> "To support backwards compatibility, if a cleanup function is not returned from the `ref` callback, `node` will be called with `null` when the `ref` is detached. This behavior will be removed in a future version."

In other words: **returning cleanup is the correct form now**; the call with `null` is compatibility on its way out.

| ID | Rule |
| --- | --- |
| `REACT-REF-04` | A ref callback that registers an observer/listener **MUST** return cleanup instead of relying on the call with `null`. |

---

## 3. `useImperativeHandle`

```tsx
useImperativeHandle(ref, createHandle, dependencies?)
```

Restricts what a component's ref exposes. The documentation itself classifies it as **rare**.

```tsx
function VideoPlayer({ ref, src }: { ref: React.Ref<VideoHandle>; src: string }) {
  const videoRef = useRef<HTMLVideoElement>(null)

  useImperativeHandle(ref, () => ({
    play:  () => videoRef.current?.play(),
    pause: () => videoRef.current?.pause(),
  }), [])

  return <video ref={videoRef} src={src} />
}
```

Legitimate when the imperative surface needs to be **deliberately smaller** than the DOM node — here the consumer cannot change `currentTime`, `volume` or the `src`.

| ID | Rule |
| --- | --- |
| `REACT-REF-05` | `useImperativeHandle` **MUST** be justified by an intentional restriction of the API; exposing the whole node is a normal ref. |
| `REACT-REF-06` | An imperative handle **NEVER** replaces props for what is expressible declaratively. |

The frequent antipattern: exposing `setValue`, `setError`, `reset` through an imperative handle instead of controlling through props. That creates a second source of truth outside the one-way flow.

---

## 4. `createPortal`

```tsx
import { createPortal } from 'react-dom'

createPortal(children, domNode, key?)
```

Renders children at another point in the **DOM**, while keeping them at the same point in the **React tree**. For modals, tooltips and popovers that need to escape `overflow: hidden` or a stacking context's `z-index`.

```tsx
function Modal({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return createPortal(
    <div className="backdrop" onClick={onClose}>
      <div className="dialog" onClick={(e) => e.stopPropagation()}>{children}</div>
    </div>,
    document.body,
  )
}
```

**The misleading consequence:** events keep propagating through the **React** tree, not the DOM one. A click inside the portal fires the handlers of React ancestors even though it is in `document.body`.

| ID | Rule |
| --- | --- |
| `REACT-REF-07` | A portal **NEVER** waives accessibility: trapped focus, `Esc` to close, `role`/`aria-modal` and returning focus remain your responsibility. |

In practice, use a ready accessible primitive (Radix, the base of shadcn) instead of building the modal from scratch — `createPortal` is the mechanism, not the complete solution.

---

## 5. `flushSync`

```tsx
import { flushSync } from 'react-dom'

flushSync(() => setItems([...items, newItem]))
listRef.current?.scrollTo({ top: listRef.current.scrollHeight })
```

Forces React to process the update and apply the DOM **synchronously**, leaving batching. Without it, the `scrollTo` above would run before the new item exists in the DOM.

It hurts performance and disables concurrency optimizations. Legitimate only when you need to read the DOM right after an update.

| ID | Rule |
| --- | --- |
| `REACT-REF-08` | `flushSync` **MUST** be a last resort, justified by reading the DOM immediately after an update. |

---

## 6. Antipatterns

| Antipattern | Fix |
| --- | --- |
| Reading `ref.current` during render | move it to a handler/Effect · `REACT-REF-01` |
| A ref to avoid re-rendering a value the UI shows | it is state · `REACT-REF-02` |
| `forwardRef` in new code | `ref` as a prop · `REACT-REF-03` |
| An imperative handle for what props solve | props · `REACT-REF-06` |
| Manipulating DOM managed by React (`innerHTML`, `remove()`) | let React reconcile |
| `flushSync` to "guarantee" state order | updater form / rethink the flow |
| A modal with `createPortal` without focus and `Esc` | accessible primitive · `REACT-REF-07` |

The fifth deserves a note: changing through a ref a node that React manages puts the real tree out of sync with the virtual one, and the next render may revert or break it. Direct manipulation is only safe on nodes React does **not** render.

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - State and Reactivity](react-state-and-reactivity.md) — the state × ref decision

## Sources consulted

Verified on 2026-08-14:

- [useRef](https://react.dev/reference/react/useRef) · [useImperativeHandle](https://react.dev/reference/react/useImperativeHandle)
- [forwardRef](https://react.dev/reference/react/forwardRef) — deprecation banner quoted literally
- [Common components — ref callback](https://react.dev/reference/react-dom/components/common) — ref callback cleanup quoted literally
- [createPortal](https://react.dev/reference/react-dom/createPortal) · [flushSync](https://react.dev/reference/react-dom/flushSync)
