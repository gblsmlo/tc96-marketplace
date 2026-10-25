---
title: TanStack Router
link: https://tanstack.com/router/latest/docs/framework/react/overview
tags:
  - tanstack-router
  - routing
  - frontend
  - reference
  - agent-context
source: "Official documentation: tanstack.com/router/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Router

## Contents

- [1. How to use these docs](#1-how-to-use-these-docs)
- [2. Mental model](#2-mental-model)
- [3. The two ways to declare routes](#3-the-two-ways-to-declare-routes)
- [4. Task map](#4-task-map)
- [5. Decision trees](#5-decision-trees)
- [5.1 Protect a route](#51-protect-a-route)
- [6. Normative rules](#6-normative-rules)
- [7. Skill contract](#7-skill-contract)
- [8. Bridges](#8-bridges)

> Entry point for routing: decides what to load, gives the mental model, exposes rules citable by ID (`TSR-*`). When it diverges from [tanstack.com/router](https://tanstack.com/router/latest/docs/framework/react/overview), the source wins. Upstream sources live in `SOURCES.md` next to these docs, for maintainers.

---

## 1. How to use these docs

| Step | Load | When |
| --- | --- | --- |
| 1 | This doc (§ 2, § 4, § 5) | Every task that touches routes |
| 2 | The task's satellite, via § 4 | When it touches a concrete API |
| 3 | The `react-developer` skill | If the task also touches component or state |

Never load every satellite. All examples are TypeScript: the library is built around type inference, and plain JavaScript loses most of its value.

---

## 2. Mental model

1. **A route is a typed contract, not a string.** `to="/posts/$postId"` is checked at compile time: a missing route, param or invalid search param is a **type error**. A raw `href` or a concatenated path throws that guarantee away.
2. **Search params are application state.** The docs describe them as *"like having `useState` right in the URL"*: parsed from JSON, schema-validated, typed, with fine-grained subscription. Filter, tab, sort and pagination belong there, not in `useState`. Same conclusion as `REACT-PAT-10` (skill `react-developer`), seen from the router side.
3. **Data loads before the component.** The `loader` fires during the transition, in parallel with code loading. Fetching in the component creates the waterfall `REACT-EFFECT-06` (skill `react-developer`) forbids.
4. **The route tree is hierarchical in three things at once:** layout (what wraps what), context (what flows down as a typed dependency) and data (what is already loaded when the child renders). Drawing the tree decides all three.
5. **Match precedence is deterministic**: by specificity, not declaration order ([TanStack Router - Route Matching](tanstack-router-route-matching.md)).

---

## 3. The two ways to declare routes

| | File-based | Code-based |
| --- | --- | --- |
| Where the route lives | in the file path | in an explicit `createRoute()` |
| Type generation | automatic, by build plugin | manual, via `getParentRoute` |
| Official recommendation | **preferred** | when file-based cannot express the structure |

Both **coexist**; virtual file routes bridge them, mapping an arbitrary physical structure to a logical tree.

---

## 4. Task map

If the task is not here, it was not verified in these docs: check the source.

| I need to... | Satellite |
| --- | --- |
| Understand route anatomy, root, index, dynamic, splat, layout, pathless | [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) |
| Name files and folders, understand the conventions and `routeTree.gen.ts` | [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) |
| Build the tree in code, type `getParentRoute`, compare approaches | [TanStack Router - Route Trees](tanstack-router-route-trees.md) |
| Know why a route matches (or not) and in what order | [TanStack Router - Route Matching](tanstack-router-route-matching.md) |
| Map an unconventional file structure to routes | [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| Navigate: `<Link>`, `useNavigate`, `redirect`, preload, blocking navigation away | [TanStack Router - Navigation](tanstack-router-navigation.md) |
| Read and write typed, validated search params | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| Load data: `loader`, `beforeLoad`, pending/error, Query integration | [TanStack Router - Data Loading](tanstack-router-data-loading.md) |
| Guard a route: authentication (`beforeLoad` + `throw redirect`) and role authorization | [TanStack Router - Data Loading](tanstack-router-data-loading.md) · § 5.1 below |
| Inject per-route dependencies and split the bundle | [TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md) |
| `notFound()`, `notFoundComponent`, `router.invalidate()` | [TanStack Router - Data Loading](tanstack-router-data-loading.md) |
| Search middlewares (`stripSearchParams`, `retainSearchParams`) and custom serialization | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| `useMatches`, `useRouterState`, breadcrumbs | [TanStack Router - Navigation](tanstack-router-navigation.md) |
| Route masking and `linkOptions` | [TanStack Router - Navigation](tanstack-router-navigation.md) |

---

## 5. Decision trees

### What kind of route do I need?

```
Does the path have a variable segment?
├── YES
│   ├── One segment → dynamic route  /posts/$postId
│   └── The whole rest of the path → splat  /files/$
└── NO
    └── Do I need to wrap children in shared UI?
        ├── YES
        │   ├── and the wrapper shows in the URL → layout route
        │   └── and it does NOT show in the URL → pathless layout route
        └── NO
            ├── It is the content of the parent's own path → index route
            └── General case → basic route
```

### How do I navigate?

```
Is navigation started by a user click on an element?
├── YES → <Link>. Always.
│         Real href (new tab, indexable, accessible), type safety, preload.
└── NO
    ├── Consequence of an action (submit, timeout, login) → useNavigate()
    └── Inside beforeLoad/loader (route guard, invalid session)
        → redirect()  (thrown, not returned)
```

`<Link>` is the only form that produces a truly navigable element.

### Where do I keep this state?

```
Must the state survive refresh, be shareable by link, or respond to the back button?
├── YES → route search param, schema-validated
│         (filter, tab, page, sort, date range)
│         → TanStack Router - Search Params
└── NO → ephemeral UI state: useState in the component
          (open menu, hover, focus, field draft) → skill react-developer
```

### How do I load this route's data?

```
Is the data required for the route to render?
├── NO → load in the component, under <Suspense> or with its own state
└── YES
    ├── Does the project use TanStack Query?
    │   ├── YES → loader calls ensureQueryData; component uses useSuspenseQuery.
    │   │         The cache belongs to Query; the loader only guarantees it was fetched.
    │   │         → TanStack Query
    │   └── NO → native loader + useLoaderData, with the route's staleTime
    └── Is it an access check, not data?
        → beforeLoad, which runs first and can redirect()
```

---

## 5.1 Protect a route

```
Is the user authenticated?
├── NO → throw redirect({ to: '/login', search: { redirect: location.href } })
│         in beforeLoad. Never in a component or Effect: by then the protected
│         loader already ran and the data already leaked.
└── YES
    └── Has the required role/permission?
        ├── NO → do NOT redirect. It is an expected error (403): render the
        │         access-denied screen as route STATE. Throwing to a boundary
        │         turns "no permission" into a generic error screen. → REACT-ASYNC-09
        └── YES → proceed
```

- **`redirect()` must be thrown.** A bare `redirect({...})` creates an object and discards it: no guard, no error. `TSR-NAV-10`.
- **The router guard is not security.** It improves UX; real authorization belongs to the backend. The WorkOS RBAC enforcement-layer table (§ 4, outside this family) classifies `beforeLoad` as the UX layer. `TSR-NAV-12` and `TSR-CTX-07`.
- **Return-to-destination after login** goes in a search param and is consumed on `/login`, with mandatory anti-open-redirect validation: [TanStack Router - Search Params](tanstack-router-search-params.md).

---

## 6. Normative rules

Families per satellite; each satellite numbers its own contiguously.

| Family | Subject | Satellite |
| --- | --- | --- |
| `TSR-ROUTE-*` | route types and anatomy | [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) |
| `TSR-FILE-*` | file conventions | [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) |
| `TSR-TREE-*` | assembling the tree | [TanStack Router - Route Trees](tanstack-router-route-trees.md) |
| `TSR-MATCH-*` | match precedence | [TanStack Router - Route Matching](tanstack-router-route-matching.md) |
| `TSR-VIRTUAL-*` | virtual routes | [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| `TSR-NAV-*` | navigation | [TanStack Router - Navigation](tanstack-router-navigation.md) |
| `TSR-SEARCH-*` | search params | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| `TSR-LOAD-*` | data loading | [TanStack Router - Data Loading](tanstack-router-data-loading.md) |
| `TSR-CTX-*` · `TSR-SPLIT-*` | context and code splitting | [TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md) |

### 6.1 Canonical IDs

Principles repeated across satellites: **always cite the canonical**; aliases do not appear in review.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| `defaultPreloadStaleTime: 0` with TanStack Query in the loader | `TSR-LOAD-14` | `TSR-NAV-08` |
| Same `queryOptions` object between loader and component | `TSR-LOAD-15` | `TSQ-BASE-09`, `TSQ-PATTERN-12` |
| Root via `createRootRouteWithContext<T>()()` | `TSR-CTX-02` | `TSR-ROUTE-03` |
| Route guard does not replace backend authorization | `TSR-CTX-07` | `TSR-NAV-12` |
| Reading data outside the route file requires `getRouteApi` | `TSR-LOAD-07` | `TSR-ROUTE-05` |
| Critical × lazy boundary in code splitting | `TSR-SPLIT-01` | `TSR-SPLIT-02` (the complement of the same rule) |

Two React principles the Router does **not** redefine; cite the React ID:

| Principle | Canonical | Where the Router mentions it |
| --- | --- | --- |
| Route data never comes from `fetch` in `useEffect` | `REACT-EFFECT-06` | `TSR-LOAD-01` is an alias |
| A value that lives in search is never copied into `useState` | `REACT-PAT-01` + `REACT-PAT-03` | `TSR-SEARCH-09` is an alias |

---

## 7. Skill contract

```
ALWAYS:     tanstack-router.md § 2 (mental model), § 5 (decision trees)
ON DEMAND:  the task's satellite, via § 4
IF the task also touches component/state: skill react-developer
NEVER:      every satellite at once
```

Skills that implement it:

- `tanstack-router`: write routes, navigation, search params, loaders.
- `tanstack-review`: review or debug existing Router (and Query) code with probes.
- `tanstack-query`: the server-state side, when the loader integrates with Query.

Invariants the skills enforce:

1. **Type safety is not optional.** A string-built path, `any` in params or search, and `@ts-expect-error` on a route are regressions.
2. **Verify before asserting.** An API not in § 4 was not verified here: check the source and update the doc.
3. **The source wins.** A divergence from tanstack.com is a bug in this doc.
4. **Search param before local state**, whenever the § 5 criterion applies.
5. **Data in the loader before the component**, when the data is a condition to render.

---

## 8. Bridges

| Subject | Where |
| --- | --- |
| Server state, cache, invalidation | skill `tanstack-query` · [TanStack Query](tanstack-query.md) |
| Component state, effects, Suspense | skill `react-developer` |
| "Does this belong in the URL?" from the React side | `REACT-PAT-10` (skill `react-developer`) |
| Why not fetch data in `useEffect` | `REACT-EFFECT-06` (skill `react-developer`) |
| Schema validation of search params | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| Error and waiting boundaries | skill `react-developer` |
