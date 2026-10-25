---
title: TanStack Query - Query Patterns
link: https://tanstack.com/query/latest/docs/framework/react/guides/dependent-queries
tags:
  - tanstack-query
  - patterns
  - agent-context
source: "Official documentation: https://tanstack.com/query/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Query - Query Patterns

## Contents

- [1. Concept: the shape of the query is a latency decision](#1-concept-the-shape-of-the-query-is-a-latency-decision)
- [2. Dependent and parallel](#2-dependent-and-parallel)
- [3. Paginated](#3-paginated)
- [4. Infinite](#4-infinite)
- [5. Lazy, enabled and skipToken](#5-lazy-enabled-and-skiptoken)
- [6. Prefetching and waterfalls](#6-prefetching-and-waterfalls)
- [7. select](#7-select)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> Dependent queries · parallel and `useQueries` · paginated with `keepPreviousData` · `useInfiniteQuery` · lazy, `enabled` and `skipToken` · prefetching and flattening waterfalls · `select`.
>
> **Does not cover:** key, `queryFn` and `status` ([TanStack Query - Fundamentals](tanstack-query-fundamentals.md)) · `staleTime`, `placeholderData` × `initialData` ([TanStack Query - Cache and Freshness](tanstack-query-cache-and-freshness.md)) · writes and invalidation ([TanStack Query - Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md)) · `useSuspenseQueries` and SSR prefetch ([TanStack Query - Suspense and SSR](tanstack-query-suspense-and-ssr.md)).

Entry: [TanStack Query](tanstack-query.md) · Normative base: [TanStack Query - Fundamentals](tanstack-query-fundamentals.md)

---

## 1. Concept: the shape of the query is a latency decision

Every pattern answers: **how many round trips until the screen is ready, and in what order.** Two parallel requests cost one latency, two serial ones cost two (on bad 4G, a second and a half). Preference, best to worst:

1. **One request** bringing everything the screen needs (an API change, not a frontend one);
2. **N parallel requests**: `useQuery` side by side or `useQueries`;
3. **N serial, with prefetch** to flatten what can be flattened;
4. **N serial** (chained `enabled`): the case that needs a justification.

---

## 2. Dependent and parallel

### Dependent: `enabled`

```tsx
const { data: user } = useQuery({
  queryKey: ['user', email],
  queryFn: () => getUserByEmail(email),
})

const userId = user?.id

const { data: projects } = useQuery({
  queryKey: ['projects', userId],
  queryFn: () => getProjectsByUser(userId!),
  enabled: !!userId,
})
```

While disabled, the second query is `status: 'pending'`, `fetchStatus: 'idle'`: the combination that breaks `if (isPending)` and requires `isLoading` (`TSQ-BASE-07`).

The docs' preferred fix: restructure the backend so both can be fetched in parallel. When that is impossible (third-party API, backend outside your control, an ID that only exists after a write), chaining is legitimate and the justification belongs in the code.

### Parallel: side by side

With a fixed number of queries, stack the hooks; they fire together:

```tsx
const usersQuery = useQuery({ queryKey: ['users'], queryFn: fetchUsers })
const teamsQuery = useQuery({ queryKey: ['teams'], queryFn: fetchTeams })
```

**Except under Suspense:** *"the first query would throw a promise internally and would suspend the component before the other queries run."* Use `useSuspenseQueries` ([TanStack Query - Suspense and SSR](tanstack-query-suspense-and-ssr.md) § 2).

### `useQueries`: variable count

When the count changes between renders, stacking hooks violates `REACT-HOOK-01` (Hooks never in a loop or conditional; skill `react-developer`). `useQueries` takes an options object with a `queries` array and returns an array of results:

```tsx
const userQueries = useQueries({
  queries: users.map((user) => ({
    queryKey: ['user', user.id],
    queryFn: () => fetchUserById(user.id),
  })),
})
```

It accepts `combine` to reduce the result array to one value, and handles dynamic dependents: build the array from the previous result, returning `[]` until the input arrives.

> **Typing caveat:** an inline `select` inside a `useQueries` query object does not infer `data` from that object's `queryFn`. Extract the function with an explicit type.

| ID | Rule |
| --- | --- |
| `TSQ-PATTERN-01` | A dependent query via `enabled` **MUST** carry, in a comment or ADR, why the API cannot return both pieces of data in one call. |
| `TSQ-PATTERN-02` | A variable number of queries **MUST** use `useQueries`; Hooks **NEVER** in a loop (`REACT-HOOK-01`). |
| `TSQ-PATTERN-03` | Parallel queries under `<Suspense>` **MUST** use `useSuspenseQueries`; side-by-side hooks suspend serially. |

---

## 3. Paginated

Pagination works by putting the page in the query key, but each page is a brand new query: the new key has no data, the query returns to `pending`, the table vanishes and reappears. `placeholderData: keepPreviousData` keeps the last successful data while the new key loads, then swaps it.

```tsx
import { keepPreviousData, useQuery } from '@tanstack/react-query'

const [page, setPage] = useState(0)

const { data, isPlaceholderData, isFetching } = useQuery({
  queryKey: ['projects', { page }],
  queryFn: () => fetchProjects(page),
  placeholderData: keepPreviousData,
})

<button
  onClick={() => setPage((p) => p + 1)}
  disabled={isPlaceholderData || !data?.hasMore}
>
  Next
</button>
```

`isPlaceholderData` is not optional: while it is `true`, `data.hasMore` describes the **previous** page, and two fast clicks skip a page or run past the end. The pattern also works with `useInfiniteQuery`.

Page state is a natural candidate for the URL instead of `useState`: [TanStack Router - Search Params](tanstack-router-search-params.md) (`REACT-PAT-10`, skill `react-developer`).

| ID | Rule |
| --- | --- |
| `TSQ-PATTERN-04` | A paginated query **MUST** include the page in the `queryKey` and use `placeholderData: keepPreviousData`. |
| `TSQ-PATTERN-05` | The page navigation control **MUST** stay disabled while `isPlaceholderData` is `true`. |

---

## 4. Infinite

```tsx
const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
  queryKey: ['projects'],
  queryFn: ({ pageParam, signal }) => fetchProjects(pageParam, signal),
  initialPageParam: 0,                                   // required
  getNextPageParam: (lastPage) => lastPage.nextCursor,   // undefined = no more pages
})
// data.pages: fetched pages · data.pageParams: params used
```

`initialPageParam` is *"available (and required)"*. `getNextPageParam` / `getPreviousPageParam` determine both whether there is more and how to fetch it; returning `undefined` sets `hasNextPage` to false.

### Two caveats that produce production bugs

- **`maxPages` drops pages from the other end.** Upstream pairs it with `getPreviousPageParam`, so a dropped page can be fetched back; with only `getNextPageParam`, the dropped pages are gone until the entry is reset.
- **Refetch refetches every page, in order:** *"each group is fetched sequentially, starting from the first one"*, so stale cursors are never used. A list with 30 loaded pages makes 30 serial requests when invalidated. `maxPages` limits the pages stored.
- **Only one fetch in flight per infinite query:** *"calling `fetchNextPage` while an ongoing fetch is in progress runs the risk of overwriting data refreshes happening in the background"*. An unguarded `IntersectionObserver` firing on every scroll event tramples its own load.

```tsx
useEffect(() => {
  if (inView && hasNextPage && !isFetchingNextPage) fetchNextPage()
}, [inView, hasNextPage, isFetchingNextPage, fetchNextPage])
```

| ID | Rule |
| --- | --- |
| `TSQ-PATTERN-06` | `useInfiniteQuery` **MUST** declare `initialPageParam` and `getNextPageParam`. |
| `TSQ-PATTERN-07` | `fetchNextPage` is **NEVER** called while `isFetchingNextPage` is true. |
| `TSQ-PATTERN-08` | An infinite query with no natural page ceiling **MUST** declare `maxPages`: refetch reloads every page serially. |

---

## 5. Lazy, `enabled` and `skipToken`

`enabled` can also toggle later (a filter form that fires once a value is entered). A disabled query:

- with cached data, starts at `status === 'success'`;
- without cached data, starts at `status === 'pending'` and `fetchStatus === 'idle'`;
- does not fetch on mount and does not refetch in the background;
- *"will ignore query client `invalidateQueries` and `refetchQueries` calls"*;
- still runs a manual `refetch()`.

The fourth item surprises: a mutation invalidating a prefix does **nothing** to its disabled queries. The data is stale when re-enabled, usually desired, but not what people assume.

### `skipToken` and the `refetch` trap

`skipToken` types better: instead of `enabled: !!id` with `id!` in the `queryFn`, TypeScript knows the query does not run and `data` stays `undefined`.

```tsx
import { skipToken, useQuery } from '@tanstack/react-query'

const { data } = useQuery({
  queryKey: ['todos', filter],
  queryFn: filter ? () => fetchTodos(filter) : skipToken,
})
```

> "Calling `refetch()` on a query that uses `skipToken` will result in a `Missing queryFn` error"

Needs manual triggering → `enabled: false`. Otherwise → `skipToken`, for the typing.

| ID | Rule |
| --- | --- |
| `TSQ-PATTERN-09` | A query that needs manual triggering **MUST** use `enabled: false`: `refetch()` with `skipToken` throws `Missing queryFn`. |
| `TSQ-PATTERN-10` | A disabled query is **NEVER** used for data a mutation must keep fresh: it ignores `invalidateQueries`. |

---

## 6. Prefetching and waterfalls

Prefetch fills the cache before anyone asks, turning `A → B → C` into `A + B + C`. `prefetchQuery` / `prefetchInfiniteQuery` respect the `queryClient` `staleTime` and accept their own, which *"is only used for the prefetch"*: set it on the `useQuery` too. With no `useQuery` instance, the prefetched query is garbage collected after `gcTime`. Return and error behaviour are in the table below.

**Prefetch is a bet, fetch is a requirement.** Application points: event handlers, components, router integration, server rendering.

```tsx
// Event handler: network starts on hover, not click
<Link
  to="/todos/$id"
  params={{ id }}
  onMouseEnter={() => queryClient.prefetchQuery(todoOptions(id))}
  onFocus={() => queryClient.prefetchQuery(todoOptions(id))}
/>
```

```tsx
// Component: fire the child's query alongside the parent's; no await, return unused
function Article({ id }: { id: string }) {
  const queryClient = useQueryClient()
  queryClient.prefetchQuery(commentsOptions(id))
  const { data } = useQuery(articleOptions(id))
  // ...
}
```

With a router, the route `loader` is the most robust path: prefetch starts on navigation, before any component mounts ([TanStack Router - Data Loading](tanstack-router-data-loading.md)). The exported `queryOptions` (`TSQ-BASE-09`) lets loader and component share the exact same definition.

| ID | Rule |
| --- | --- |
| `TSQ-PATTERN-11` | `prefetchQuery` is **NEVER** used for data rendering requires: it returns `Promise<void>` and does not throw. Outside a route loader, use `fetchQuery`; **inside** a loader, use `ensureQueryData` (`TSR-LOAD-16`). |
| `TSQ-PATTERN-12` | Prefetch and the matching `useQuery` **MUST** share the same `queryOptions`. Alias of `TSQ-BASE-09`. |

| Function | Returns | Refetches if already fresh? | Where |
| --- | --- | --- | --- |
| `prefetchQuery` | `Promise<void>`, **does not throw** (the `useQuery` retries) | no | opportunistic warm-up where failing is acceptable |
| `fetchQuery` | `Promise<TData>`, throws | **yes, always** | outside a loader, when you need the data or the error |
| `ensureQueryData` | `Promise<TData>`, throws | no, respects the cache | **inside a loader**: `fetchQuery` that respects `staleTime` |

`ensureQueryData` wins in a loader because it throws (the error reaches `errorComponent`) **and** skips what is fresh. `fetchQuery` in a loader ignores the cache and refetches on every navigation.

On 5.104.5 all three are `@deprecated`: `queryClient.query(options)` replaces `fetchQuery`, `query({ ...options, staleTime: 'static' })` replaces `ensureQueryData`, and `query(options).catch(noop)` replaces `prefetchQuery`; the semantics in the table hold. Check the installed types before choosing a name.

---

## 7. `select`

`select` transforms what the component sees without touching the cache: fewer re-renders (*"will only re-render if the length of the todos changes"*) and a place to adapt the server shape to the UI without breaking structural sharing (`TSQ-CACHE-04`).

```tsx
const count = useQuery({
  ...todosOptions(),
  select: (todos) => todos.length,
})
```

> "A `select` function that returns an error results in `data` being `undefined` and `isSuccess` being `true`."

A throwing `select` yields an apparently successful query with no data. Validate *"in the `queryFn` instead"*, where Zod `parse` already lives (`TSQ-BASE-06`).

Stability: the docs suggest wrapping `select` in `useCallback`; a function defined outside the component works the same without a hook.

| ID | Rule |
| --- | --- |
| `TSQ-PATTERN-13` | `select` **NEVER** validates or throws: an error in `select` yields `data: undefined` with `isSuccess: true`. Validate in the `queryFn`. |
| `TSQ-PATTERN-14` | An inline `select` with an expensive computation **MUST** be stabilized (`useCallback` or a function outside the component). |

---

## Version notes

Facts older material missed: a throwing `select` is not a query error (§ 7); one fetch in flight per infinite query (§ 4); the prefetch `staleTime` does not apply to `useQuery` (§ 6); a disabled query ignores `invalidateQueries` and `refetchQueries` (§ 5); `useQueries` inline `select` inference gap and `combine` (§ 2).

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `users.map((u) => useQuery(...))` | Hook in a loop | `useQueries({ queries: users.map(...) })`: `TSQ-PATTERN-02` |
| `userOptions` then `settingsOptions` with `enabled: !!user?.id`, by habit | waterfall the backend could avoid | one round trip (`userWithSettingsOptions`), or justify: `TSQ-PATTERN-01` |
| `select: (raw) => todoSchema.parse(raw)` | an error becomes success with no data | `parse` in the `queryFn`: `TSQ-PATTERN-13` |
| Pagination without `keepPreviousData` | the table vanishes on every page change | `placeholderData: keepPreviousData`: `TSQ-PATTERN-04` |
| "Next" button active with `isPlaceholderData` | decides on the previous page's data; skips or overshoots | `disabled={isPlaceholderData}`: `TSQ-PATTERN-05` |
| `fetchNextPage` in an observer without a guard | one fetch in flight per infinite query; the call tramples the refresh | check `isFetchingNextPage`: `TSQ-PATTERN-07` |
| Infinite query without `maxPages` | invalidation refetches every page serially | `maxPages`: `TSQ-PATTERN-08` |
| `skipToken` + a "search" button calling `refetch()` | `Missing queryFn` | `enabled: false`: `TSQ-PATTERN-09` |
| `prefetchQuery` before rendering required data | returns no data and does not throw; the screen breaks silently | `fetchQuery`: `TSQ-PATTERN-11` |
| Inline `select` recreated every render | recomputes on every render | stable function: `TSQ-PATTERN-14` |
| Side-by-side parallel queries under `<Suspense>` | the first suspends before the others run | `useSuspenseQueries`: `TSQ-PATTERN-03` |
