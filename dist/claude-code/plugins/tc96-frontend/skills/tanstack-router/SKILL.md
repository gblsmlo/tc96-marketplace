---
name: tanstack-router
description: Writes TanStack Router code: routes, Link, search params, loaders, guards, lazy
source: "[TanStack Router](../../docs/tanstack/tanstack-router.md)"
docs:
  - /websites/tanstack_router
tags:
  - skill
  - tanstack-router
  - react
---

# tanstack-router

> **Source:** [TanStack Router](../../docs/tanstack/tanstack-router.md) (hub, § 5 decision trees, § 6.1 canonical IDs) and nine satellites. Rule bodies live only in the docs; this file routes and says what to check.
> **API surface:** Context7 `/websites/tanstack_router` for signatures in the installed version.

Writes or changes routes, navigation, URL state and route loading.

| The question is… | Go to |
| --- | --- |
| the remote data itself: freshness, invalidation, optimism | `tanstack-query` |
| why existing route code misbehaves, or a review of it | `tanstack-review` |
| the inside of a component | `react-developer` |
| where a file lives in the feature | `react-structure` |
| a multi-step form (the step is the URL's, the values are the form's) | `react-hook-form` |

## Load one satellite per task

Open only the row's doc. The project's convention (file-based or code-based, `routeTree.gen.ts` or `addChildren`) decides where code goes: read one existing route before writing.

| Task | Load | Check before calling it done |
| --- | --- | --- |
| Define or nest a route | [Routing Concepts](../../docs/tanstack/tanstack-router-routing-concepts.md); [File-Based Routing](../../docs/tanstack/tanstack-router-file-based-routing.md) § 2 for the file grammar | route type chosen from § 8's matrix (`TSR-ROUTE-*`); file name yields the intended path (`TSR-FILE-*`) |
| Why a URL matches | [Route Matching](../../docs/tanstack/tanstack-router-route-matching.md) | specificity, never declaration order (`TSR-MATCH-*`) |
| Tree outside the folder convention | [Virtual File Routes](../../docs/tanstack/tanstack-router-virtual-file-routes.md) · [Route Trees](../../docs/tanstack/tanstack-router-route-trees.md) | `TSR-VIRTUAL-*`, `TSR-TREE-*` |
| Navigate | [Navigation](../../docs/tanstack/tanstack-router-navigation.md) § 2, § 5 | `to` is a route path, params in `params`, query in `search` (`TSR-NAV-01`); a destination known at render is `<Link>` (`-02`); relative `to` has `from` (`-03`) from `Route.fullPath` (`-04`); navigation that consumes the route (post-login, post-submit) uses `replace: true` (`-09`) |
| Search params | [Search Params](../../docs/tanstack/tanstack-router-search-params.md) § 2-6 | `validateSearch` on every route that reads search (`TSR-SEARCH-01`); read with `useSearch` only (`-02`); every key defines absent **and** invalid (`-03`); one-key updates use the function form with a spread (`-07`); Zod v3 `.catch` needs `fallback` (`-05`) |
| Load route data | [Data Loading](../../docs/tanstack/tanstack-router-data-loading.md) § 2-8 | first-render data from `loader`, never `useEffect` (`TSR-LOAD-01`); `loaderDeps` returns only the keys the loader reads (`-03`, `-04`); `beforeLoad` holds context, guard and redirect, never screen data (`-05`); `errorComponent` per loader route or a router default (`-09`); with Query: a cache-respecting read (`ensureQueryData`, or `queryClient.query({ ...opts, staleTime: 'static' })` where the installed types deprecate it) + shared `queryOptions` + `defaultPreloadStaleTime: 0` (`-14`, `-15`, `-16`) |
| Guard a route | hub § 5.1 · [Route Context and Code Splitting](../../docs/tanstack/tanstack-router-route-context-and-code-splitting.md) § 2-4 | `throw redirect(...)` in `beforeLoad`, never `navigate` in an effect (`TSR-LOAD-06`); auth reaches `beforeLoad` through router context (`TSR-CTX-*`); the return target is validated as an internal path (Search Params § 9) |
| Split the bundle | same doc § 6-9 | split the component, never the critical `loader`; the convention the project already uses (`TSR-SPLIT-*`) |

Aliases: `TSR-LOAD-01` = `REACT-EFFECT-06`, `TSR-NAV-08` = `TSR-LOAD-14`. Cite the canonical one (hub § 6.1).

## Self-check, then report

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-review/scripts/probes.sh src router
bunx tsc --noEmit
```

A type error on `to`, `params` or `search` is the router telling you the path or schema is wrong: fix the declaration, never cast. Treat each probe hit in a file you touched as a defect to fix or justify. Report each route decision with its ID, and what you did not verify.

## Example

"The invoice filter must survive refresh and the back button." `validateSearch` with `status`, `page`, `sort`, each with a default and a catch; the component reads `Route.useSearch()`; filter changes call `navigate({ search: (prev) => ({ ...prev, status, page: 1 }) })`; `loaderDeps` returns `{ status, page, sort }`; the loader warms the cache with `invoicesQuery(deps)`; the router sets `defaultPreloadStaleTime: 0`; the detail link is `<Link to="/invoices/$invoiceId" params={{ invoiceId }}>`. Cites `TSR-SEARCH-01`, `TSR-SEARCH-07`, `TSR-LOAD-03`, `TSR-LOAD-14`, `TSR-NAV-01`.
