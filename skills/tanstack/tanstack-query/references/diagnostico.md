# Diagnosis: symptom → likely cause → satellite

The two most frequent questions about this library are two faces of the same axis. Start with the table, open **one** satellite.

### "The screen does not update"

| Symptom | Likely cause | Where |
| --- | --- | --- |
| Changing the filter/param does not refetch | a variable used in the `queryFn` left out of the key (`TSQ-BASE-03`) — the variations compete for the same cache entry | [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) |
| Saved and the list is still old | the mutation invalidates nothing, or invalidates a prefix that does not cover the effect (`TSQ-MUT-07`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) |
| Invalidation runs, does not error and has no effect | `staleTime: 'static'` on the query (`TSQ-CACHE-02`), or a disabled query holding the data (`TSQ-PATTERN-10`) | [TanStack Query - Cache e Frescor](../../../../knowledge-base/tanstack-query-cache-e-frescor.md) · [TanStack Query - Padrões de Consulta](../../../../knowledge-base/tanstack-query-padroes-de-consulta.md) |
| The cache is right in devtools, the screen is not | an in-place mutation instead of an immutable write (`TSQ-MUT-08`) — with no new reference, React does not see a change | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) |
| The button returns to "Save" before the list changes | an invalidation callback without `return`ing the Promise (`TSQ-MUT-02`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) |
| The optimistic update flickers and reverts | missing `cancelQueries` in `onMutate` (`TSQ-MUT-10`): an in-flight refetch lands later and reverts it | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) |
| The write errors and the screen stays optimistic | the rollback reading the wrong argument — the old `onError` signature (`TSQ-MUT-11`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) § 2 |
| The rollback restores the wrong value | the snapshot in a `useRef`/module, overwritten by a concurrent mutation (`TSQ-MUT-11`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) |
| A spinner that never goes away | `isPending` on a query with `enabled` (`TSQ-BASE-07`), or `fetchStatus: 'paused'` with no network (`TSQ-BASE-08`) | [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) § 5 |
| `isSuccess` with `data: undefined` | `select` validating or throwing (`TSQ-PATTERN-13`) | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/tanstack-query-padroes-de-consulta.md) |
| Stale data after a mutation, with Query apparently right | the router holding the preload: missing `defaultPreloadStaleTime: 0` (`TSR-LOAD-14`) | [TanStack Router - Carregamento de Dados](../../../../knowledge-base/tanstack-router-carregamento-de-dados.md) § 8 |

### "Too many requests"

| Symptom | Likely cause | Where |
| --- | --- | --- |
| Network on every mount, tab focus and reconnect | `staleTime` never declared (`TSQ-CACHE-01`): every piece of data is born stale | [TanStack Query - Cache e Frescor](../../../../knowledge-base/tanstack-query-cache-e-frescor.md) § 3 |
| A burst of requests on every write | `invalidateQueries` without a filter (`TSQ-MUT-07`), or `refetchType: 'all'` on a broad prefix | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) § 3 |
| Returning to the screen always reloads from scratch | a low `gcTime`: the cache is discarded before you come back | [TanStack Query - Cache e Frescor](../../../../knowledge-base/tanstack-query-cache-e-frescor.md) § 2 |
| Cascading refetches, unchanged data looking new | `Date`/`Map`/`Set` in the `queryFn` breaking structural sharing (`TSQ-CACHE-04`) | [TanStack Query - Cache e Frescor](../../../../knowledge-base/tanstack-query-cache-e-frescor.md) § 5 |
| A re-render on every `isFetching` | `const { data,...rest }` switching off tracked properties (`TSQ-CACHE-05`) | [TanStack Query - Cache e Frescor](../../../../knowledge-base/tanstack-query-cache-e-frescor.md) § 5 |
| Slow screens, latencies added up in series | a waterfall from `enabled` that the API could have resolved in one call (`TSQ-PATTERN-01`), or suspense queries side by side (`TSQ-PATTERN-03`, `TSQ-SSR-02`) | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/tanstack-query-padroes-de-consulta.md) · [TanStack Query - Suspense e SSR](../../../../knowledge-base/tanstack-query-suspense-e-ssr.md) |
| Invalidating the infinite list fires N requests | missing `maxPages` (`TSQ-PATTERN-08`): the refetch redoes every page in series | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/tanstack-query-padroes-de-consulta.md) § 4 |
| Type-ahead search leaves N requests in flight | the `queryFn` ignoring the `signal` (`TSQ-SSR-10`) | [TanStack Query - Suspense e SSR](../../../../knowledge-base/tanstack-query-suspense-e-ssr.md) § 5 · |
| The client refetches on hydration everything the server already fetched | `staleTime: 0` with SSR (`TSQ-SSR-05`) | [TanStack Query - Suspense e SSR](../../../../knowledge-base/tanstack-query-suspense-e-ssr.md) § 3 |

**The fix is almost never switching off a trigger.** `refetchOnWindowFocus: false` erases the symptom and leaves `refetchOnMount` with the opposite policy on the same cache — two contradictory rules about the same data. Calibrate `staleTime` first; switching off a trigger is fine-tuning afterwards, never a remedy → `TSQ-CACHE-03`.
