# The `TSR-*` families, by task

> **What changed.** The previous version of this skill carried a "doc status warning" saying
> the satellites were **under construction** and, for that reason, **cited no ID at all** — it
> borrowed `REACT-*`. The ten satellites exist today and add up to **102 declared `TSR-*`
> rules**. The warning is gone, and every task now has a citable family.

| Task | Family | Where |
| --- | --- | --- |
| defining a route, hierarchy, layout | `TSR-ROUTE-*` | [TanStack Router - Routing Concepts](../../../../knowledge-base/docs/tanstack-router-routing-concepts.md) |
| file convention and tree generation | `TSR-FILE-*` | [TanStack Router - File-Based Routing](../../../../knowledge-base/docs/tanstack-router-file-based-routing.md) |
| assembling and organizing the tree | `TSR-TREE-*` | [TanStack Router - Route Trees](../../../../knowledge-base/docs/tanstack-router-route-trees.md) |
| why a URL matches (or does not) | `TSR-MATCH-*` | [TanStack Router - Route Matching](../../../../knowledge-base/docs/tanstack-router-route-matching.md) |
| a tree outside the file convention | `TSR-VIRTUAL-*` | [TanStack Router - Virtual File Routes](../../../../knowledge-base/docs/tanstack-router-virtual-file-routes.md) |
| navigating, `<Link>`, `useNavigate`, preloading | `TSR-NAV-*` | [TanStack Router - Navegação](../../../../knowledge-base/docs/tanstack-router-navegacao.md) |
| typed and validated search params | `TSR-SEARCH-*` | [TanStack Router - Search Params](../../../../knowledge-base/docs/tanstack-router-search-params.md) |
| loader, `beforeLoad`, cache integration | `TSR-LOAD-*` | [TanStack Router - Carregamento de Dados](../../../../knowledge-base/docs/tanstack-router-carregamento-de-dados.md) |
| route context (typed dependency injection) | `TSR-CTX-*` | [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/docs/tanstack-router-route-context-e-code-splitting.md) |
| per-route code splitting | `TSR-SPLIT-*` | [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/docs/tanstack-router-route-context-e-code-splitting.md) |

Full index, by section: `mapa-de-ids.md`.

---

## The rules that decide most cases

**Navigation**

| Rule | What it requires |
| --- | --- |
| `TSR-NAV-01` | `to` **never** takes an interpolated string — a path param goes in `params`, a query in `search`, a fragment in `hash` |
| `TSR-NAV-02` | a destination known at render is **`<Link>`**; `useNavigate` in an `onClick` is not |
| `TSR-NAV-03` | a relative `to` (`.`, `..`) **requires** `from` — without it the origin is `/`, not the current route |
| `TSR-NAV-04` | `from` comes from `Route.fullPath`, never from a string literal repeated in the JSX |
| `TSR-NAV-09` | navigation that **consumes** the current route (post-login, post-submit) uses `replace: true` |

**Search params**

| Rule | What it requires |
| --- | --- |
| `TSR-SEARCH-01` | a route that reads search **declares `validateSearch`** — without a schema there is no type, no default and no guarantee of shape |
| `TSR-SEARCH-02` | the source is `useSearch` — never `window.location.search`, `URLSearchParams` or another library's hook |
| `TSR-SEARCH-03` | every key defines behavior for **absent** and for **invalid**; a happy-path-only schema validates nothing |
| `TSR-SEARCH-05` | Zod v3 with `.catch` **requires** the adapter's `fallback`, otherwise the type collapses to `unknown` |
| `TSR-SEARCH-07` | updating **one** key uses the functional form with a spread — an object literal replaces the whole search |

**Loading**

| Rule | What it requires |
| --- | --- |
| `TSR-LOAD-01` | first-render data comes from the `loader`, **never** from a `fetch` in a `useEffect` (alias of `REACT-EFFECT-06`) |
| `TSR-LOAD-03` · `TSR-LOAD-04` | `loaderDeps` returns **only** the search params the loader reads — and the loader does not read search from `location` |
| `TSR-LOAD-05` | `beforeLoad` is context, guard and redirect; fetching screen data there is **serial** and blocks the parallel loaders |
| `TSR-LOAD-06` | an access guard is `throw redirect(...)` in `beforeLoad`, not a `navigate` in an effect |
| `TSR-LOAD-09` | a route with a `loader` has its own `errorComponent` or a `defaultErrorComponent` on the router |
| `TSR-LOAD-14` | a loader using Query requires `defaultPreloadStaleTime: 0` — **one** cache decides freshness. `TSR-NAV-08` is an alias; cite the canonical one |

---

## Related

- `por-tarefa.md` — what to load and check in each task
- `mapa-de-ids.md` — the 102 `TSR-*` by satellite and section
- `tanstack-query` — the other cache, and the `TSR-LOAD-14` rule that reconciles them
