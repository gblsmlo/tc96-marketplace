---
titulo: React - Suspense and Async
Link: https://react.dev/reference/react/Suspense
tags:
  - react
  - suspense
  - async
  - agent-context
source: "Official React documentation — Suspense, lazy, use"
verificado-em: 2026-08-14
---

# React — Suspense and Async

> `<Suspense>` · `lazy` · `use` · Error Boundaries
>
> How React expresses "this is not ready yet" and "this failed" declaratively, without scattering `isLoading` and `error` across the whole tree.

Entry: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Concept: waiting as a position in the tree

The imperative model scatters loading state per component:

```tsx
if (isLoading) return <Spinner />
if (error) return <Error />
return <Content />
```

Suspense inverts this: the component **declares what it needs** and **suspends** if it is not available yet. The fallback is chosen by the nearest `<Suspense>` ancestor.

```tsx
<Suspense fallback={<ProfileSkeleton />}>
  <Profile userId={userId} />
</Suspense>
```

The design consequence is what matters: **where you place the boundary defines what disappears from the screen while waiting.**

```tsx
// One boundary at the root: the whole page becomes a skeleton because of one slow comment
<Suspense fallback={<PageSkeleton />}>
  <Header /><Article /><Comments />
</Suspense>

// Boundaries per region: header and article appear immediately
<Header />
<Suspense fallback={<ArticleSkeleton />}><Article /></Suspense>
<Suspense fallback={<CommentsSkeleton />}><Comments /></Suspense>
```

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-01` | Suspense boundaries **MUST** be placed per UI region, not only at the root. |
| `REACT-ASYNC-02` | The `fallback` **MUST** take up roughly the same space as the real content, to avoid layout shift. |

### What triggers Suspense

Only sources integrated with it:

- components loaded with `lazy`;
- Promises read with `use`;
- data fetching from libraries with Suspense support — in TanStack Query this requires the **dedicated hooks** `useSuspenseQuery` / `useSuspenseInfiniteQuery`, not a flag on the normal `useQuery`;
- RSC with streaming.

**`useEffect` + `fetch` does not trigger Suspense.** A `<Suspense>` around a component that fetches data in an Effect never shows the fallback — this is the most common misunderstanding about the API.

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-03` | `<Suspense>` is **NEVER** combined with fetch in `useEffect` expecting a fallback — it does not work. |

---

## 2. `lazy`

```tsx
import { lazy, Suspense } from 'react'

const Settings = lazy(() => import('./Settings'))

<Suspense fallback={<Spinner />}>
  <Settings />
</Suspense>
```

It defers loading the code until the first render. Two practical rules:

**Declare it at module scope.** Calling `lazy()` inside a component creates a new type on every render, which remounts the subtree and discards its state.

```tsx
// WRONG — new component on every render
function Page() {
  const Settings = lazy(() => import('./Settings'))
  // ...
}
```

**The module needs an `export default`** — or the loader must map to a named export explicitly:

```tsx
const Settings = lazy(() =>
  import('./Settings').then((m) => ({ default: m.Settings })),
)
```

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-04` | `lazy` **MUST** be called at module scope, never inside a component. |
| `REACT-ASYNC-05` | Every `lazy` **MUST** have a `<Suspense>` ancestor. |

Where it pays off: routes, heavy modals, editors, charts. Where it does not: small components — the cost of the extra request outweighs the bundle cost.

> **Bridge:** with `TanStack Router`, route-level code splitting is already handled by the router. Use `lazy` for what is **outside** the route boundary.

---

## 3. `use`

```tsx
const value = use(promiseOrContext)
```

It reads a Promise or a context. It is an **API, not a Hook** — and that is why it is the only thing in the surface that can be called conditionally or inside blocks (`REACT-HOOK-03`).

```tsx
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise)   // suspends until it resolves
  return <ul>{comments.map((c) => <li key={c.id}>{c.text}</li>)}</ul>
}

// The parent provides the Promise and the boundary
<Suspense fallback={<CommentsSkeleton />}>
  <Comments commentsPromise={fetchComments()} />
</Suspense>
```

### The decisive restriction

**The Promise cannot be created during the render of the component that reads it.** A Promise created during render would be recreated on every render, and each one would suspend again — infinite loop.

```tsx
// WRONG — new Promise on every render
function Comments() {
  const comments = use(fetch('/api/comments').then((r) => r.json()))
}
```

The Promise must come from outside: from a Server Component, from a cache, or from a library that guarantees stable identity.

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-06` | The Promise passed to `use` is **NEVER** created during the render of the component that consumes it. |
| `REACT-ASYNC-07` | `use` **MUST** be called from inside a component or Hook, even though it can be conditional. |

