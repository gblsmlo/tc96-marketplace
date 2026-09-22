# The seven tasks

> A task → note router. The satellite's content is not repeated here — it is cited.

| Task | Load (in this order) |
| --- | --- |
| 1. Reading remote data for the first time | [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) → [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) |
| 2. Deciding the freshness policy | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) |
| 3. Writing to the server and invalidating | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) |
| 4. Optimistic update with rollback | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) → [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) § 5 |
| 5. Paginated or infinite list | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/docs/tanstack-query-padroes-de-consulta.md) → [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) |
| 6. Integrating with the route loader | [TanStack Router - Carregamento de Dados](../../../../knowledge-base/docs/tanstack-router-carregamento-de-dados.md) § 8 → [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) § 7 |
| 7. Diagnosing the cache | see the **Diagnosis** section — the satellite follows from the symptom |

Suspense, SSR/hydration, cancellation and network mode live in [TanStack Query - Suspense e SSR](../../../../knowledge-base/docs/tanstack-query-suspense-e-ssr.md) and appear as a branch of other tasks, not as an entry task.

---


### 1. Reading remote data for the first time

**Load:** [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) (§ 3 keys, § 4 query functions, § 5 `status` × `fetchStatus`, § 7 `queryOptions`); [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) only when you reach the freshness policy — which is task 2 and **is not optional**.

**Check:**

