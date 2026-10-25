---
title: TanStack Query - Fundamentals
link: https://tanstack.com/query/latest/docs/framework/react/overview
tags:
  - tanstack-query
  - fundamentals
  - data-fetching
  - agent-context
source: "Official documentation, https://tanstack.com/query/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Query - Fundamentals

## Contents

- [Version covered](#version-covered)
- [1. Concept: remote data is not yours](#1-concept-remote-data-is-not-yours)
- [2. Setup](#2-setup)
- [3. Query keys: the data's identity in the cache](#3-query-keys-the-datas-identity-in-the-cache)
- [4. Query functions](#4-query-functions)
- [5. `status` × `fetchStatus`: two axes, not one](#5-status--fetchstatus-two-axes-not-one)
- [6. Aggressive defaults](#6-aggressive-defaults)
- [7. `queryOptions` and typing](#7-queryoptions-and-typing)
- [8. Devtools](#8-devtools)
- [Antipatterns](#antipatterns)

> Server × client state · setup and `QueryClient` · `queryKey` · `queryFn` and `QueryFunctionContext` · `status` × `fetchStatus` · aggressive defaults · `queryOptions` and typing · Devtools.
>
> **Does not cover:** freshness policy and cache lifecycle ([Cache and Freshness](tanstack-query-cache-and-freshness.md)) · writes and invalidation ([Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md)) · dependent, paginated, infinite queries, prefetch and `select` ([Query Patterns](tanstack-query-query-patterns.md)) · Suspense, hydration, cancellation and network mode ([Suspense and SSR](tanstack-query-suspense-and-ssr.md)).

Entry point: [TanStack Query](tanstack-query.md)

---

## Version covered

npm registry, **2026-08-14**: `@tanstack/react-query` `dist-tags.latest = 5.101.4`. **v5 is current and stable**; v6 is only a pre-release (`6.0.0-beta.8`, August 2026), not `latest`. `tanstack.com/query/latest` serves v5 (same content as `/v5/...`) and shows no version: check versions on npm, not the site.

Do not write code against v6. "It is v5" is not enough either: some signatures circulating as v5 are outdated **within** v5, notably the mutation callbacks ([Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md) § 2).

---

## 1. Concept: remote data is not yours

The library handles "fetching, caching, synchronizing and updating **server state**". Per the source, server state is persisted remotely where you may not control it, needs async APIs, has **shared ownership** (others change it without your knowledge), and can go out of date. None of this holds for client state, so an API response in `useState` or a client store is the wrong tool, not "a different choice". This principle already has a canonical ID: **`REACT-PAT-03`** ("Remote data is **NEVER** `useState` as source of truth", skill `react-developer`). Do not create an equivalent `TSQ-*`; cite `REACT-PAT-03`.

What it takes on (caching, dedupe, background updates, staleness detection, fast updates, pagination, garbage collection, structural sharing; hub § 3) is what `useEffect` + `fetch` does **not** do: the whole argument of `REACT-EFFECT-06` (skill `react-developer`).

It does **not** validate the response: a changed API contract delivers wrong data with `status: 'success'` and optimistic typing. Validation is yours, in the `queryFn`.

---

## 2. Setup

```bash
npm i @tanstack/react-query
```

Declared compatibility: React v18+, ReactDOM and React Native.

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// Outside render: one instance per app on the client.
const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 60_000 } }, // explicit decision, TSQ-CACHE-01
})

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Repo />
    </QueryClientProvider>
  )
}
```

The `QueryClient` **is** the cache; created in a component body, it is recreated (and the cache lost) each render. Correct forms: module scope (pure SPA) or `useState(() => new QueryClient())` (when the app can remount, or with SSR). On the server the rule is stronger, one instance **per request**: [Suspense and SSR](tanstack-query-suspense-and-ssr.md) § 3.

> **With TanStack Router**, module-scope creation is still correct, but you **NEVER** *read* that singleton inside `beforeLoad`/`loader`: there the `queryClient` arrives through the router `context` (`TSR-CTX-05`), or SSR breaks. Create it in the module **and** inject it into `createRouter` (creation × access). See [TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md).

| ID | Rule |
| --- | --- |
| `TSQ-BASE-01` | The `QueryClient` is **NEVER** constructed in the render body; use module scope or `useState(() => new QueryClient())`. |

---

## 3. Query keys: the data's identity in the cache

The cache index and the unit of invalidation: an Array at the top level (one string up to nested objects), valid "as long as [it] is serializable using `JSON.stringify`, and **unique to the query's data**".

### Deterministic hashing, with an asymmetry

Key order inside objects does not matter, and `undefined` is dropped:

```tsx
// EQUAL
useQuery({ queryKey: ['todos', { status, page }], ... })
useQuery({ queryKey: ['todos', { page, status }], ... })
useQuery({ queryKey: ['todos', { page, status, other: undefined }], ... })
```

But "Array item order matters!":

```tsx
// DIFFERENT: three distinct cache entries
useQuery({ queryKey: ['todos', status, page], ... })
useQuery({ queryKey: ['todos', page, status], ... })
useQuery({ queryKey: ['todos', undefined, page, status], ... })
```

Loose array positions are positional; an object in the array is commutative. Hence the stable hierarchy `[entity, scope, params-as-object]`, e.g. `['todos', 'list', { page, status }]`, which makes prefix invalidation predictable ([Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md) § 3).

### The rule the source calls fundamental

"If your query function depends on a variable, include it in your query key": queries are then cached independently and refetch automatically when the variable changes.

```tsx
function Todo({ todoId }: { todoId: string }) {
  return useQuery({
    queryKey: ['todos', 'detail', todoId],
    queryFn: () => fetchTodoById(todoId),
  })
}
```

Omitting `todoId` raises no error: item B shows item A's data because both write to one cache entry.

| ID | Rule |
| --- | --- |
| `TSQ-BASE-02` | The query key **MUST** be an array at the top level, serializable by `JSON.stringify` and unique to that query's data. |
| `TSQ-BASE-03` | Every variable read by the `queryFn` **MUST** appear in the `queryKey`. |

---

## 4. Query functions

Any function returning a Promise. Three rules, each with a silent consequence when broken:

- **Errors must be thrown.** The query errors only if the function "must throw or return a rejected Promise". `fetch` does not reject on `404`/`500` (it resolves with `response.ok === false`); without the check, the API's error body enters the cache as success.
- **`undefined` is failure.** "Queries that resolve to `undefined` will be treated as failed." To represent absence as success, resolve `null`.
- **Validate the contract.** Return the parsed result, not raw JSON.

```tsx
const todoQuery = useQuery({
  queryKey: ['todos', 'detail', todoId],
  queryFn: async ({ signal }): Promise<Todo | null> => {
    const response = await fetch(`/api/todos/${todoId}`, { signal })
    if (response.status === 404) return null
    if (!response.ok) throw new Error(`GET /todos/${todoId} failed: ${response.status}`)
    return todoSchema.parse(await response.json())
  },
})
```

Not optional: forwarding `signal` (cancellation, [Suspense and SSR](tanstack-query-suspense-and-ssr.md) § 5), the `throw`, the Zod `parse`. The return annotation is optional (inference flows to `data`).

### `QueryFunctionContext`

| Property | Type | Use |
| --- | --- | --- |
| `queryKey` | `QueryKey` | read params from the key instead of closing over variables |
| `client` | `QueryClient` | cache access inside the `queryFn`, without `useQueryClient` |
| `signal` | `AbortSignal \| undefined` | cancellation; pass to `fetch`/`axios` |
| `meta` | `Record<string, unknown> \| undefined` | optional extra information about the query |
| `pageParam` | `TPageParam` | infinite queries only |
| `direction` | `'forward' \| 'backward'` | **deprecated**: encode direction inside `pageParam` |

| ID | Rule |
| --- | --- |
| `TSQ-BASE-04` | `queryFn` **NEVER** resolves `undefined`; for "no data", resolve `null`. |
| `TSQ-BASE-05` | A `fetch`-based `queryFn` **MUST** check `response.ok` and throw; `fetch` does not reject on HTTP errors. |
| `TSQ-BASE-06` | `queryFn` **MUST** return the result of a schema `parse`/`safeParse`, never raw JSON. |

---

## 5. `status` × `fetchStatus`: two axes, not one

The API's most common misreading. `status` is about the `data`, `fetchStatus` about the `queryFn`, and background refetches make every combination possible.

| Axis | Values | Answers |
| --- | --- | --- |
| `status` | `pending` · `error` · `success` | do I have data? |
| `fetchStatus` | `fetching` · `paused` · `idle` | is the `queryFn` running? |

| `status` | `fetchStatus` | Situation |
| --- | --- | --- |
| `success` | `idle` | normal: fresh data, nothing running |
| `success` | `fetching` | background refetch: the UI **has** data, no page spinner |
| `pending` | `fetching` | true first load |
| `pending` | `idle` | disabled query (`enabled: false`): never resolves on its own |
| `pending` | `paused` | no network in `networkMode: 'online'`: looks like eternal loading |

The last two break a naive `if (isPending) return <Spinner />`:

- **Query that can be disabled** → use `isLoading`, defined by the source as `isPending && isFetching`.
- **No network** → the network mode guide warns that checking `pending` is not enough: a query mounting for the first time offline is `pending` + `paused`.

```tsx
const { data, isLoading, isError, error, fetchStatus } = useQuery(todosOptions)

if (fetchStatus === 'paused') return <Offline />
if (isLoading) return <Spinner />
if (isError) return <ErrorView error={error} />
return <List todos={data} />
```

For a discreet background-refetch indicator: `isFetching` per query, `useIsFetching()` globally.

| ID | Rule |
| --- | --- |
| `TSQ-BASE-07` | A first-load loader on a query that can be disabled **MUST** use `isLoading`, never `isPending`. |
| `TSQ-BASE-08` | In `networkMode: 'online'`, the spinner **NEVER** depends on `status === 'pending'` alone; handle `fetchStatus: 'paused'` separately. |

---

## 6. Aggressive defaults

None is neutral:

| Default | Value | Effect |
| --- | --- | --- |
| `staleTime` | `0` | all data is born stale |
| automatic refetch | on new instance mount, window refocus, network reconnect | fires whenever the data is stale |
| `gcTime` | `1000 * 60 * 5` (5 min) | **inactive** queries leave memory after this |
| `retry` | `3` | failures retried silently |
| `retry` on the server | `0` | "to make server rendering as fast as possible" |
| `retryDelay` | `Math.min(1000 * 2 ** attemptIndex, 30000)` | exponential backoff, 30 s cap |
| `structuralSharing` | on | reference kept when data did not actually change |

Special `staleTime` values `Infinity` (invalidation still works) and `'static'` (blocks even invalidation): [Cache and Freshness](tanstack-query-cache-and-freshness.md) § 3.

`retry: 3` turns a legitimate `404` into four requests and ~7 s before the UI shows "not found". Do not retry client errors:

```tsx
new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        if (error instanceof HttpError && error.status < 500) return false
        return failureCount < 3
      },
    },
  },
})
```

---

## 7. `queryOptions` and typing

The source's preferred way to share `queryKey` and `queryFn` while keeping them co-located. At runtime it returns its input; the value is inference and the key travelling with its function.

```tsx
import { queryOptions } from '@tanstack/react-query'

