# The seven tasks

> A task → note router, with what to check in each one.

| Task | Load (in this order) |
| --- | --- |
| Defining a new route | [TanStack Router - Routing Concepts](../../../../knowledge-base/tanstack-router-routing-concepts.md) → [TanStack Router - File-Based Routing](../../../../knowledge-base/tanstack-router-file-based-routing.md) → [TanStack Router - Route Trees](../../../../knowledge-base/tanstack-router-route-trees.md) |
| Understanding why a URL matches (or does not match) a route | [TanStack Router - Route Matching](../../../../knowledge-base/tanstack-router-route-matching.md) → [TanStack Router - Route Trees](../../../../knowledge-base/tanstack-router-route-trees.md) |
| Navigating between routes | [TanStack Router - Navegação](../../../../knowledge-base/tanstack-router-navegacao.md) → [TanStack Router - Routing Concepts](../../../../knowledge-base/tanstack-router-routing-concepts.md) |
| Handling search params | [TanStack Router - Search Params](../../../../knowledge-base/tanstack-router-search-params.md) → [TanStack Router - Navegação](../../../../knowledge-base/tanstack-router-navegacao.md) |
| Loading route data | [TanStack Router - Carregamento de Dados](../../../../knowledge-base/tanstack-router-carregamento-de-dados.md) → [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/tanstack-router-route-context-e-code-splitting.md) |
| Splitting the bundle | [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/tanstack-router-route-context-e-code-splitting.md) → [TanStack Router - File-Based Routing](../../../../knowledge-base/tanstack-router-file-based-routing.md) |
| A route tree outside the file convention | [TanStack Router - Virtual File Routes](../../../../knowledge-base/tanstack-router-virtual-file-routes.md) → [TanStack Router - Route Trees](../../../../knowledge-base/tanstack-router-route-trees.md) |

---

### 1. Defining a new route

**Load:** [TanStack Router - Routing Concepts](../../../../knowledge-base/tanstack-router-routing-concepts.md), then [TanStack Router - File-Based Routing](../../../../knowledge-base/tanstack-router-file-based-routing.md); [TanStack Router - Route Trees](../../../../knowledge-base/tanstack-router-route-trees.md) if the route joins an existing hierarchy.

**Check:**

- Does the project use file-based routing or routes in code? The project's convention decides where the file goes — confirm before creating it ([TanStack Router - File-Based Routing](../../../../knowledge-base/tanstack-router-file-based-routing.md) × [TanStack Router - Virtual File Routes](../../../../knowledge-base/tanstack-router-virtual-file-routes.md)).
- Does the file name produce the intended path, according to the documented convention — not according to intuition.
- What type is the route (root, layout, nested, dynamic, wildcard)? Check the taxonomy in [TanStack Router - Routing Concepts](../../../../knowledge-base/tanstack-router-routing-concepts.md) before choosing.
- Where the route fits in the tree, and what it inherits from the parent (layout, context, loader).
- The generated tree was updated, if the project depends on generation.
- The types line up: type safety is the router's point; a type error here signals a badly declared path or params.

### 2. Navigating

**Load:** [TanStack Router - Navegação](../../../../knowledge-base/tanstack-router-navegacao.md); [TanStack Router - Routing Concepts](../../../../knowledge-base/tanstack-router-routing-concepts.md) if the destination route is nested or dynamic.

**Check:**

- Declarative navigation (a link) or imperative (in a handler/effect)? Prefer the declarative one when the destination is known at render — that is what gives link semantics to the user and the browser.
- The destination's params and search params are complete and typed.
- Relative × absolute navigation: confirm the documented behavior before assuming.
- Replace history or stack it? The wrong choice breaks the back button.
- The destination exists in the route tree — do not navigate to a path built by string concatenation with no type check.

### 3. Search params

**Load:** [TanStack Router - Search Params](../../../../knowledge-base/tanstack-router-search-params.md); [TanStack Router - Navegação](../../../../knowledge-base/tanstack-router-navegacao.md) to write back to the URL.

**Check:**

- Does this state **belong** to the URL? Criterion in [React - Patterns](../../../../knowledge-base/react-patterns.md) § 2: it has to survive a refresh, be shareable by link or respond to the back button (`REACT-PAT-10`). A filter, a tab, pagination, sorting and a date range almost always belong; an open menu, hover and focus do not.
- If it belongs to the URL, the source of truth is the route — **not** a `useState` mirroring the param.
- The params are validated on read, with a schema: the URL is untrusted input.
- Default values and absent params have defined behavior.
- Writing preserves the other params instead of overwriting the whole query.
- Types derive from the schema, not from `any` or a manual cast.

### 4. Loading route data

**Load:** [TanStack Router - Carregamento de Dados](../../../../knowledge-base/tanstack-router-carregamento-de-dados.md); [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/tanstack-router-route-context-e-code-splitting.md) when the loader depends on injected context.

**Check:**

- Who owns the data: the route's loader, [TanStack Query](../../../../knowledge-base/tanstack-query-o-que-um-dev-frontend-precisa-saber.md)'s cache, or both integrated? Pick **one owner** and document it — two sources of truth diverge.
- No `fetch` in a `useEffect` for what the loader should load: `REACT-EFFECT-06` still holds inside a route.
- The loader's dependencies (params, search params, context) are declared, so that reloading happens when they change.
- Where waiting stops: a `<Suspense>`/pending boundary at the right level of the tree, not at the root by default.
- Where failure stops: every loading point needs an error boundary — `REACT-ASYNC-08` and `REACT-PAT-06` ([React - Patterns](../../../../knowledge-base/react-patterns.md) § 6).
- An expected error (a business 404, no permission) is error state/route, not an exception thrown to the boundary — `REACT-ASYNC-09`.
- Prefetching on hover/intent has been considered, if the satellite's docs support it.

### 5. Splitting the bundle

**Load:** [TanStack Router - Route Context e Code Splitting](../../../../knowledge-base/tanstack-router-route-context-e-code-splitting.md); [TanStack Router - File-Based Routing](../../../../knowledge-base/tanstack-router-file-based-routing.md) for the file convention that supports it.

**Check:**

- Is there a measurement of the problem before splitting? The same discipline as `REACT-PERF-01`: optimization without measurement does not go in.
- What is split is the route's **component/code**, not the critical loader — splitting data loading delays the route instead of speeding it up.
- The split respects the convention documented in the satellite; a manual `lazy` split on the side can duplicate what the router already does.
- There is a waiting boundary for the chunk, and it is not the root.
- Critical entry routes did not end up behind an unnecessary chunk.