- Is the `QueryClient` outside the render body? → `TSQ-BASE-01`
- Is the key an array, serializable and unique for that data? → `TSQ-BASE-02`
- Is **every** variable read by the `queryFn` in the key? It is the root cause of most stale-data bugs ([TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 2, point 3) → `TSQ-BASE-03`
- Does absence of data resolve to `null`, never `undefined`? → `TSQ-BASE-04`
- Is an HTTP error thrown explicitly — `fetch` does not reject on 4xx/5xx? → `TSQ-BASE-05`
- Does the response pass through a schema before becoming `data`? The HTTP boundary validates ([TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 7, invariant 5;) → `TSQ-BASE-06`
- Does the loading state distinguish the two axes: a query that can be disabled uses `isLoading`, not `isPending` → `TSQ-BASE-07`; and `fetchStatus: 'paused'` gets its own handling → `TSQ-BASE-08`
- If the query has more than one consumer, are the key and the function co-located in an exported `queryOptions`? → `TSQ-BASE-09`
- Is the package version pinned to an exact patch? → `TSQ-BASE-10`

**Do not:** store the result in `useState`, nor "save the response" anywhere. That creates the second source of truth that diverges on the first revalidation — `REACT-PAT-03` in [React - Patterns](../../../../knowledge-base/docs/react-patterns.md), and invariant 1 of the contract. If the current code fetches in a `useEffect`, the finding is `REACT-EFFECT-06` ([React - Efeitos e Sincronização](../../../../knowledge-base/docs/react-efeitos-e-sincronizacao.md)), and the fix is the query, not a better Effect.

### 2. Deciding the freshness policy (`staleTime` / `gcTime`)

**Load:** [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) (§ 2 lifecycle, § 3 `staleTime`, § 4 refetch triggers).

Walk the "Qual `staleTime`?" tree in [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 5 before writing the number. Calibration follows the **data's volatility**, not the screen.

**Check:**

- Is there an explicit `staleTime` on the query or in `defaultOptions`? Accepting the `0` default by omission is the antipattern; accepting it by decision is legitimate → `TSQ-CACHE-01`, and invariant 4 of the contract
- Does any `staleTime: 'static'` cover data that a mutation changes? It is the bug that does not show up in a test: the invalidation runs, does not fail and does nothing → `TSQ-CACHE-02`
- Do `staleTime` and `gcTime` govern different phases (active × inactive) and were they decided separately? The high/low combination is the worst possible one — see [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) § 2
- Was no refetch trigger switched off before calibrating `staleTime`? → `TSQ-CACHE-03`
- Does the `queryFn` return only JSON-compatible values (`Date`, `Map`, `Set` and class instances break structural sharing)? → `TSQ-CACHE-04`
- No `const { data,...rest } = useQuery(...)`? The rest switches off tracked properties → `TSQ-CACHE-05`
- If there is `initialData`: is it real and complete data → `TSQ-CACHE-06`, and does it carry `initialDataUpdatedAt` when it comes from another cache → `TSQ-CACHE-07`
- If there is `placeholderData`: does `isPlaceholderData` block an action or a decision based on the provisional value? → `TSQ-CACHE-08`

Background reasoning:.

### 3. Writing to the server and deciding what to invalidate

**Load:** [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) (§ 2 `useMutation`, § 3 `invalidateQueries`, § 4 `setQueryData`).

Walk the "Escrevi no servidor. E agora?" tree in [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 5. **A write does not update the screen — invalidation does** ([TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 2, point 5). No mutation leaves this skill without answering what it made stale, or justifying why nothing became stale (invariant 3).

**Check:**

- Does every write go through `useMutation` — `useQuery` never fires POST/PUT/PATCH/DELETE → `TSQ-MUT-01`
- Does the callback that invalidates or refetches **return** the Promise, so the mutation stays `pending` until the refetch finishes? Without it the button returns to "Save" with the list still stale, and the user clicks again → `TSQ-MUT-02`
- Are cache synchronization, invalidation and rollback in the `useMutation`, not in the `mutate` callbacks — which do not run if the component unmounts? Navigating, closing a modal and a toast are what belong to `mutate` → `TSQ-MUT-03`
- Does every `mutateAsync` have a `catch` or `try/catch`? It throws; `onError` handles the effect, not the Promise → `TSQ-MUT-04`
- No `retry` on a non-idempotent mutation? → `TSQ-MUT-05`
- Do concurrent mutations over the same resource declare `scope: { id }`? → `TSQ-MUT-06`
- Does the invalidation use the **most specific prefix** that covers the write's effect, never `invalidateQueries` without a filter? If you do not know what the mutation affects, the problem is the key hierarchy → `TSQ-MUT-07`
- If writing straight to the cache: is it immutable → `TSQ-MUT-08`, and does the updater return `undefined` when it receives `undefined`, so as not to create an entry out of a write → `TSQ-MUT-09`
- Does an expected failure (409, validation, no permission) become UI state, while an unexpected one goes to the boundary → `REACT-ASYNC-09` in [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md)
- **Are the callback signatures in v5's current form** — see the next section. Always check, never from memory.

**Calibrate the dose:** invalidating too little leaves a stale screen; invalidating too much turns every write into a cascade of requests. `refetchType` (default `'active'`) is what almost nobody configures and what decides the size of the burst — [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) § 3.

### 4. Optimistic update with rollback

**Load:** [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) § 5 (the complete cycle and the `variables` alternative); [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) § 5 **before choosing the layer**.

**First decide the layer — they are not two options that combine.** See the "Optimism has two layers" section below.

If the optimism lives in Query's cache, check:

- Does the cycle have the five steps: `cancelQueries` → snapshot → `setQueryData` → rollback in `onError` → invalidation in `onSettled` → `TSQ-MUT-10`
- Without `cancelQueries`, an in-flight refetch lands later and reverts the optimism — an intermittent bug, nearly impossible to reproduce on demand
- Does the snapshot travel **through `onMutate`'s return**, never through a `useRef`, a module variable or component state: with concurrent mutations, the second snapshot overwrites the first and the rollback restores the wrong state → `TSQ-MUT-11`
- Is the final invalidation in `onSettled`, not only in `onSuccess` — on error, the rollback restored a local value that also needs confirming against the source → `TSQ-MUT-12`
- Does `onSettled` have a `return`, so `isPending` lasts until the refetch finishes → `TSQ-MUT-02`
- **Was the signature of `onError`/`onSuccess`/`onSettled` checked in the docs**, not written from memory — see the next section.

Background reasoning:.

### 5. Paginated or infinite list

**Load:** [TanStack Query - Padrões de Consulta](../../../../knowledge-base/docs/tanstack-query-padroes-de-consulta.md) (§ 3 paginated, § 4 infinite); [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) § 6 for `placeholderData` × `initialData`.

First: does the page/cursor belong to the URL? If the user needs to share a link or use the back button, it is a search param — `REACT-PAT-10`, and the route comes in through `tanstack-router`. Pagination model in.

**Check (paginated):**

- Is the page in the `queryKey` and does the query use `placeholderData: keepPreviousData`? Without it the table disappears on every page change → `TSQ-PATTERN-04`
- Are the navigation controls disabled while `isPlaceholderData` is `true` — otherwise they decide about the previous page and skip or overshoot → `TSQ-PATTERN-05`

**Check (infinite):**

- Are `initialPageParam` and `getNextPageParam` declared → `TSQ-PATTERN-06`
- Is `fetchNextPage` guarded by `isFetchingNextPage`; is there only one fetch in flight per infinite query → `TSQ-PATTERN-07`
- Does a list with no natural ceiling declare `maxPages` — the refetch redoes **every** page in series → `TSQ-PATTERN-08`

**If the screen also has dependent, parallel, lazy, prefetched or `select`ed queries,** the same note covers: `TSQ-PATTERN-01` (justify the `enabled` waterfall), `TSQ-PATTERN-02` (a variable number uses `useQueries`, a Hook never in a loop — `REACT-HOOK-01`), `TSQ-PATTERN-03` (parallel ones under Suspense use `useSuspenseQueries`), `TSQ-PATTERN-09` (manual triggering is `enabled: false`, not `skipToken`), `TSQ-PATTERN-10` (a disabled query ignores `invalidateQueries` — do not keep in it data that a mutation has to keep fresh), `TSQ-PATTERN-11` and `TSQ-PATTERN-12` (prefetching), `TSQ-PATTERN-13` and `TSQ-PATTERN-14` (`select` does not validate and is stable).

### 6. Integrating with the route loader

**Load:** [TanStack Router - Carregamento de Dados](../../../../knowledge-base/docs/tanstack-router-carregamento-de-dados.md) § 8 ("External data loading"), which brings the criterion and the pattern; then [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) § 7 for the shared `queryOptions`. [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/docs/tanstack-router-route-context-e-code-splitting.md) § 2 when the `queryClient` has to reach the loader through context.

This is the boundary with `tanstack-router`: **the route is theirs, the cache is this skill's.** If the question is where the loader lives, how the route matches or what it inherits, delegate.

**Check:**

- **Who owns the data?** A native loader when the data belongs to one route and is consumed only there; TanStack Query when it is consumed by several routes, or needs mutation with selective invalidation, refetch on focus, pagination or optimistic updates. It is not "either/or": the official pattern uses both — the loader warms the cache, the component reads from the cache. Criterion in [TanStack Router - Carregamento de Dados](../../../../knowledge-base/docs/tanstack-router-carregamento-de-dados.md) § 8
- Do the loader and the component share the **same** `queryOptions` object, never two parallel constructions → `TSR-LOAD-15` (it is the same reason as `TSQ-BASE-09` and `TSQ-PATTERN-12`)
- Does the warming in the loader use `ensureQueryData`, which respects the cache — not `fetchQuery`, which always fetches → `TSR-LOAD-16`
- Was the router created with `defaultPreloadStaleTime: 0` → `TSR-LOAD-14`. **This is the item that slips most:** without it the router considers the preload fresh for 30 s, does not call the loader, and Query's `staleTime` is never consulted. The symptom is stale data after a mutation, with Query "right" and the router holding on
- No `fetch` in a `useEffect` inside the route: `REACT-EFFECT-06` still holds in there
- Where waiting and failure stop: `<Suspense>`/pending and an Error Boundary at the right level, never only at the root → `REACT-ASYNC-08`, `REACT-PAT-06`

If the screen uses `useSuspenseQuery`, SSR or hydration, then open [TanStack Query - Suspense e SSR](../../../../knowledge-base/docs/tanstack-query-suspense-e-ssr.md) — especially `TSQ-SSR-04` (a `QueryClient` per request on the server, or the cache leaks data between users), `TSQ-SSR-05` (`staleTime` > 0 on the client, or hydration discards what the server fetched) and `TSQ-SSR-07` (`<HydrationBoundary>`).

### 7. Diagnosing

See the **Diagnosis** section — the satellite to open follows from the symptom, and loading the wrong satellite here costs more than reading the table.
