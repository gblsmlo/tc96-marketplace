---
title: TanStack Router - Routing Concepts
link: https://tanstack.com/router/latest/docs/framework/react/routing/routing-concepts
tags:
  - tanstack-router
  - routing
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Routing Concepts

## Contents

- [1. Concept: a route is a node, not a screen](#1-concept-a-route-is-a-node-not-a-screen)
- [2. Root route](#2-root-route)
- [3. Basic routes and index routes](#3-basic-routes-and-index-routes)
- [4. Dynamic segments, prefixes and suffixes](#4-dynamic-segments-prefixes-and-suffixes)
- [5. Splat / catch-all](#5-splat--catch-all)
- [6. Layout routes: with and without a path](#6-layout-routes-with-and-without-a-path)
- [7. Organization with no route effect](#7-organization-with-no-route-effect)
- [8. Decision matrix](#8-decision-matrix)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> Route types and what each means: root, basic, index, dynamic segment, optional param, segment prefix/suffix, splat, layout, pathless layout, non-nested, excluded files and route groups. Normative basis of the other four routing docs.
>
> **Does not cover:** tree topology and code-based mode ([TanStack Router - Route Trees](tanstack-router-route-trees.md)) · the file-token table and plugin config ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · which route wins when two match ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · routes declared in code instead of files ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)) · `Link`/`navigate` ([TanStack Router - Navigation](tanstack-router-navigation.md)) · `validateSearch` ([TanStack Router - Search Params](tanstack-router-search-params.md)) · `loader` ([TanStack Router - Data Loading](tanstack-router-data-loading.md)) · `context` and code splitting ([TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md)).

Entry: [TanStack Router](tanstack-router.md) · Normative basis: this doc (`TSR-ROUTE-*`)

---

## 1. Concept: a route is a node, not a screen

The costliest mental-model error is "route = page". A route is a **tree node** that, when the URL matches it, contributes three things at once:

1. a piece of the URL path (or none);
2. one level of the rendered component tree;
3. a point where `loader`, `beforeLoad`, `validateSearch` and `context` run before the children.

Route types are combinations of two independent questions:

| | contributes a URL segment | does not |
| --- | --- | --- |
| **renders a component level** | basic, dynamic, splat, layout route | pathless layout (`_prefix`) |
| **renders nothing by itself** | route group `(name)` | excluded file `-name` |

`_` prefix, `_` suffix and `(parentheses)` answer different questions, not variations of one feature.

*"Paths are automatically written and managed by the router for you via the TanStack Router Bundler Plugin or Router CLI."* The literal in `createFileRoute('/posts/$postId')` is written back by the generator from the file name; editing it is editing a generated artifact.

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-01` | The path literal passed to `createFileRoute` is **NEVER** written or fixed by hand: it is generated from the file name. To change the path, rename the file. |

---

## 2. Root route

The tree root. From the source: *"It has no path"* · *"It is **always** matched"* · *"Its `component` is **always** rendered"*. In file-based it lives in a fixed-name file: *"The root route file must be named `__root.tsx` and must be placed in the root of the configured `routesDirectory`."*

```tsx
// src/routes/__root.tsx
import { Outlet, createRootRoute } from '@tanstack/react-router'

export const Route = createRootRoute({
  component: () => (
    <>
      <nav>…</nav>
      <Outlet />
    </>
  ),
})
```

Typed context (a `QueryClient`, auth state) changes the factory:

```tsx
import { createRootRouteWithContext } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'

interface RouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<RouterContext>()({
  component: RootComponent,
})
```

Note the **double call** `createRootRouteWithContext<T>()(routeOptions)`, required by the source instead of `createRootRoute()`. Required context properties not passed in the initial router context are a TypeScript error. How context flows: [TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md).

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-02` | The root route file **MUST** be named `__root.tsx` and sit at the root of `routesDirectory`. |
| `TSR-ROUTE-03` | Typed router context **MUST** be declared with `createRootRouteWithContext<T>()(...)`, never with `createRootRoute()` plus a cast. |

---

## 3. Basic routes and index routes

A **basic route** matches an exact path:

```tsx
// src/routes/about.tsx  →  /about
export const Route = createFileRoute('/about')({
  component: AboutComponent,
})
```

An **index route** fills the parent when the URL stops exactly on it: *"Index routes specifically target their parent route when it is **matched exactly and no child route is matched**."* Syntax: trailing slash in the path, `index` token in the file.

```tsx
// src/routes/posts.index.tsx  →  /posts (when no child matches)
export const Route = createFileRoute('/posts/')({
  component: PostsIndexComponent,
})
```

Recurring bug: at `/posts`, `posts.tsx` with children renders only its layout and an empty `<Outlet />`; `posts.index.tsx` fills it.

```
/posts        → PostsLayout (posts.tsx) + PostsIndex (posts.index.tsx)
/posts/123    → PostsLayout (posts.tsx) + PostDetail (posts.$postId.tsx)
```

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-04` | Every route with children that must show content at its own exact URL **MUST** have a sibling index route (`.index.tsx` / `index.tsx`). Without it, the `<Outlet />` stays empty. |

---

## 4. Dynamic segments, prefixes and suffixes

`$` makes a segment a `param`, at any depth: `/users/$userId/posts/$postId` yields both params.

```tsx
// src/routes/posts.$postId.tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: ({ params }) => fetchPost(params.postId),
  component: PostComponent,
})

function PostComponent() {
  const { postId } = Route.useParams() // postId: string
  return <h1>Post {postId}</h1>
}
```

Outside the route file (code-split or shared component), read with an explicit `from`, or `getRouteApi` to avoid importing the `Route` config:

```tsx
import { useParams } from '@tanstack/react-router'

const { postId } = useParams({ from: '/posts/$postId' })
```

### Optional parameters

Syntax `{-$name}`:

```tsx
// src/routes/posts.{-$category}.tsx  →  matches /posts AND /posts/tech
export const Route = createFileRoute('/posts/{-$category}')({
  component: PostsComponent,
})

function PostsComponent() {
  const { category } = Route.useParams() // string | undefined
  return <h1>{category ? `Posts in ${category}` : 'All posts'}</h1>
}
```

They chain (`/posts/{-$category}/{-$slug}` matches `/posts`, `/posts/tech`, `/posts/tech/hello-world`) and mix with required ones (`/users/$id/{-$tab}` matches `/users/123` and `/users/123/settings`). Absent means `undefined`. They rank below exact matches: `/posts/featured` goes to a static `/posts/featured` over `/posts/{-$category}` ([TanStack Router - Route Matching](tanstack-router-route-matching.md)).

### Prefixes and suffixes in a segment

A braced parameter can take only part of a segment:

| Pattern | Matches | Param |
| --- | --- | --- |
| `post-{$postId}` | `post-123` | `postId = "123"` |
| `{$fileName}.txt` | `document.txt` | `fileName = "document"` |
| `user-{$userId}.json` | `user-42.json` | `userId = "42"` |

The `[x]` escape remains for fully static segments: `script[.]js.tsx` yields `/script.js`.

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-05` | Params read outside the route's own file **MUST** pass `from` (or use `getRouteApi`): `useParams()` with neither `from` nor `strict: false` is not typed for that route. |
| `TSR-ROUTE-06` | A consumer of `{-$param}` **MUST** handle `undefined`; the type is `string \| undefined`, not `string`. |
| `TSR-ROUTE-07` | A special character that must appear literally in the URL **MUST** be escaped with `[x]` in the file name (`script[.]js.tsx` → `/script.js`). |

---

## 5. Splat / catch-all

A lone `$` segment captures **the whole rest** of the URL, in `params._splat`:

```tsx
// src/routes/files.$.tsx
export const Route = createFileRoute('/files/$')({
  loader: ({ params }) => fetchFile(params._splat),
})
// URL /files/documents/2024/report.pdf → params._splat === 'documents/2024/report.pdf'
```

The source records the legacy form: *"In v1 of the router, splat routes are also denoted with a `*`"*. Splat is the last route tried, see [TanStack Router - Route Matching](tanstack-router-route-matching.md).

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-08` | A splat route's value **MUST** be read from `params._splat`; the `*` key **NEVER** enters new code. |

---

## 6. Layout routes: with and without a path

A **layout route** has children and wraps them: shared UI, `loader`/`beforeLoad` once before any child, search params validated for the children, common `errorComponent` / `pendingComponent`. Flat or directory, same result:

```
routes/                        routes/
├── app.tsx                    └── app/
├── app.dashboard.tsx              ├── route.tsx      ← the layout
└── app.settings.tsx               ├── dashboard.tsx
                                   └── settings.tsx
```

```tsx
// src/routes/app.tsx
export const Route = createFileRoute('/app')({
  loader: () => fetchUserData(),
  component: AppLayout,
})

function AppLayout() {
  return (
    <div className="app-layout">
      <nav>App</nav>
      <main>
        <Outlet />
      </main>
    </div>
  )
}
```

**Without `<Outlet />` the child does not appear**, with no error or warning: the URL matches, the loader runs, only the layout shows.

### Pathless layout route (`_prefix`)

The wrapper without a URL segment:

```
routes/
├── _pathlessLayout.tsx      ← the wrapper
├── _pathlessLayout.a.tsx    → /a
└── _pathlessLayout.b.tsx    → /b

/     → <Index />
/a    → <PathlessLayout><A /></PathlessLayout>
/b    → <PathlessLayout><B /></PathlessLayout>
```

Canonical use: auth guard, `_authenticated.tsx` with a redirecting `beforeLoad`, protected routes as children, no `/authenticated/` in the URL. Pathless layouts do not match URL segments, so they *"do not support Dynamic Route Segments as part of their path"*:

```
❌ routes/_$postId/          ← does not work: pathless does not match a segment
✅ routes/$postId/route.tsx  ← layout with a path, which can be dynamic
```

### Non-nested route (`_` suffix)

The same character at the other end excludes the route from nesting under its parents:

```
routes/
├── posts.tsx                 ← layout
├── posts.$postId.tsx         → /posts/123   (inside the layout)
└── posts_.$postId.edit.tsx   → /posts/123/edit (WITHOUT the layout)
```

Same URL, different component tree: how a full-screen edit page drops the list sidebar.

| Token | Effect on the URL | Effect on the component tree |
| --- | --- | --- |
| `_prefix` (pathless layout) | removes the segment | **adds** a wrapper level |
| `suffix_` (non-nested) | no change | **removes** the ancestor wrappers |

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-09` | Every route with children **MUST** render `<Outlet />` in its `component`. |
| `TSR-ROUTE-10` | A pathless layout (`_prefix`) **NEVER** contains a dynamic segment in its own path: it does not match by URL segment. |
| `TSR-ROUTE-11` | `_` as prefix and `_` as suffix are **NEVER** treated as the same feature: the prefix adds a layout without changing the URL; the suffix removes layouts without changing the URL. |

---

## 7. Organization with no route effect

**Route group `(name)/`** groups files without entering the URL:

```
routes/
├── (app)/
│   ├── dashboard.tsx   → /dashboard
│   └── settings.tsx    → /settings
└── (auth)/
    ├── login.tsx       → /login
    └── register.tsx    → /register
```

Groups are *"purely organizational and do not affect the route tree or component tree in any way"*: a shared layout needs a pathless layout (`_auth.tsx`).

**Excluded files `-name`** (files and folders) colocate helper code outside the route tree:

```
routes/
├── posts.tsx
├── -posts-table.tsx    ← ignored
└── -components/        ← whole folder ignored
    └── header.tsx
```

```tsx
// posts.tsx
import { PostsTable } from './-posts-table'
```

The prefix is the configurable `routeFileIgnorePrefix` default ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)).

| ID | Rule |
| --- | --- |
| `TSR-ROUTE-12` | A route group `(name)` is **NEVER** used to get a shared layout or shared data: it creates no tree node. Use a pathless layout. |
| `TSR-ROUTE-13` | A helper file inside `routesDirectory` **MUST** use the `-` prefix; otherwise it becomes a route. |

---

## 8. Decision matrix

| You want... | Use | File |
| --- | --- | --- |
| Simple route | basic route | `about.tsx` |
| Content at the parent's exact URL | index route | `posts.index.tsx` |
| Capture one segment | dynamic segment | `posts.$postId.tsx` |
| Segment that may be missing | optional param | `posts.{-$category}.tsx` |
| Part of a segment | prefix/suffix | `post-{$postId}.tsx` |
| Capture the rest of the URL | splat | `files.$.tsx` |
| Shared UI + data **with** a segment | layout route | `app.tsx` + `app.*.tsx` |
| Shared UI + data **without** a segment | pathless layout | `_auth.tsx` + `_auth.*.tsx` |
| Escape the ancestor's layout | non-nested | `posts_.$postId.edit.tsx` |
| Only tidy folders | route group | `(admin)/` |
| Helper code next to the route | excluded file | `-table.tsx` |

---

## Version notes

- `*` for splat is documented as an alternative spelling in v1; the docs do not announce its removal in v2. Treat it as legacy, not as deprecated with a date.
- Not verified: the rationale "`$` over `*` because `*` works badly in file names and CLI tools, following Remix". Plausible, not on the official page.
- The internal router functions some notes describe (`inferParamsFromPath`, `matchRoute`, `calculateRouteScore`, `executeLoaders`...) do not exist in the docs. The shape of `routeTree.gen.ts` (e.g. `interface FileRoutesByPath`) is a generator artifact, not documented public API.

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Editing the literal in `createFileRoute('/…')` to change the URL | The generator rewrites it on the next build; the path comes from the file name | Rename the file (`TSR-ROUTE-01`) |
| More than one `__root.tsx`, or one outside the root of `routesDirectory` | The root file has a fixed name and place | One `__root.tsx` at the root (`TSR-ROUTE-02`) |
| Layout `component` without `<Outlet />` | The URL matches, the loader runs, the child never appears | Render `<Outlet />` (`TSR-ROUTE-09`) |
| `(auth)/` group to share a layout or `beforeLoad` | A group renders nothing and creates no node | `_auth.tsx` pathless layout with `<Outlet />` (`TSR-ROUTE-12`) |
| `posts.tsx` with children and no `posts.index.tsx` | `/posts` renders the layout with an empty `<Outlet />` | Create the index route (`TSR-ROUTE-04`) |
| `_$postId/` as a dynamic pathless layout | Pathless does not match a URL segment; the param is never captured | Layout with a path: `$postId/route.tsx` (`TSR-ROUTE-10`) |
| `params['*']` to read a splat | Legacy v1 key | `params._splat` (`TSR-ROUTE-08`) |
| `const { id } = useParams()` in a shared component | No `from`, no route typing | `useParams({ from: '/posts/$postId' })` (`TSR-ROUTE-05`) |
| `{-$category}` used as if always present | The type includes `undefined`; breaks at `/posts` | Handle the absent branch (`TSR-ROUTE-06`) |
| `components/Header.tsx` inside `routes/` | Becomes the route `/components/Header` | `-` prefix (`TSR-ROUTE-13`) |
