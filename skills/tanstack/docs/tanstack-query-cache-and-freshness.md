---
title: TanStack Query - Cache and Freshness
link: https://tanstack.com/query/latest/docs/framework/react/guides/caching
tags:
  - tanstack-query
  - cache
  - agent-context
source: "Official documentation, https://tanstack.com/query/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Query - Cache and Freshness

## Contents

- [1. Concept: freshness is a domain decision, not a default](#1-concept-freshness-is-a-domain-decision-not-a-default)
- [2. A query's lifecycle](#2-a-querys-lifecycle)
- [3. `staleTime`: choosing a policy](#3-staletime-choosing-a-policy)
- [4. Refetch triggers and the temptation to turn them off](#4-refetch-triggers-and-the-temptation-to-turn-them-off)
- [5. Structural sharing and tracked properties](#5-structural-sharing-and-tracked-properties)
- [6. `placeholderData` × `initialData`](#6-placeholderdata--initialdata)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> A query's lifecycle · `staleTime` × `gcTime` · refetch triggers and how to calibrate them · structural sharing and tracked properties · `placeholderData` × `initialData`.
>
> **Does not cover:** key identity and `queryFn` ([Fundamentals](tanstack-query-fundamentals.md)) · write-triggered invalidation ([Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md)) · `keepPreviousData` in pagination ([Query Patterns](tanstack-query-query-patterns.md)) · hydration and `gcTime` in SSR ([Suspense and SSR](tanstack-query-suspense-and-ssr.md)).

Entry point: [TanStack Query](tanstack-query.md) · Normative base: [TanStack Query - Fundamentals](tanstack-query-fundamentals.md)

---

## 1. Concept: freshness is a domain decision, not a default

Caching answers three questions the library cannot answer for you:

1. **How long can this response be shown without asking again?** → `staleTime`
2. **How long is it worth keeping in memory once nobody uses it?** → `gcTime`
3. **Which reads does a write make suspect?** → invalidation

The defaults answer aggressively: *nothing is fresh* (`staleTime: 0`), *keep 5 minutes* (`gcTime`), *nothing invalidates on its own*. Fine to start, bad to leave: a busy list and a static reference table do not share a policy. The structural error is never choosing, then fighting symptoms by turning off `refetchOnWindowFocus`.

---

## 2. A query's lifecycle

The source narrates it with `gcTime: 3 * 60 * 1000`:

1. **First `useQuery({ queryKey: ['todos'], queryFn: fetchTodos })` mounts.** New key: hard loading state and a request. The data is cached and marked stale after `staleTime` (default `0`, immediately).
2. **A second instance of the key mounts elsewhere.** Cached data immediately, **plus** a background request; when it returns, both instances update. Dedupe and sync with no component aware of the other.
3. **All instances unmount.** The query is **inactive**; a garbage collection timeout of `gcTime` (default **5 minutes**) starts.
4. a) **A new instance mounts before the timeout:** cached data immediately while `fetchTodos` runs in the background ("the app is fast").
   b) **Nobody mounts in time:** the data is garbage collected.

**`staleTime` and `gcTime` govern different phases and do not compete**: `staleTime` while **active** (whether to refetch), `gcTime` once **inactive** (when to discard). High `staleTime` with low `gcTime` does not revalidate yet loses the cache on screen change: the worst combination.

| | `staleTime` | `gcTime` |
| --- | --- | --- |
| Governs | when data is considered stale | how long inactive data stays in memory |
| Applies while | there is an active instance | there is **no** active instance |
| Default | `0` | 5 minutes |
| Raising it | fewer requests | more memory, faster navigation |
| Old name | | `cacheTime` (v4) |

---

## 3. `staleTime`: choosing a policy

A stale query refetches on three triggers: a new instance mounts, the window refocuses, the network reconnects. With `staleTime: 0`, every mount, tab return and reconnect hits the network, for data that did not change.

**Calibrate by data volatility, not by screen.**

| Nature of the data | `staleTime` | Rationale |
| --- | --- | --- |
| Feature flags, permissions, enums, reference tables | `'static'` | immutable during the session |
| User profile, account settings | 30–60 min | changes rarely, by the user's own action |
| Listing of the user's resources | 1–5 min | changes through the app, and the mutation invalidates |
| Detail opened right after the listing | same as the listing | avoids immediate refetch on navigation |
| Counters, live status, balance | `0` + `refetchInterval` | freshness is the requirement |

The two special values:

- **`Infinity`**: blocks staleness refetch. `invalidateQueries` still works.
- **`'static'`**: "never trigger a refetch, even if the Query is invalidated manually". Also blocks `refetchOnMount`, `refetchOnWindowFocus` and `refetchOnReconnect` even when set to `"always"`.

`'static'` puts the query out of invalidation's reach. On data a mutation can change, the bug hides from tests: invalidation runs, returns without error, does nothing.

```tsx
// Sane base for a CRUD app: conservative default, explicit exceptions.
new QueryClient({
  defaultOptions: { queries: { staleTime: 60_000, gcTime: 10 * 60_000 } },
})

export const featureFlagsOptions = queryOptions({
  queryKey: ['feature-flags'],
  queryFn: fetchFlags,
  staleTime: 'static', // does not change at runtime, and nothing invalidates it
})
```

| ID | Rule |
| --- | --- |
| `TSQ-CACHE-01` | `staleTime` **MUST** appear explicitly on the query or in the `QueryClient` `defaultOptions`; accepting `0` is a decision, not an omission. |
| `TSQ-CACHE-02` | `staleTime: 'static'` is **NEVER** used on data some mutation can change; it blocks `invalidateQueries`. |

---

## 4. Refetch triggers and the temptation to turn them off

Each trigger has a flag: `refetchOnMount`, `refetchOnWindowFocus`, `refetchOnReconnect`. All accept `true` (default), `false` and `'always'` (ignores `staleTime` and refetches anyway).

The wrong fix for over-fetching is `refetchOnWindowFocus: false`. It works, which is why it misleads: `staleTime: 0` still says "never trust this data", just invisibly. The app now revalidates on mount (`refetchOnMount` still on) but not on tab return: two contradictory policies in one cache.

Calibrate `staleTime` first. If one trigger still bothers you (a dashboard open all day), turn it off as fine-tuning, not as the remedy.

Outside the browser: `focusManager.setEventListener()` replaces the default listener (`visibilitychange` + `document.visibilityState === 'visible'`), `focusManager.setFocused(true | false | undefined)` forces the state; React Native uses `AppState`.

| ID | Rule |
| --- | --- |
| `TSQ-CACHE-03` | Excess refetching **MUST** be fixed with `staleTime` before any `refetchOnMount`/`refetchOnWindowFocus`/`refetchOnReconnect: false`. |

---

## 5. Structural sharing and tracked properties

Two optimizations that run on their own, and two ways to switch them off unnoticed.

### Structural sharing

The reference is kept if *nothing* changed; otherwise only changed parts are replaced. Same JSON re-renders nothing; one changed item in 200 keeps the other 199's identity, so `memo`, `useMemo` and dependency arrays keep working.

Literal limitation: "This optimization only works if the `queryFn` returns JSON compatible data." `Date`, `Map`, `Set`, `BigInt` and class instances always look new; a `queryFn` converting ISO strings to `Date` disables it for the whole object. Convert in the consumer or a `select`. Opt out with `structuralSharing: false` or pass a custom implementation.

### Tracked properties

The `useQuery` result is a Proxy: the component re-renders only for properties it **accesses** (reading only `data`, it ignores `isFetching` toggles). Object rest destructuring disables this.

```tsx
// WRONG: rest touches every property; re-renders on isFetching, isStale, dataUpdatedAt...
const { data, ...rest } = useQuery(todosOptions())

// RIGHT: only the properties actually read are tracked
const { data, isLoading } = useQuery(todosOptions())
```

Explicit tuning when needed: `notifyOnChangeProps`.

| ID | Rule |
| --- | --- |
| `TSQ-CACHE-04` | `queryFn` **MUST** return JSON-compatible data; `Date`, `Map`, `Set` and class instances break structural sharing. Convert in the consumer or in `select`. |
| `TSQ-CACHE-05` | The `useQuery` result is **NEVER** destructured with rest (`const { data, ...rest }`); it disables tracked properties. |

---

## 6. `placeholderData` × `initialData`

Both start the query in `success` instead of `pending`. The deciding difference: placeholder data "**is not persisted to the cache**".

| | `initialData` | `placeholderData` |
| --- | --- | --- |
| Goes to the cache | **yes** | no |
| Subject to `staleTime` | yes, counts as just fetched | not applicable |
| Flagged in the result | no flag | `isPlaceholderData: true` |
| Seen by other instances of the key | yes | no |
| Purpose | **real** data obtained another way | **provisional** data to avoid an empty screen |

### `initialData`: real data by another path

It is persisted to the cache, so the source advises against placeholder, partial or incomplete data. Legitimate use: reuse what the cache already has, e.g. the listing's item as the detail screen's start.

```tsx
const todo = useQuery({
  ...todoOptions(todoId),
  initialData: () =>
    queryClient.getQueryData<Todo[]>(['todos', 'list'])?.find((t) => t.id === todoId),
  initialDataUpdatedAt: () =>
    queryClient.getQueryState(['todos', 'list'])?.dataUpdatedAt,
})
```

`initialDataUpdatedAt` (ms timestamp of the initial data's last update) prevents the worst case: without it, an item cached twenty minutes ago enters as just fetched and `staleTime` shields it from revalidation. With no `staleTime`, the query refetches on mount; with one, the data counts as fresh for that long.

### `placeholderData`: provisional, and flagged

Not cached, invisible to other instances, flagged by `isPlaceholderData: true`. It accepts a function of `previousData` and `previousQuery`, the basis of flicker-free pagination (`keepPreviousData`, [Query Patterns](tanstack-query-query-patterns.md) § 3).

```tsx
const { data, isPlaceholderData } = useQuery({
  ...todoOptions(todoId),
  placeholderData: { id: todoId, title: '', done: false },
})

<button disabled={isPlaceholderData} onClick={() => complete(data)}>
  Complete
</button>
```

Ignoring the flag turns the optimization into a bug: "next page" clicked on a provisional count, a form submitted with skeleton values.

| ID | Rule |
| --- | --- |
| `TSQ-CACHE-06` | `initialData` **NEVER** receives partial, incomplete or skeleton data; it is persisted to the cache and other instances read it. |
| `TSQ-CACHE-07` | `initialData` derived from another cache entry **MUST** come with `initialDataUpdatedAt`. |
| `TSQ-CACHE-08` | A `placeholderData` consumer **MUST** check `isPlaceholderData` before enabling an action or decision based on it. |

---

## Version notes

- The Placeholder Query Data page does not mention `keepPreviousData`; it appears in the Paginated Queries guide. "placeholderData = keepPreviousData" is derived, not literal.
- The Window Focus Refetching page does not document `'always'` for `refetchOnWindowFocus`; the value appears in the defaults guide, where `staleTime: 'static'` is said to block it.

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Never declaring `staleTime` | all data born stale; the app fetches on every mount, focus and reconnect | explicit `staleTime` by volatility, `TSQ-CACHE-01` |
| `refetchOnWindowFocus: false` as a general remedy | hides the symptom and leaves `refetchOnMount` with the opposite policy in the same cache | calibrate `staleTime`, `TSQ-CACHE-03` |
| `staleTime: 'static'` on data a mutation changes | `invalidateQueries` runs, does not fail, has no effect | `Infinity` (invalidation still works), `TSQ-CACHE-02` |
| `staleTime: Infinity` + default `gcTime` | no revalidation while active, but everything lost 5 min after leaving the screen | raise `gcTime` along with it, so returning to the screen finds the cache |
| `queryFn` converting ISO to `Date` | the whole object looks new on each refetch; structural sharing off | convert in `select` or the component, `TSQ-CACHE-04` |
| `const { data, ...rest } = useQuery(...)` | rest touches every Proxy prop; re-render on `isFetching`, `isStale`, `dataUpdatedAt` | destructure only what you use, `TSQ-CACHE-05` |
| `initialData` with a skeleton object | the skeleton is written to the cache and served to every instance of the key | `placeholderData`, `TSQ-CACHE-06` |
| `initialData` from another cache without a timestamp | old data enters as just fetched and `staleTime` shields it | `initialDataUpdatedAt`, `TSQ-CACHE-07` |
