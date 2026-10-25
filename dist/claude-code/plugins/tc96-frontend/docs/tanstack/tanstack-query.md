---
title: TanStack Query
link: https://tanstack.com/query/latest/docs/framework/react/overview
tags:
  - tanstack-query
  - data-fetching
  - server-state
  - reference
  - agent-context
source: "Official documentation, tanstack.com/query/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Query

## Contents

- [1. How to use these docs](#1-how-to-use-these-docs)
- [2. Mental model](#2-mental-model)
- [3. What the library solves out of the box](#3-what-the-library-solves-out-of-the-box)
- [4. Task map](#4-task-map)
- [5. Decision trees](#5-decision-trees)
- [5.1 Diagnosis by symptom](#51-diagnosis-by-symptom)
- [6. Normative rules](#6-normative-rules)
- [7. Skill contract](#7-skill-contract)
- [8. Bridges](#8-bridges)

> Entry point for server state: a router over the satellites, with rules citable by ID (`TSQ-*`). When it diverges from [tanstack.com/query](https://tanstack.com/query/latest/docs/framework/react/overview), the source wins. Each satellite records the version it verified.

---

## 1. How to use these docs

| Step | Load | When |
| --- | --- | --- |
| 1 | This doc (§ 2, § 4, § 5) | Whenever the task involves remote data |
| 2 | The task's satellite, via § 4 | When it touches a concrete API |
| 3 | The `react-developer` skill | If the task also touches components or client state |

Never load every satellite.

---

## 2. Mental model

1. **Server state is not client state.** It lives somewhere you do not control, needs an async API, has **shared ownership** (others change it without you knowing), and can be out of date at any moment. `useState` models none of this.
2. **You declare how to get the data and when it is stale; you do not manage it.** A query is a key, a function and a freshness policy. The cache is the source of truth, shared by every component using the key.
3. **The query key is the data's identity.** Cache, dedupe, invalidation and refetch revolve around it. A variable the fetch function depends on **belongs in the key**; forgetting this causes most stale-data bugs.
4. **`stale` and `loading` are independent axes.** Data can be cached and revalidating in the background at once. Confusing "no data" with "fetching" flashes spinners over content already on screen.
5. **A write does not update the screen; invalidation does.** After a mutation, decide what became stale: the most error-prone part ([Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md)).

---

## 3. What the library solves out of the box

Caching, request dedupe, background revalidation, staleness detection, fast UI updates, pagination and lazy loading, garbage collection, and memoization with *structural sharing*. Code doing any of these by hand is fighting the library.

---

## 4. Task map

| I need to... | Satellite |
| --- | --- |
| Understand server state, setup, query keys, query functions, `status` × `fetchStatus` | [Fundamentals](tanstack-query-fundamentals.md) |
| Set the freshness policy: `staleTime`, `gcTime`, when refetch happens | [Cache and Freshness](tanstack-query-cache-and-freshness.md) |
| Write: mutations, invalidation, optimistic update, direct cache writes | [Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md) |
| Dependent, parallel, paginated, infinite, lazy queries, prefetch, `select` | [Query Patterns](tanstack-query-query-patterns.md) |
| `useSuspenseQuery`, SSR/hydration, cancellation, network mode | [Suspense and SSR](tanstack-query-suspense-and-ssr.md) |

---

## 5. Decision trees

### Does this data belong in Query?

```
Does the data come from a server, and can someone else change it?
├── YES → it is server state. Query.
└── NO
    ├── Ephemeral UI state → useState
    ├── Must survive refresh / be a link → route search param
    │   → TanStack Router - Search Params (tanstack-router-search-params.md)
    └── Global client state written often → a client store
```

A response copied to `useState` is a second source of truth that diverges on the first revalidation (`REACT-PAT-03`, skill `react-developer`).

### Which `staleTime`?

```
How often does this data change, and what does showing it stale cost?
├── Practically immutable (country, currency, domain enum)
│   → high staleTime (minutes to hours). Refetch is waste.
├── Changes with use, but seconds-stale is harmless
│   → medium staleTime. The most common case.
└── Must always be correct (balance, stock, permission)
    → low or zero staleTime, and revalidate after actions that affect it
```

`staleTime: 0` (the default) means "always stale": it revalidates on every mount, window focus and reconnect. Safe, not free.

### I wrote to the server. Now what?

```
What did the write make stale?
├── One or a few known lists/details
│   → invalidateQueries on the affected keys. The default. Prefer this.
├── The server already returned the updated resource
│   → setQueryData to write it directly, and consider invalidating anyway
└── I need instant feedback before the response arrives
    → optimistic update with snapshot and rollback
```

Under-invalidating leaves a stale screen; over-invalidating turns each write into a request cascade.

### Instant feedback: which layer?

```
Does the data you want to show optimistically live in the Query cache?
├── YES → optimistic mutation: snapshot in onMutate, rollback in onError
│         → TanStack Query - Mutations and Invalidation § 5
└── NO (local state, form with no remote cache)
    → React's useOptimistic (skill react-developer)
```

**Never both on the same data**: two diverging sources of truth (`REACT-FORM-07`, skill `react-developer`).

---

## 5.1 Diagnosis by symptom

An index over causes spread across satellites. The ID family names the satellite (§ 6).

### "I wrote to the server and the screen does not update"

In order of likelihood:

| # | Cause | How to confirm | Where |
| --- | --- | --- | --- |
| 1 | Did not invalidate, or invalidated a key that does not match | invalidation matches **by prefix**; `exact: true` or a prefix deeper than the list's key does not match | `TSQ-MUT-07` |
| 2 | The list's key is not what you think | order of loose array items matters; inside an object it does not | `TSQ-BASE-02/03` |
| 3 | `refetchType`: the list is on an unmounted route | default is `'active'`: inactive queries are only marked, and refetch on mount | `TSQ-MUT-07` |
| 4 | The query is disabled (`enabled: false`) | a disabled query **ignores** `invalidateQueries` and `refetchQueries` | `TSQ-PATTERN-10` |
| 5 | `staleTime: 'static'` on the list | `'static'` never refetches, not even on manual invalidation. Use `Infinity` for the extreme while keeping invalidation | `TSQ-CACHE-02` |
| 6 | `setQueryData` mutating in place | the cache is right and the screen does not change: structural sharing broke | `TSQ-MUT-08` |
| 7 | The list was copied into `useState` | the cache updates, the local copy lags | `REACT-PAT-03` (skill `react-developer`) |
| 8 | Not "does not update" but "updates late" | without `return`ing the invalidation Promise, the mutation leaves `pending` before the refetch ends | `TSQ-MUT-02` |

Causes 4 and 5 are the hardest to find: the invalidation runs, throws nothing, and does nothing.

### "Too many requests: every tab focus fires everything"

| Cause | Fix | Where |
| --- | --- | --- |
| `staleTime: 0`, the default | calibrate by data volatility, not by screen weight | `TSQ-CACHE-01` |
| Someone "fixed" it with `refetchOnWindowFocus: false` | **antipattern**: hides the symptom and leaves `refetchOnMount` with the opposite policy | `TSQ-CACHE-03` |
| High `staleTime` with default `gcTime` | does not revalidate while active, loses everything on screen change | `TSQ-CACHE-*` antipatterns |

A high `staleTime` does **not** isolate a query from its own writes: `invalidateQueries` cuts through any `staleTime` except `'static'`.

The Devtools show at runtime each entry's key and state: for causes 1, 2 and 4 they answer in seconds.

---

## 6. Normative rules

| Family | Subject | Satellite |
| --- | --- | --- |
| `TSQ-BASE-*` | keys, query functions, states | [Fundamentals](tanstack-query-fundamentals.md) |
| `TSQ-CACHE-*` | freshness, lifecycle, refetch | [Cache and Freshness](tanstack-query-cache-and-freshness.md) |
| `TSQ-MUT-*` | writes, invalidation, optimism | [Mutations and Invalidation](tanstack-query-mutations-and-invalidation.md) |
| `TSQ-PATTERN-*` | query patterns | [Query Patterns](tanstack-query-query-patterns.md) |
| `TSQ-SSR-*` | Suspense, SSR, network mode | [Suspense and SSR](tanstack-query-suspense-and-ssr.md) |

---

## 7. Skill contract

```
ALWAYS:     tanstack-query.md § 2 (mental model)
                              § 5 (decision trees)

ON DEMAND, via § 4:
            the task's satellite

IF the task involves a route/loader:
            tanstack-router-data-loading.md

NEVER:      every satellite at once
```

Implemented by the skills `tanstack-query` (write server-state code), `tanstack-router` (write routes, navigation, search, loaders) and `tanstack-review` (review or debug existing Query/Router code with probes).

Invariants:

1. **Remote data never becomes `useState`** as a source of truth (`REACT-PAT-03`).
2. **Every variable used in the query function belongs in the query key.**
3. **Every mutation declares what it invalidates**, or justifies why nothing needs invalidating.
4. **`staleTime` is a deliberate decision**, not a default accepted by omission.
5. **The HTTP boundary validates**: a response is not trustworthy just because it arrived.

---

## 8. Bridges

| Subject | Where |
| --- | --- |
| Routes, loaders, search params | [TanStack Router](tanstack-router.md) |
| Why not fetch data in `useEffect` | `REACT-EFFECT-06` (skill `react-developer`) |
| `<Suspense>` and Error Boundaries | skill `react-developer` |
| Optimistic update: which layer owns it | `REACT-FORM-07` (skill `react-developer`) |
| Contract validation at the boundary | `parse` in the `queryFn` (`TSQ-BASE-06`) |
| Expected × unexpected error, error body and status | the `http-contract` skill |