export function todoOptions(todoId: string) {
  return queryOptions({
    queryKey: ['todos', 'detail', todoId] as const,
    queryFn: async ({ signal }) => {
      const res = await fetch(`/api/todos/${todoId}`, { signal })
      if (!res.ok) throw new Error(`status ${res.status}`)
      return todoSchema.parse(await res.json())
    },
    staleTime: 5 * 60_000,
  })
}

queryClient.setQueryData(todoOptions(id).queryKey, updated) // updated is typed
```

Verified consumers: `useQuery()`, `useSuspenseQuery()`, `useQueries()`, `queryClient.prefetchQuery()`, `queryClient.setQueryData()`. For infinite queries: `infiniteQueryOptions`.

> `mutationOptions` is exported by `@tanstack/react-query` (verified on 5.104.5): the same co-location for a mutation shared by several components.

TypeScript, confirmed on the official page:

- Minimum: "TypeScript versions released within the last 2 years", currently **5.4**+. The floor moves on its own.
- **Type changes ship as patch** ("considered non-breaking"): pin the exact package version.
- The result is a **discriminated union** by `status`: checking `isSuccess` narrows `data` from `T | undefined` to `T`.
- `error` is `Error` by default. For custom errors, prefer narrowing (e.g. `axios.isAxiosError`) over generics, which break the rest of inference.
- The `Register` interface registers global types: `defaultError`, `queryMeta`, `mutationMeta`, `queryKey`, `mutationKey`.

| ID | Rule |
| --- | --- |
| `TSQ-BASE-09` | `queryKey` and `queryFn` **MUST** be co-located in an exported `queryOptions` when the query has more than one consumer. |
| `TSQ-BASE-10` | The `@tanstack/react-query` version **MUST** be pinned to an exact patch; type changes are published as patches. |

---

## 8. Devtools

`@tanstack/react-query-devtools` (`ReactQueryDevtools`), excluded from production builds automatically; *floating* or *embedded* (`ReactQueryDevtoolsPanel`). Since v5 they observe mutations too and have an offline toggle to exercise `fetchStatus: 'paused'` (`TSQ-BASE-08`) without cutting the network.

Also recommended: `@tanstack/eslint-plugin-query`, which statically catches most `TSQ-BASE-03` violations.

---

## Antipatterns

```tsx
// WRONG: API response mirrored into client state
const { data } = useQuery(todosOptions())
const [todos, setTodos] = useState<Todo[]>([])
useEffect(() => { if (data) setTodos(data) }, [data])