In an SPA without RSC, this restriction is why `use` is rarely the right tool for data fetching — the stable cache is exactly what TanStack Query provides..

### `use` for context

```tsx
function Item({ compact }: { compact: boolean }) {
  if (compact) {
    const theme = use(ThemeContext)   // conditional — impossible with useContext
    return <span className={theme}>…</span>
  }
  return <Full />
}
```

---

## 4. Error Boundaries

Suspense handles **waiting**; an Error Boundary handles **failure**. The two boundaries are complementary and usually sit together.

```tsx
<ErrorBoundary fallback={<LoadError />}>
  <Suspense fallback={<Skeleton />}>
    <Profile userId={userId} />
  </Suspense>
</ErrorBoundary>
```

### React does not export an Error Boundary

There is no built-in `<ErrorBoundary>`. It is **necessarily a class component**, because the methods that define it have no Hook equivalent. The two options:

**A. `react-error-boundary`** (library, the normal path):

```tsx
import { ErrorBoundary } from 'react-error-boundary'

<ErrorBoundary
  fallbackRender={({ error, resetErrorBoundary }) => (
    <div role="alert">
      <p>Could not load the profile.</p>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  )}
  onError={(error, info) => reportError(error, info)}
>
  <Suspense fallback={<Skeleton />}>
    <Profile userId={userId} />
  </Suspense>
</ErrorBoundary>
```

**B. Your own implementation**, when you do not want the dependency:

```tsx
type Props = { fallback: React.ReactNode; children: React.ReactNode }
type State = { error: Error | null }

export class ErrorBoundary extends React.Component<Props, State> {
  state: State = { error: null }

  static getDerivedStateFromError(error: Error): State {
    return { error }               // updates state to render the fallback
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    reportError(error, info)       // side effect: logging, telemetry
  }

  render() {
    return this.state.error ? this.props.fallback : this.props.children
  }
}
```

The two methods have distinct roles: `getDerivedStateFromError` decides **what to render** and must be pure; `componentDidCatch` is where the **side effect** of reporting goes. Your own implementation also needs a way to reset — usually a `key` that changes, or a button that clears the state.

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-11` | A boundary with no recovery path (retry or reset) is **NEVER** enough — the user gets stuck on the fallback. |

Concept developed in. Two operational points:

**Not every error goes to the boundary.** Expected errors — validation failed, item not found, no permission — are **UI state**, not exceptions..

**Boundaries do not catch** errors in event handlers, async code outside render, nor errors in the boundary itself. Handlers need their own `try/catch`.

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-08` | Every Suspense boundary at a data boundary **MUST** have an associated Error Boundary. |
| `REACT-ASYNC-09` | An expected error is **NEVER** thrown to a boundary — it is state. |

---

## 5. Suspense + transitions

Without a transition, updating state that suspends **replaces** the visible content with the fallback — the UI flashes back to the skeleton.

```tsx
// Keeps the current content visible while the new one loads
startTransition(() => setTab('comments'))
```

General rule: **navigation and switching already-visible content must be transitions.** See [React - Performance and Concurrency](react-performance-and-concurrency.md) § 4.

| ID | Rule |
| --- | --- |
| `REACT-ASYNC-10` | An update that may suspend already-visible content **MUST** be wrapped in a transition. |

---

## 6. Antipatterns

| Antipattern | Fix |
| --- | --- |
| `<Suspense>` around fetch in an Effect | library with Suspense support · `REACT-ASYNC-03` |
| A single boundary at the root | boundaries per region · `REACT-ASYNC-01` |
| `lazy()` inside a component | module scope · `REACT-ASYNC-04` |
| Promise created during render passed to `use` | stable Promise from outside · `REACT-ASYNC-06` |
| Fallback with a different height from the content | sized skeleton · `REACT-ASYNC-02` |
| Suspense without an Error Boundary | mandatory pair · `REACT-ASYNC-08` |
| Navigation without a transition, flashing the skeleton | `startTransition` · `REACT-ASYNC-10` |

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Performance and Concurrency](react-performance-and-concurrency.md) · [React - Server Components and Directives](react-server-components-and-directives.md)

## Sources consulted

Verified on 2026-08-14:

- [Suspense](https://react.dev/reference/react/Suspense) · [lazy](https://react.dev/reference/react/lazy) · [use](https://react.dev/reference/react/use)
- [Server Components](https://react.dev/reference/rsc/server-components)
