---
title: TanStack Router - Route Trees
link: https://tanstack.com/router/latest/docs/framework/react/routing/route-trees
tags:
  - tanstack-router
  - routing
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Route Trees

## Contents

- [1. Concept: the URL is a tree, not a string](#1-concept-the-url-is-a-tree-not-a-string)
- [2. The five ways to build the tree](#2-the-five-ways-to-build-the-tree)
- [3. Reading the tree at runtime](#3-reading-the-tree-at-runtime)
- [4. Code-based routing](#4-code-based-routing)
- [5. Comparison](#5-comparison)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> **Topology**: what a route tree is, why nested routing maps URL to component tree, and the five ways to build it (flat, directory, mixed, virtual, code-based). Includes the code-based API (`createRootRoute`, `createRoute`, `addChildren`, `createRouter`).
>
> **Does not cover:** what each route type means ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · the file-name token table and generator config ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · which node wins when two match ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · the `rootRoute`/`route`/`index`/`layout`/`physical` API ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)).

Entry: [TanStack Router](tanstack-router.md) · Normative basis: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Concept: the URL is a tree, not a string

TanStack Router treats the URL not as a key in a flat map but as **a path down a tree**, and renders *every* node on the path, nested.

```
URL: /blog/posts/123

├── blog
│   ├── posts
│   │   ├── $postId
```

```tsx
<Blog>
  <Posts>
    <Post postId="123" />
  </Posts>
</Blog>
```

Each ancestor of the match is a place to hang UI, data, validation and fallback: layouts, cascading loaders and per-level error boundaries need no extra API.

**Draw the tree from which UI and data must be shared, not from the URL.** Two screens with the same URL prefix and no common layout should not be siblings: use the `_` suffix (non-nested, [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) § 6).

| ID | Rule |
| --- | --- |
| `TSR-TREE-01` | The tree hierarchy **MUST** be decided by shared layout, data and context, not by path similarity. An equal URL prefix does not force nesting. |

---

## 2. The five ways to build the tree

| Form | Where the structure lives | When to use |
| --- | --- | --- |
| **Flat routes** | file names with `.` | shallow trees; see everything at once |
| **Directory routes** | folders | deep subtrees or many helper files |
| **Mixed** | both | the real case for most projects |
| **Virtual file routes** | TS code pointing at files | an existing file structure you do not want to move ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)) |
| **Code-based** | TS code, no generation | § 4, discouraged by the source |

The source calls file-based *"the preferred and recommended way"*: *"less code for the same or better results"*.

### Flat

```
routes/
├── __root.tsx
├── index.tsx
├── about.tsx
├── posts.index.tsx          → /posts
├── posts.$postId.tsx        → /posts/$postId
└── posts.$postId.edit.tsx   → /posts/$postId/edit
```

The `.` is the level separator: `blog.post` is a child of `blog`.

### Directory

```
routes/
├── __root.tsx
├── index.tsx
└── settings/
    ├── route.tsx           ← the /settings layout
    ├── profile.tsx         → /settings/profile
    └── notifications.tsx   → /settings/notifications
```

**A folder alone is not a layout**: it contributes only the path segment. `/settings` has a layout only if `settings/route.tsx` (or the flat sibling `settings.tsx`) exists.

### Mixed

Supported and normal (the docs' own example):

```
/routes
├── __root.tsx
├── index.tsx
├── about.tsx
├── posts/
│   ├── index.tsx
│   ├── $postId.tsx
├── posts.$postId.edit.tsx
├── settings/
│   ├── profile.tsx
│   ├── notifications.tsx
├── _pathlessLayout/
│   ├── route-a.tsx
│   ├── route-b.tsx
├── files/
│   ├── $.tsx
```

The risk is defining the same route twice (`posts.index.tsx` and `posts/index.tsx`): the generator cannot choose.

| ID | Rule |
| --- | --- |
| `TSR-TREE-02` | The same route is **NEVER** defined by two files (flat and directory at once). Pick one style per subtree. |
| `TSR-TREE-03` | A shared layout in a directory **MUST** come from a `route.tsx` (or the same-name flat sibling); the folder alone only contributes a path segment. |

The generated `routeTree.gen.ts` and the generator config belong to [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md), including `TSR-FILE-05`, which forbids editing it by hand.

---

## 3. Reading the tree at runtime

```tsx
import { useRouter, useMatches } from '@tanstack/react-router'

function Breadcrumbs() {
  const matches = useMatches() // root to leaf, in order
  return <nav>{matches.map((m) => m.pathname).join(' / ')}</nav>
}
```

`useMatches()` returns the matched tree path: the basis for breadcrumbs and "which section am I in" UI.

---

## 4. Code-based routing

Fully typed, and discouraged: *"Code-based routing is not recommended for most applications."* File-based is sugar that generates exactly this.

```tsx
import {
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
} from '@tanstack/react-router'

const rootRoute = createRootRoute({
  component: () => <Outlet />,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: HomeComponent,
})

const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
  component: PostsLayout,
})

const postsIndexRoute = createRoute({
  getParentRoute: () => postsRoute,
  path: '/', // index of /posts
  component: PostsIndex,
})

const postDetailRoute = createRoute({
  getParentRoute: () => postsRoute,
  path: '$postId',
  component: PostDetail,
})

const routeTree = rootRoute.addChildren([
  indexRoute,
  postsRoute.addChildren([postsIndexRoute, postDetailRoute]),
])

export const router = createRouter({ routeTree })
```

Non-negotiable:

- `getParentRoute` is a required *function* returning the parent; through it TypeScript infers accumulated `params`, `search` and `context`.
- The root comes from `createRootRoute()` or `createRootRouteWithContext<T>()()`, never `createRoute` with an invented `id` such as `'__root__'`.
- An index route is `path: '/'`, not `id: 'index'` (that is a pathless layout).
- A pathless layout uses `id` instead of `path` (the `_` prefix equivalent):

```tsx
const authLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: '_auth', // no path: contributes no URL segment
  component: AuthLayout,
})
```

| ID | Rule |
| --- | --- |
| `TSR-TREE-04` | Code-based routing **NEVER** enters a new project without a recorded decision: the source explicitly discourages it for most applications. |
| `TSR-TREE-05` | Every `createRoute` **MUST** declare `getParentRoute: () => parent`; without it there is no ancestor type inference. |
| `TSR-TREE-06` | The root **MUST** come from `createRootRoute` / `createRootRouteWithContext`, **NEVER** from `createRoute`. |
| `TSR-TREE-07` | A code-based index route **MUST** be `path: '/'`. |
| `TSR-TREE-08` | A code-based pathless layout **MUST** use `id` and omit `path`. |

---

## 5. Comparison

| Aspect | File-based | Code-based |
| --- | --- | --- |
| Where the structure lives | file system | TS module |
| Boilerplate | minimal | one block per route + manual assembly |
| Type safety | generated by the plugin | manual, via `getParentRoute` |
| Automatic code splitting | yes (`autoCodeSplitting`) | manual |
| Official recommendation | **preferred** | "not recommended for most applications" |
| Legitimate case | default | tree assembled at runtime from configuration |

---

## Version notes

- Not in the docs (verified 2026-08-14): a `router.routeTree` API with `getRoute(id)`, `getRoutes()`, `findRouteByPath(path)`. Confirm in the source before navigating the tree programmatically.
- `createVirtualFileRoute` does not exist, nor a router option `virtualRoutes`. The real API is `rootRoute`/`route`/`index`/`layout`/`physical` from `@tanstack/virtual-file-routes`, consumed by the plugin option `virtualRouteConfig` ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)).
- A `_`-prefixed directory contributes no segment: `_dashboard/analytics.tsx` is `/analytics`, not `/dashboard/analytics`.
- There is no documented internal `RouteTree` class or priority table; the real precedence order is in [TanStack Router - Route Matching](tanstack-router-route-matching.md).

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Nesting by URL similarity with no common layout | Every child inherits a loader and UI it does not use | `_` suffix to un-nest (`TSR-TREE-01`) |
| `settings/profile.tsx` and `settings/notifications.tsx` with no `settings/route.tsx` | No layout at `/settings`; the shared header does not appear | Add `route.tsx` with `<Outlet />` (`TSR-TREE-03`) |
| `posts.index.tsx` **and** `posts/index.tsx` | Two definitions of one route; the generator cannot choose | One style per subtree (`TSR-TREE-02`) |
| `createRoute` without `getParentRoute` | The route does not link to the tree and loses type inference | Declare `getParentRoute` (`TSR-TREE-05`) |
| `createRoute({ id: '__root__' })` as root | `createRoute` does not create a root | `createRootRoute(...)` (`TSR-TREE-06`) |
| `id: 'index'` for a code-based index route | Becomes a pathless layout, not an index | `path: '/'` (`TSR-TREE-07`) |
| Migrating to code-based "for more control" | Loses type generation and automatic code splitting | Virtual file routes solve the real case (`TSR-TREE-04`) |
| Hand-edited `routeTree.gen.ts` | Regenerated on every dev and build | Change file names (`TSR-FILE-05`) |