// RIGHT: the cache already is the state
const { data: todos } = useQuery(todosOptions())
```
Violates `REACT-PAT-03` and `REACT-EFFECT-04` (skill `react-developer`). Shows on the first mutation: the cache updates, the `useState` lags.

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `queryKey: ['todos']` with `queryFn: () => fetchTodos(filter)` | changing the filter does not refetch; both variants fight over one entry | `['todos', 'list', filter]`, `TSQ-BASE-03` |
| `queryFn: () => fetch(url).then((r) => r.json())` | `fetch` does not throw on 500; the error body is cached as success | check `r.ok`, throw, `parse` (§ 4), `TSQ-BASE-05`, `TSQ-BASE-06` |
| `new QueryClient()` in the component body | cache discarded every render; every query refetches from scratch | module scope or `useState(() => ...)`, `TSQ-BASE-01` |
| `if (isPending) return <Spinner />` on a query with `enabled` | `pending + idle` is permanent; the spinner never leaves | `isLoading`, `TSQ-BASE-07` |
| `queryFn` returning `undefined` when nothing is found | the query is marked **failed**, not empty | return `null`, `TSQ-BASE-04` |
| `['todos', page, status]` with loose positions | positional order; reordering silently invalidates the whole cache | `['todos', 'list', { page, status }]` |
| Accepting `retry: 3` app-wide | a `404` costs 4 requests and ~7 s before reaching the UI | `retry` as a function, no retry on 4xx |
