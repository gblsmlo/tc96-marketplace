# Sources of the TanStack family docs

Provenance for maintainers re-verifying a doc against upstream. No doc links here, so the build
and the `.skill` packages leave this file out and no run loads it.

Re-checked on 2026-10-25 against the installed packages (`@tanstack/react-query` 5.104.5,
`@tanstack/react-router` 1.170.46, `@tanstack/router-plugin`): the v5 mutation callback signatures,
`mutationOptions`, the 30 s `defaultPreloadStaleTime` default and the `CodeSplitGroupings` shape.

## TanStack Query

Doc: [tanstack-query.md](tanstack-query.md)

Verified on 2026-08-14:

- [Overview](https://tanstack.com/query/latest/docs/framework/react/overview) — the page declares no major version number; the satellites record the version each one verified

## TanStack Query - Fundamentals

Doc: [tanstack-query-fundamentals.md](tanstack-query-fundamentals.md)

Verified on 2026-08-14:

- [Overview](https://tanstack.com/query/latest/docs/framework/react/overview) — no version indicator on the page; version checked on npm
- [Installation](https://tanstack.com/query/latest/docs/framework/react/installation)
- [Queries](https://tanstack.com/query/latest/docs/framework/react/guides/queries)
- [Query Keys](https://tanstack.com/query/latest/docs/framework/react/guides/query-keys)
- [Query Functions](https://tanstack.com/query/latest/docs/framework/react/guides/query-functions) — `QueryFunctionContext` includes `client`; `direction` is deprecated
- [Query Options](https://tanstack.com/query/latest/docs/framework/react/guides/query-options) — `mutationOptions` not mentioned on this page
- [Important Defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults)
- [Query Retries](https://tanstack.com/query/latest/docs/framework/react/guides/query-retries)
- [Disabling Queries](https://tanstack.com/query/latest/docs/framework/react/guides/disabling-queries) — definition of `isLoading`
- [Network Mode](https://tanstack.com/query/latest/docs/framework/react/guides/network-mode) — `pending` + `paused`
- [TypeScript](https://tanstack.com/query/latest/docs/framework/react/typescript) — the TS floor is a rule ("last 2 years"), currently 5.4
- [`@tanstack/react-query` on npm](https://registry.npmjs.org/@tanstack/react-query) — `dist-tags.latest = 5.101.4`; v6 is beta, not `latest`

## TanStack Query - Cache and Freshness

Doc: [tanstack-query-cache-and-freshness.md](tanstack-query-cache-and-freshness.md)

Verified on 2026-08-14:

- [Caching](https://tanstack.com/query/latest/docs/framework/react/guides/caching)
- [Important Defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults) — `staleTime: 'static'` blocks the refetch flags even in `"always"`
- [Render Optimizations](https://tanstack.com/query/latest/docs/framework/react/guides/render-optimizations) — tracked properties and the rest-destructuring caveat
- [Initial Query Data](https://tanstack.com/query/latest/docs/framework/react/guides/initial-query-data) — `initialDataUpdatedAt`
- [Placeholder Query Data](https://tanstack.com/query/latest/docs/framework/react/guides/placeholder-query-data) — does not mention `keepPreviousData`
- [Window Focus Refetching](https://tanstack.com/query/latest/docs/framework/react/guides/window-focus-refetching) — does not document `'always'`
- [Query Retries](https://tanstack.com/query/latest/docs/framework/react/guides/query-retries)

## TanStack Query - Mutations and Invalidation

Doc: [tanstack-query-mutations-and-invalidation.md](tanstack-query-mutations-and-invalidation.md)

Verified on 2026-08-14:

- [Mutations](https://tanstack.com/query/latest/docs/framework/react/guides/mutations)
- [Query Invalidation](https://tanstack.com/query/latest/docs/framework/react/guides/query-invalidation)
- [Updates from Mutation Responses](https://tanstack.com/query/latest/docs/framework/react/guides/updates-from-mutation-responses)
- [Optimistic Updates](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates)
- [Filters](https://tanstack.com/query/latest/docs/framework/react/guides/filters)
- [QueryClient reference](https://tanstack.com/query/latest/docs/reference/QueryClient) — `refetchType`, `setQueryData`

## TanStack Query - Query Patterns

Doc: [tanstack-query-query-patterns.md](tanstack-query-query-patterns.md)

Verified on 2026-08-14:

- [Dependent Queries](https://tanstack.com/query/latest/docs/framework/react/guides/dependent-queries)
- [Parallel Queries](https://tanstack.com/query/latest/docs/framework/react/guides/parallel-queries)
- [Paginated Queries](https://tanstack.com/query/latest/docs/framework/react/guides/paginated-queries)
- [Infinite Queries](https://tanstack.com/query/latest/docs/framework/react/guides/infinite-queries)
- [Disabling / Pausing Queries](https://tanstack.com/query/latest/docs/framework/react/guides/disabling-queries)
- [Prefetching & Router Integration](https://tanstack.com/query/latest/docs/framework/react/guides/prefetching)
- [Render Optimizations](https://tanstack.com/query/latest/docs/framework/react/guides/render-optimizations) — `select`

## TanStack Query - Suspense and SSR

Doc: [tanstack-query-suspense-and-ssr.md](tanstack-query-suspense-and-ssr.md)

Verified on 2026-08-14:

- [Suspense](https://tanstack.com/query/latest/docs/framework/react/guides/suspense)
- [Server Rendering & Hydration](https://tanstack.com/query/latest/docs/framework/react/guides/ssr)
- [Advanced Server Rendering](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr)
- [Query Cancellation](https://tanstack.com/query/latest/docs/framework/react/guides/query-cancellation)
- [Network Mode](https://tanstack.com/query/latest/docs/framework/react/guides/network-mode)

## TanStack Router

Doc: [tanstack-router.md](tanstack-router.md)

Verified on 2026-08-14:

- [Overview](https://tanstack.com/router/latest/docs/framework/react/overview) — declares no major version number and does not mention TanStack Start; the three design goals in § 2 (type safety, search params as state, integrated data loading) are stated literally there

## TanStack Router - Routing Concepts

Doc: [tanstack-router-routing-concepts.md](tanstack-router-routing-concepts.md)

Verified on 2026-08-14:

- [Routing Concepts](https://tanstack.com/router/latest/docs/framework/react/routing/routing-concepts) — `*` documented as a v1 alternative for splat, no removal announced
- [File Naming Conventions](https://tanstack.com/router/latest/docs/framework/react/routing/file-naming-conventions)
- [Path Params](https://tanstack.com/router/latest/docs/framework/react/guide/path-params)
- [Router Context](https://tanstack.com/router/latest/docs/framework/react/guide/router-context)
- [Code-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/code-based-routing)

## TanStack Router - Route Trees

Doc: [tanstack-router-route-trees.md](tanstack-router-route-trees.md)

Verified on 2026-08-14:

- [Route Trees](https://tanstack.com/router/latest/docs/framework/react/routing/route-trees)
- [Code-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/code-based-routing)
- [File Naming Conventions](https://tanstack.com/router/latest/docs/framework/react/routing/file-naming-conventions)
- [File-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/file-based-routing)

## TanStack Router - Route Matching

Doc: [tanstack-router-route-matching.md](tanstack-router-route-matching.md)

Verified on 2026-08-14:

- [Route Matching](https://tanstack.com/router/latest/docs/framework/react/routing/route-matching)
- [Routing Concepts](https://tanstack.com/router/latest/docs/framework/react/routing/routing-concepts) — precedence of optional parameters
- [Path Params](https://tanstack.com/router/latest/docs/framework/react/guide/path-params)

## TanStack Router - File-Based Routing

Doc: [tanstack-router-file-based-routing.md](tanstack-router-file-based-routing.md)

Verified on 2026-08-14:

- [File-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/file-based-routing)
- [File Naming Conventions](https://tanstack.com/router/latest/docs/framework/react/routing/file-naming-conventions)
- [Installation with Vite](https://tanstack.com/router/v1/docs/framework/react/installation/with-vite)
- [File-Based Routing API Reference](https://tanstack.com/router/v1/docs/api/file-based-routing) — options and defaults; `target` not listed there

## TanStack Router - Virtual File Routes

Doc: [tanstack-router-virtual-file-routes.md](tanstack-router-virtual-file-routes.md)

Verified on 2026-08-14:

- [Virtual File Routes](https://tanstack.com/router/latest/docs/framework/react/routing/virtual-file-routes)
- [File-Based Routing API Reference](https://tanstack.com/router/v1/docs/api/file-based-routing) — `virtualRouteConfig` option
- [Installation with Vite](https://tanstack.com/router/v1/docs/framework/react/installation/with-vite) — plugin order

## TanStack Router - Navigation

Doc: [tanstack-router-navigation.md](tanstack-router-navigation.md)

Verified on 2026-08-14:

- [Navigation](https://tanstack.com/router/latest/docs/framework/react/guide/navigation) — `ToOptions`, `NavigateOptions`, `LinkOptions`, `<Link>`, `useNavigate`, `<Navigate>`, `router.navigate`, `useMatchRoute`
- [Path Params](https://tanstack.com/router/latest/docs/framework/react/guide/path-params) · [Preloading](https://tanstack.com/router/latest/docs/framework/react/guide/preloading)
- [Navigation Blocking](https://tanstack.com/router/latest/docs/framework/react/guide/navigation-blocking) — prose and examples diverge on the return of `shouldBlockFn` (§ 8)
- [Route Masking](https://tanstack.com/router/latest/docs/framework/react/guide/route-masking) · [Link Options](https://tanstack.com/router/latest/docs/framework/react/guide/link-options)
- [Authenticated Routes](https://tanstack.com/router/latest/docs/framework/react/guide/authenticated-routes) · [redirect](https://tanstack.com/router/latest/docs/framework/react/api/router/redirectFunction)
- [useRouter](https://tanstack.com/router/latest/docs/framework/react/api/router/useRouterHook) · [useMatch](https://tanstack.com/router/latest/docs/framework/react/api/router/useMatchHook) · [useMatches](https://tanstack.com/router/latest/docs/framework/react/api/router/useMatchesHook)

## TanStack Router - Search Params

Doc: [tanstack-router-search-params.md](tanstack-router-search-params.md)

Verified on 2026-08-14:

- [Search Params](https://tanstack.com/router/latest/docs/framework/react/guide/search-params) — `validateSearch`, adapters, `useSearch`, inheritance, middlewares, `.catch()` vs `.default()`, `fallback()`
- [Custom Search Param Serialization](https://tanstack.com/router/latest/docs/framework/react/guide/custom-search-param-serialization) — `parseSearchWith`/`stringifySearchWith` and the Base64 warnings
- [retainSearchParams](https://tanstack.com/router/latest/docs/framework/react/api/router/retainSearchParamsFunction) · [stripSearchParams](https://tanstack.com/router/latest/docs/framework/react/api/router/stripSearchParamsFunction)
- [useSearch](https://tanstack.com/router/latest/docs/framework/react/api/router/useSearchHook)
- [Navigation](https://tanstack.com/router/latest/docs/framework/react/guide/navigation) — object vs functional form in `<Link search>`

## TanStack Router - Data Loading

Doc: [tanstack-router-data-loading.md](tanstack-router-data-loading.md)

Verified on 2026-08-14:

- [Data Loading](https://tanstack.com/router/latest/docs/framework/react/guide/data-loading)
- [External Data Loading](https://tanstack.com/router/latest/docs/framework/react/guide/external-data-loading)
- [Preloading](https://tanstack.com/router/latest/docs/framework/react/guide/preloading)
- [Not Found Errors](https://tanstack.com/router/latest/docs/framework/react/guide/not-found-errors)
- [Authenticated Routes](https://tanstack.com/router/latest/docs/framework/react/guide/authenticated-routes)
- [RouteOptions (API)](https://tanstack.com/router/latest/docs/framework/react/api/router/RouteOptionsType)
- [useLoaderData (API)](https://tanstack.com/router/latest/docs/framework/react/api/router/useLoaderDataHook)
- [Route Matching](https://tanstack.com/router/latest/docs/framework/react/guide/route-matching) — could not be opened (returned `isNotFound`)

## TanStack Router - Route Context and Code Splitting

Doc: [tanstack-router-route-context-and-code-splitting.md](tanstack-router-route-context-and-code-splitting.md)

Verified on 2026-08-14:

- [Router Context](https://tanstack.com/router/latest/docs/framework/react/guide/router-context)
- [Code Splitting](https://tanstack.com/router/latest/docs/framework/react/guide/code-splitting)
- [Automatic Code Splitting](https://tanstack.com/router/latest/docs/framework/react/guide/automatic-code-splitting)
- [Authenticated Routes](https://tanstack.com/router/latest/docs/framework/react/guide/authenticated-routes)
- [External Data Loading](https://tanstack.com/router/latest/docs/framework/react/guide/external-data-loading)
- [RouteOptions (API)](https://tanstack.com/router/latest/docs/framework/react/api/router/RouteOptionsType)
