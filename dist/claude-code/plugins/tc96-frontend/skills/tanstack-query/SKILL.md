---
name: tanstack-query
description: Writes TanStack Query v5 code: queries, mutations, staleTime, optimistic, paging
source: "[TanStack Query](../../docs/tanstack/tanstack-query.md)"
docs:
  - /websites/tanstack_query
tags:
  - skill
  - tanstack-query
  - react
---

# tanstack-query

> **Source:** [TanStack Query](../../docs/tanstack/tanstack-query.md) (hub, § 5 decision trees) and five satellites. Rule bodies live only in the docs; this file routes and says what to check.
> **API surface:** Context7 `/websites/tanstack_query` for signatures in the installed version.

Writes or changes code whose data **comes from a server that someone else can change**.

| The question is… | Go to |
| --- | --- |
| state that belongs to the URL (filter, page, tab), or a route loader | `tanstack-router` |
| why existing code misbehaves, or a review of it | `tanstack-review` |
| ephemeral UI state, component structure | `react-developer` |
| freshness decided by server headers | `http-cache` |
| an Eden client as `queryFn` (it must throw) | `elysia-eden` |

## Load one satellite per task

Open only the row's doc and section. Open the hub only to walk a § 5 tree you cannot decide without.

| Task | Load | Check before calling it done |
| --- | --- | --- |
| Read remote data | [Fundamentals](../../docs/tanstack/tanstack-query-fundamentals.md) § 3-5, § 7 | `QueryClient` outside render (`TSQ-BASE-01`); every variable the `queryFn` reads is in the key (`-03`); absent data is `null` (`-04`); throw on `!res.ok` (`-05`); one exported `queryOptions` per data, shared by every consumer (`-09`) |
| Freshness | [Cache and Freshness](../../docs/tanstack/tanstack-query-cache-and-freshness.md) § 2-4 | explicit `staleTime` chosen by volatility (`TSQ-CACHE-01`); never `'static'` on data a mutation changes (`-02`); calibrate `staleTime` before switching any trigger off (`-03`) |
| Write and invalidate | [Mutations and Invalidation](../../docs/tanstack/tanstack-query-mutations-and-invalidation.md) § 2-4 | writes in `useMutation` (`TSQ-MUT-01`); the callback **returns** the invalidation Promise (`-02`); cache work in `useMutation`, toast/navigate in `mutate` (`-03`); the narrowest prefix that covers the effect (`-07`); `setQueryData` immutable and `undefined`-safe (`-08`, `-09`) |
| Optimistic update | same doc § 5 | pick **one** layer first (table below); `cancelQueries` → snapshot returned from `onMutate` → `setQueryData` → rollback in `onError` → invalidate in `onSettled` (`TSQ-MUT-10`, `-11`, `-12`) |
| Paginated or infinite list | [Query Patterns](../../docs/tanstack/tanstack-query-query-patterns.md) § 3-4 | page in the key + `placeholderData: keepPreviousData` (`TSQ-PATTERN-04`); controls disabled while `isPlaceholderData` (`-05`); `initialPageParam` + `getNextPageParam` (`-06`); `fetchNextPage` guarded (`-07`); `maxPages` (`-08`) |
| Dependent, parallel, lazy, `select` | same doc § 2, § 5-7 | the waterfall is justified (`TSQ-PATTERN-01`); a variable count uses `useQueries` (`-02`); manual trigger is `enabled: false` (`-09`) |
| Route loader | [TanStack Router - Data Loading](../../docs/tanstack/tanstack-router-data-loading.md) § 8 | a cache-respecting read with the component's `queryOptions` (`TSR-LOAD-15`, `-16`); router has `defaultPreloadStaleTime: 0` (`TSR-LOAD-14`) |
| Suspense, SSR, cancellation | [Suspense and SSR](../../docs/tanstack/tanstack-query-suspense-and-ssr.md) | one `QueryClient` per request on the server (`TSQ-SSR-04`); client `staleTime` > 0 (`-05`); `queryFn` passes `signal` (`-10`) |

## v5 facts not to write from memory

Verified on `@tanstack/query-core` 5.104.5:

```ts
onMutate:  (variables, context) => onMutateResult
onError:   (error, variables, onMutateResult, context) => …
onSuccess: (data, variables, onMutateResult, context) => …
onSettled: (data, error, variables, onMutateResult, context) => …
```

5.104.5 also deprecates `ensureQueryData`, `fetchQuery` and `prefetchQuery` in favour of `queryClient.query()`: `query({ ...options, staleTime: 'static' })` is the cache-respecting read. Use whichever the installed types do not mark deprecated.

The snapshot `onMutate` returns arrives as **`onMutateResult`, the third argument**. The last one, `context`, is `MutationFunctionContext` (`client`, `meta`, `mutationKey`), so a rollback reading `context.previous` restores nothing and fails silently (`TSQ-MUT-11`).

| Optimism lives in… | Use |
| --- | --- |
| one place, inside a form or Action | `useOptimistic` (skill `react-developer`) |
| several places, or it must survive navigation | the cache cycle above (`TSQ-MUT-10`) |
| one row of a list, no cache write needed | render the mutation's `variables` while `isPending` |

Never both layers in one flow; the optimistic value is never the source of truth (`REACT-FORM-07`).

## Self-check, then report

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-review/scripts/probes.sh src query
bunx tsc --noEmit
```

Treat each probe hit in a file you touched as a defect to fix or to justify. Then report: what each query and mutation decided (key, `staleTime`, what it invalidates and what it deliberately leaves alone), the IDs behind each choice, and what you did not verify.

## Example

"Approve an invoice; the list and the summary must reflect it." Key `['invoices', 'list', status]` with `staleTime` set; the mutation's `onSettled` returns `Promise.all` invalidating `['invoices','list']`, `['invoices','summary']` and the detail, and leaves `['customers']` alone because approving does not change a customer. Optimism, if asked for, follows the cycle with the snapshot read from the third argument. Cites `TSQ-BASE-03`, `TSQ-CACHE-01`, `TSQ-MUT-02`, `TSQ-MUT-07`, `TSQ-MUT-10`.
