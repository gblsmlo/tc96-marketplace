---
title: TanStack Query - Suspense and SSR
link: https://tanstack.com/query/latest/docs/framework/react/guides/suspense
tags:
  - tanstack-query
  - suspense
  - ssr
  - agent-context
source: "Official documentation: https://tanstack.com/query/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Query - Suspense and SSR

## Contents

- [1. Concept: who answers for loading and error](#1-concept-who-answers-for-loading-and-error)
- [2. The Suspense hooks](#2-the-suspense-hooks)
- [3. SSR: the two approaches](#3-ssr-the-two-approaches)
- [4. Streaming and hydrating pending queries](#4-streaming-and-hydrating-pending-queries)
- [5. Cancellation](#5-cancellation)
- [6. Network Mode](#6-network-mode)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> `useSuspenseQuery` · `useSuspenseQueries` · `useSuspenseInfiniteQuery` · `QueryErrorResetBoundary` · `dehydrate` / `HydrationBoundary` · streaming and hydrating `pending` queries · cancellation with `AbortSignal` · network mode.
>
> **Does not cover:** `status` × `fetchStatus` and client `QueryClient` setup ([TanStack Query - Fundamentals](tanstack-query-fundamentals.md)) · `staleTime` and `gcTime` ([TanStack Query - Cache and Freshness](tanstack-query-cache-and-freshness.md)) · prefetch in event handlers and the router ([TanStack Query - Query Patterns](tanstack-query-query-patterns.md)) · what an Error Boundary is (skill `react-developer`).

Entry: [TanStack Query](tanstack-query.md) · Normative base: [TanStack Query - Fundamentals](tanstack-query-fundamentals.md)

---

## 1. Concept: who answers for loading and error

`useQuery` returns states and lets the component decide. `useSuspenseQuery` **leaves the component**: loading goes to the nearest `<Suspense>`, errors to the nearest Error Boundary. The gain is in the types: `data` is guaranteed defined, so no `data?.`, no loading early return, no `if (isError)`.

The cost: the boundary becomes required infrastructure. **`REACT-ASYNC-08`: every Suspense boundary at a data frontier MUST have an Error Boundary** (skill `react-developer`); there is no `TSQ-*` equivalent, cite `REACT-ASYNC-08`. Without it, a network failure unmounts the tree up to the root. `REACT-ASYNC-09` still holds: an expected error (404, 409, validation) is state, not an exception for the boundary.

---

## 2. The Suspense hooks

Three: `useSuspenseQuery`, `useSuspenseQueries`, `useSuspenseInfiniteQuery`.

```tsx
function Profile({ id }: { id: string }) {
  const { data } = useSuspenseQuery(userOptions(id))
  return <h1>{data.name}</h1>   // data is T, not T | undefined
}

<ErrorBoundary fallback={<ErrorView />}>
  <Suspense fallback={<Skeleton />}>
    <Profile id={id} />
  </Suspense>
</ErrorBoundary>
```

### Two constraints that decide the architecture

**No conditional enabling:** there is no `enabled`, because the guarantee that `data` is defined cannot survive a query that does not run. A conditional query stays `useQuery` with `enabled` or `skipToken` ([TanStack Query - Query Patterns](tanstack-query-query-patterns.md) § 5).

**Queries in one component are fetched serially:** the first suspends before the second is reached; two 300 ms queries become 600 ms, a waterfall made by the code's shape, not by data dependency.

```tsx
// WRONG: 2x the latency, no dependency between them
const { data: user } = useSuspenseQuery(userOptions(id))
const { data: posts } = useSuspenseQuery(postsOptions(id))

// RIGHT: parallel
const [{ data: user }, { data: posts }] = useSuspenseQueries({
  queries: [userOptions(id), postsOptions(id)],
})
```

The other way out is two sibling components, each with its own boundary, which also gives per-fallback granularity.

### `throwOnError` is not what people assume

Default:

```
throwOnError: (error, query) => typeof query.state.data === 'undefined'
```

The error reaches the boundary **only when there is no cached data**. A failed background refetch over cached data keeps rendering the old data and never fires the boundary: good for UX, silent for observability unless you handle it.

### Reset for "try again"

A recovering Error Boundary needs the query to forget the error too: `QueryErrorResetBoundary` (component) or `useQueryErrorResetBoundary` (hook).

```tsx
<QueryErrorResetBoundary>
  {({ reset }) => (
    <ErrorBoundary
      onReset={reset}
      fallbackRender={({ resetErrorBoundary }) => (
        <button onClick={() => resetErrorBoundary()}>Try again</button>
      )}
    >
      <Profile id={id} />
    </ErrorBoundary>
  )}
</QueryErrorResetBoundary>
```

Without `reset`, the button remounts the component, the query is still in error, and the boundary fires again immediately.

| ID | Rule |
| --- | --- |
| `TSQ-SSR-01` | `useSuspenseQuery` is **NEVER** used for a conditional query: it does not accept `enabled`. Use `useQuery`. |
| `TSQ-SSR-02` | Two or more independent suspense queries in one component **MUST** become `useSuspenseQueries` or sibling components: they run serially. |
| `TSQ-SSR-03` | An Error Boundary with retry over queries **MUST** be wrapped by `QueryErrorResetBoundary` or use `useQueryErrorResetBoundary`. |

---

## 3. SSR: the two approaches

### `initialData`: simple and limited

Passing server data as `initialData` works, with drawbacks: the data must be threaded through the tree, `dataUpdatedAt` is inaccurate, and, the serious one:

> "initialData will never overwrite this data, **even if the new data is fresher than the old one**."

### Prefetch + `dehydrate` / `HydrationBoundary`: recommended

Fetch on the server with a dedicated `QueryClient`, serialize the cache with `dehydrate()`, restore on the client inside `<HydrationBoundary>` (per route or at the app root).

```tsx
// Server (route loader / RSC / getServerSideProps)
export async function loader() {
  const queryClient = new QueryClient()          // one per request
  await queryClient.prefetchQuery(todosOptions())
  return { dehydratedState: dehydrate(queryClient) }
}

// Client
export default function Page({ dehydratedState }: Props) {
  return (
    <HydrationBoundary state={dehydratedState}>
      <Todos />
    </HydrationBoundary>
  )
}
```

### Server rules

| Rule | Source and consequence |
| --- | --- |
| One `QueryClient` per request | *"This ensures that data is not shared between different users and requests"*. A module-scope client on the server serves user A's data to user B: a security bug. Client-side sibling: `TSQ-BASE-01` (`useState(() => new QueryClient())`). |
| `staleTime` above zero | with the default `0`, everything the server fetched is stale at hydration and the client refetches it all |
| No `gcTime: 0` | *"it may result in a hydration error"* |
| Safe serialization | the serializer must prevent XSS; raw `JSON.stringify()` into HTML is discouraged |

| ID | Rule |
| --- | --- |
| `TSQ-SSR-04` | On the server, the `QueryClient` **MUST** be created per request; **NEVER** in module scope. A cache shared across requests leaks data between users. |
| `TSQ-SSR-05` | An SSR app **MUST** set `staleTime` > 0 on the client, or the pre-rendered HTML is discarded at hydration. |
| `TSQ-SSR-06` | `gcTime: 0` **NEVER** in an app with hydration: the docs tie the value to hydration errors. |
| `TSQ-SSR-07` | Dehydrated state **MUST** be consumed by `<HydrationBoundary state={...}>`, not spread as `initialData` through the tree. |

---

## 4. Streaming and hydrating pending queries

> "as of React Query v5.40.0, you don't have to `await` all prefetches for this to work, as `pending` Queries can also be dehydrated and sent to the client."

Previously the response waited for the slowest prefetch. Now you can start the fetch, dehydrate the **pending** query, send the shell, and stream the result when it resolves: streaming `<Suspense>` end to end.

```tsx
shouldDehydrateQuery: (query) =>
  defaultShouldDehydrateQuery(query) || query.state.status === 'pending'
```

### Server Components and Server Actions

> "From the React Query perspective, treat Server Components as a place to prefetch data, nothing more."

**Server Actions do not work as a `queryFn`**: they *"run serially, not in parallel"*. The library assumes parallelism; serializing requests reintroduces the waterfall prefetch exists to remove. A Server Action is a write frontier (`REACT-RSC-06`, skill `react-developer`).

### The experimental package

`@tanstack/react-query-next-experimental` (`ReactQueryStreamedHydration`) fetches on the server from a Client Component via `useSuspenseQuery`, no manual prefetch, streaming as boundaries resolve. Still labelled **experimental**: an option with a recorded decision, not a default.

| ID | Rule |
| --- | --- |
| `TSQ-SSR-08` | A Server Function / Server Action is **NEVER** used as a `queryFn`: they run serially. |
| `TSQ-SSR-09` | `@tanstack/react-query-next-experimental` **NEVER** enters production without a recorded decision: the docs keep it marked experimental. |

---

## 5. Cancellation

Every query function receives an `AbortSignal`.

```tsx
useQuery({
  queryKey: ['todos'],
  queryFn: async ({ signal }) => {
    const res = await fetch('/todos', { signal })
    if (!res.ok) throw new Error(`status ${res.status}`)
    return todosSchema.parse(await res.json())
  },
})

// axios (v0.22.0+)
useQuery({
  queryKey: ['todos'],
  queryFn: ({ signal }) => axios.get('/todos', { signal }),
})
```

If you consume it, the Promise is cancelled and so is the query, whose state is **reverted** to its previous state. Cancellation is not an error: no `status: 'error'`, no error entry in the cache. That removes the manual `AbortError` filtering of the `AbortController`-in-`useEffect` pattern (skill `react-developer`).

`queryClient.cancelQueries({ queryKey: ['todos'] })` cancels manually and reverts; it is the first step of the optimistic update (`TSQ-MUT-10`).

Not forwarding `signal` breaks nothing visible: obsolete requests keep travelling, holding connections and, in type-ahead search, keeping N requests in flight for results nobody will see.

| ID | Rule |
| --- | --- |
| `TSQ-SSR-10` | Every `queryFn` doing cancellable I/O **MUST** forward the `signal` from the `QueryFunctionContext`. |

---

## 6. Network Mode

| Mode | Behaviour |
| --- | --- |
| `online` (default) | queries and mutations do not fire without a network connection; going offline mid-fetch pauses retry, resumed automatically on reconnect |
| `always` | always fetches, ignoring online/offline. For a `queryFn` with no network: AsyncStorage, IndexedDB, mocks. |
| `offlineFirst` | runs the `queryFn` once, then pauses retries. For a PWA with a service worker or an HTTP cache in front. |

UI caveat, already rule `TSQ-BASE-08`: a query mounting for the first time with no network is `status: 'pending'` with `fetchStatus: 'paused'`; checking only `isPending` shows an infinite spinner in airplane mode. The `online` default also explains why a `queryFn` reading local storage never runs offline: the library does not even try.

| ID | Rule |
| --- | --- |
| `TSQ-SSR-11` | A `queryFn` that does not depend on the network (local storage, memory, mock) **MUST** declare `networkMode: 'always'`. |

---

## Version notes

- 5.104.5 marks `prefetchQuery` `@deprecated`; on that line the server prefetch is `await queryClient.query(todosOptions()).catch(() => {})`, with the same dehydrate flow.
Facts older material missed: `pending` queries dehydrate since v5.40.0, so streaming needs neither awaiting every prefetch nor the experimental Next package (§ 4); Server Actions as `queryFn` are explicitly discouraged, a common pattern in generated code (§ 4); `gcTime: 0` causes hydration errors, the per-request `QueryClient` is a cross-user leak guard, `initialData` never overwrites fresher data (ruling it out for revisited SSR screens) and raw `JSON.stringify()` risks XSS (§ 3); the suspense `throwOnError` default is a function (§ 2).

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `const queryClient = new QueryClient()` at module scope in a server `loader` | cache shared across requests and users | create it inside the `loader`: `TSQ-SSR-04` |
| `useSuspenseQuery({ ...userOptions(id), enabled: !!id })` | `enabled` does not exist here | `useQuery({ ...userOptions(id), enabled: !!id })`: `TSQ-SSR-01` |
| Data `<Suspense>` without an Error Boundary | a network failure unmounts the tree up to the root | Error Boundary: `REACT-ASYNC-08` |
| "Try again" button without `reset` | the query stays in error; the boundary refires immediately | `QueryErrorResetBoundary`: `TSQ-SSR-03` |
| Two independent `useSuspenseQuery` in one component | serializes two latencies with no dependency | `useSuspenseQueries`: `TSQ-SSR-02` |
| SSR with `staleTime: 0` | the client refetches everything the server fetched, at hydration | `staleTime` > 0: `TSQ-SSR-05` |
| Server Action as `queryFn` | runs serially; recreates the waterfall | HTTP route for reads: `TSQ-SSR-08` |
| `queryFn` ignoring `signal` | obsolete requests stay in flight; N in parallel in type-ahead search | forward `signal`: `TSQ-SSR-10` |
| Spinner based only on `isPending` | airplane mode becomes infinite loading with no message | handle `fetchStatus: 'paused'`: `TSQ-BASE-08` |
