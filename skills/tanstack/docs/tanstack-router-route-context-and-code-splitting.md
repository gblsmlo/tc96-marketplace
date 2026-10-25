---
title: TanStack Router - Route Context and Code Splitting
link: https://tanstack.com/router/latest/docs/framework/react/guide/router-context
tags:
  - tanstack-router
  - context
  - code-splitting
  - agent-context
source: "Official documentation, https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Route Context and Code Splitting

## Contents

- [1. Concept: context is typed, per-route dependency injection](#1-concept-context-is-typed-per-route-dependency-injection)
- [2. Defining the root context](#2-defining-the-root-context)
- [3. beforeLoad extends the context](#3-beforeload-extends-the-context)
- [4. The two patterns that justify the mechanism](#4-the-two-patterns-that-justify-the-mechanism)
- [5. Invalidation when context changes](#5-invalidation-when-context-changes)
- [6. Concept: splitting can only remove what is not needed before render](#6-concept-splitting-can-only-remove-what-is-not-needed-before-render)
- [7. .lazy.tsx and createLazyFileRoute](#7-lazytsx-and-createlazyfileroute)
- [8. Code-based routing: createLazyRoute + .lazy()](#8-code-based-routing-createlazyroute--lazy)
- [9. Automatic code splitting](#9-automatic-code-splitting)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> Context: `createRootRouteWithContext` · `createRouter`'s `context` option · `beforeLoad` returning context · parent-to-child inheritance and merge · `useRouteContext` · injecting `queryClient` and auth · `router.invalidate()` after a context change.
> Splitting: `.lazy.tsx` · `createLazyFileRoute` · `createLazyRoute` + `.lazy()` · `autoCodeSplitting` · `codeSplittingOptions` (`defaultBehavior`, `splitBehavior`) · critical vs. non-critical configuration · `getRouteApi`.
>
> **Does not cover:** `loader`, `loaderDeps`, preloading and the TanStack Query integration ([TanStack Router - Data Loading](tanstack-router-data-loading.md)) · file naming conventions ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · virtual routes defined in code ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)).

Entry: [TanStack Router](tanstack-router.md)

---

## 1. Concept: context is typed, per-route dependency injection

Upstream says router context is for "dependency injection among many other things". It is not React Context renamed. React Context is a **render** mechanism, read only by hooks inside the component tree. `beforeLoad` and `loader` are **not components** and run **before** any render, and you can't use hooks in a non-React function.

Route context fills that gap: an object the router carries down the route tree, available in `beforeLoad`, `loader` and components (via `useRouteContext`). It is how `queryClient`, the API client and auth state enter the loading pipeline. It is **per route**, with inheritance: a route sees its parent's context merged with what its own `beforeLoad` returned. Each level can add; none has to forward.

| ID | Rule |
| --- | --- |
| `TSR-CTX-01` | `beforeLoad` and `loader` **NEVER** call React hooks. Values that come from hooks enter through the router context. |

---

## 2. Defining the root context

The type at the root and the value in `createRouter` must agree.

```tsx
// src/routes/__root.tsx
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'

export interface MyRouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<MyRouterContext>()({
  component: () => <Outlet />,
})
```

```tsx
// src/router.tsx
const router = createRouter({ routeTree, context: { queryClient } })
```

**Double call:** `createRootRouteWithContext<T>()(options)`. The first parentheses close the generic, the second take the options; `createRootRouteWithContext<T>(options)` does not compile.

`MyRouterContext` only needs what is passed directly to `createRouter`; everything `beforeLoad` adds is inferred down the tree. Required properties in the interface make TypeScript error if `context` is omitted on `createRouter`; if all are optional, `context` becomes optional. Missing context is `{}`.

| ID | Rule |
| --- | --- |
| `TSR-CTX-02` | A project that passes `context` to `createRouter` **MUST** declare the root with `createRootRouteWithContext<T>()`, **NEVER** with `createRootRoute()`. |
| `TSR-CTX-03` | The root context interface **MUST** contain only what is passed to `createRouter`; what `beforeLoad` adds is **NEVER** declared there (it is inferred). |

---

## 3. `beforeLoad` extends the context

The return of `beforeLoad` is **merged** into the parent context. It does not replace it and needs no spread.

```tsx
// __root.tsx  ->  context: { foo: true }

export const Route = createFileRoute('/posts')({
  beforeLoad: () => ({ bar: true, fetchPosts: () => console.info('foo') }),
  loader: ({ context }) => {
    context.foo // true, inherited from the root
    context.bar // true, from this route
    context.fetchPosts() // 'foo'
  },
})
```

The merge is what makes typed context useful: a pathless `_authed` route can return `{ user }` from `beforeLoad`, and **every** child route gets a typed `context.user` (pathless routes: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)). Returning `{ ...context, bar: true }` is not just redundant: it bloats the context and blurs what the route contributes.

| ID | Rule |
| --- | --- |
| `TSR-CTX-04` | `beforeLoad` **MUST** return only the context delta; **NEVER** spread the parent context (`...context`) into the return: the router does the merge. |

`beforeLoad` also runs on speculative (hover) preload, so a side effect there fires without navigation: `TSR-LOAD-12` ([TanStack Router - Data Loading](tanstack-router-data-loading.md) § 7).

---

## 4. The two patterns that justify the mechanism

### 4.1 `queryClient`: the dependency that is not a hook

```tsx
const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreloadStaleTime: 0,
})

export const Route = createFileRoute('/posts')({
  loader: ({ context }) => context.queryClient.ensureQueryData(postsQueryOptions),
})
```

Importing `queryClient` from a global module works in the browser and breaks in SSR: the client must be **per request**, and a module singleton leaks cache between users. Context is the channel that allows per-request instantiation and injection.

### 4.2 Auth: the dependency that **is** a hook

Here context is the only way out. Auth state comes from a hook (`useAuth`) and `beforeLoad` cannot call hooks. Upstream solution: read the hook in a component and pass the result through `RouterProvider`.

```tsx
// __root.tsx
export const Route = createRootRouteWithContext<{ auth: AuthState }>()({
  component: () => <Outlet />,
})
```

```tsx
// main.tsx
const router = createRouter({
  routeTree,
  context: { auth: undefined! }, // filled in InnerApp
})

function InnerApp() {
  const auth = useAuth()
  return <RouterProvider router={router} context={{ auth }} />
}

function App() {
  return (
    <AuthProvider>
      <InnerApp />
    </AuthProvider>
  )
}
```

`undefined!` is a deliberate placeholder: the real value only exists inside the React provider. If `context={{ auth }}` on `RouterProvider` is forgotten there is **no type error** (the `!` silenced TypeScript) and the guard breaks at runtime. With this in place, the guard is the one in [TanStack Router - Data Loading](tanstack-router-data-loading.md) § 4:

```tsx
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({ to: '/login', search: { redirect: location.href } })
    }
  },
})
```

Route guards protect **UI**; endpoints must authorize on their own, because they can be called outside the routing layer.

| ID | Rule |
| --- | --- |
| `TSR-CTX-05` | A hook-derived value (auth, i18n, theme) **MUST** enter through the `<RouterProvider>`'s `context`, **NEVER** be read from a module singleton inside `beforeLoad`. |
| `TSR-CTX-06` | Context declared with a placeholder (`undefined!`) in `createRouter` **MUST** have a matching `context` on `<RouterProvider>`: the `!` removes the type check. |
| `TSR-CTX-07` | A context-based route guard **NEVER** replaces backend authorization. |

---

## 5. Invalidation when context changes

Router context is read in `beforeLoad`/`loader`, outside the render cycle. Changing the value on `RouterProvider` does **not** re-run anything by itself. Call `router.invalidate()` when context state changes to recompute all routes.

```tsx
function InnerApp() {
  const auth = useAuth()

  useEffect(() => {
    router.invalidate()
  }, [auth.isAuthenticated])

  return <RouterProvider router={router} context={{ auth }} />
}
```

Classic case, logout: without `invalidate()`, already-matched routes keep the old context, guards do not re-evaluate and the protected screen stays.

| ID | Rule |
| --- | --- |
| `TSR-CTX-08` | A value change in the router context (login, logout, tenant switch) **MUST** be followed by `router.invalidate()`. |

### Accumulated context

Each match keeps its own context, so `router.state.matches` can be walked to collect contributions. Upstream use: breadcrumbs and dynamic page titles, filtering matches that expose something like `getTitle()` in context.

---

## 6. Concept: splitting can only remove what is not needed before render

To match the URL the router must parse params and validate search; to start fetching it needs `beforeLoad` and `loader`. None of that can arrive later. Hence the **critical** / **non-critical** split, a consequence of the execution order in [TanStack Router - Data Loading](tanstack-router-data-loading.md) § 1, not an organizational preference.

| Critical: stays in the route file | Non-critical: can be lazy |
| --- | --- |
| Path parsing / serialization | `component` |
| Search param validation (`validateSearch`) | `errorComponent` |
| `loader` | `pendingComponent` |
| `beforeLoad` | `notFoundComponent` |
| Route context | |
| Static data, links, scripts, styles | |
| "All other route configuration not listed as non-critical" | |

The non-critical list is closed: four components. Everything else is critical by definition.

| ID | Rule |
| --- | --- |
| `TSR-SPLIT-01` | `loader`, `beforeLoad`, `validateSearch`, param parsing and context **MUST** stay in the critical route file; **NEVER** in a `.lazy.tsx` file. |
| `TSR-SPLIT-02` | A `.lazy.tsx` file **MUST** export only `component`, `errorComponent`, `pendingComponent` and `notFoundComponent`. |

---

## 7. `.lazy.tsx` and `createLazyFileRoute`

```tsx
// src/routes/posts.tsx  (critical)
export const Route = createFileRoute('/posts')({
  loaderDeps: ({ search: { page } }) => ({ page }),
  loader: ({ deps: { page } }) => fetchPosts({ page }),
})
```

```tsx
// src/routes/posts.lazy.tsx  (non-critical)
import { createLazyFileRoute } from '@tanstack/react-router'

export const Route = createLazyFileRoute('/posts')({
  component: Posts,
})

function Posts() {
  const posts = Route.useLoaderData()
  return <PostList posts={posts} />
}
```

Both files declare **the same path** (`'/posts'`) and both export `Route`; that is how the router stitches them. A diverging path or export name breaks the link.

If the critical file ends up empty after the split, upstream says **delete it**: the router generates a virtual route to anchor the lazy file (tree assembly: [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md), [TanStack Router - Route Trees](tanstack-router-route-trees.md)). Directory encapsulation also works with no extra config: `posts.tsx` becomes `posts/route.tsx`, next to `posts/route.lazy.tsx` and `posts/-components/...`.

| ID | Rule |
| --- | --- |
| `TSR-SPLIT-03` | A `.lazy.tsx` file **MUST** use `createLazyFileRoute`, **NEVER** `createFileRoute`. |
| `TSR-SPLIT-04` | The path passed to `createLazyFileRoute` **MUST** be identical to the matching `createFileRoute`'s. |
| `TSR-SPLIT-05` | A critical route file left with no options **MUST** be deleted: the virtual route anchors the lazy file. |

### Components in their own files: `getRouteApi`

Splitting spreads components across files, and importing `Route` back creates a cycle. Use `getRouteApi` (same rule as `TSR-LOAD-07`):

```tsx
// src/routes/-components/post-body.tsx
const route = getRouteApi('/posts/$postId')

export function PostBody() {
  const post = route.useLoaderData()
  const { postId } = route.useParams()
  return <article id={postId}>{post.body}</article>
}
```

Methods: `useLoaderData`, `useLoaderDeps`, `useMatch`, `useParams`, `useRouteContext`, `useSearch`.

---

## 8. Code-based routing: `createLazyRoute` + `.lazy()`

With routes defined in code there is no file suffix for the plugin to read; the link is explicit.

```tsx
// posts.lazy.tsx
export const Route = createLazyRoute('/posts')({
  component: MyComponent,
})

// app.tsx
const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
}).lazy(() => import('./posts.lazy').then((d) => d.Route))
```

`.lazy()` takes a function that returns the lazy `Route`: the `.then((d) => d.Route)` is not optional; the default import does not work.

---

## 9. Automatic code splitting

Available **only** with file-based routing and a supported bundler. The plugin separates critical from non-critical by itself, with no hand-written `.lazy.tsx`.

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [tanstackRouter({ autoCodeSplitting: true })],
})
```

### `codeSplittingOptions`

In automatic mode **five properties are splittable, not four**: `component`, `errorComponent`, `pendingComponent`, `notFoundComponent` **and `loader`**. Manual `.lazy.tsx` never accepted `loader`; the plugin does, on explicit request.

```ts
tanstackRouter({
  autoCodeSplitting: true,
  codeSplittingOptions: {
    defaultBehavior: [
      ['component', 'pendingComponent', 'errorComponent', 'notFoundComponent'],
    ], // one chunk with all the UI
    splitBehavior: ({ routeId }) => {
      if (routeId.startsWith('/posts')) {
        return [['loader', 'component']]
      }
    },
  },
})
```

Each inner array is a **group that becomes one chunk**: `[['a','b'],['c']]` yields two chunks. A `splitBehavior` that returns nothing falls back to `defaultBehavior`.

### Why not split the `loader`

Upstream warns on both pages: moving the `loader` into its own chunk is a **performance trade-off** that adds a trip to the server before data can be fetched, slowing initial loads; splitting it is highly discouraged without a specific use case ("a dangerous game", per the manual page).

The arithmetic: an isolated loader must be **downloaded** before it can **fetch**, two serial trips where there was one. It is also what `intent` (hover) preload tries to get ahead of, so the most valuable asset to preload becomes the latest. Loaders rarely weigh much in the bundle; components do. ``'loader', 'component'`` does **not** isolate the loader: it groups both in one chunk. The antipattern is the isolated loader, or the loader imported through `lazyFn`.

| ID | Rule |
| --- | --- |
| `TSR-SPLIT-06` | The `loader` **NEVER** goes into an isolated chunk, neither via `codeSplittingOptions` nor via `lazyFn`. Grouping it with `component` in the same chunk is allowed. |
| `TSR-SPLIT-07` | In code-based routing, splitting **MUST** use `createLazyRoute` + `.lazy()`: `autoCodeSplitting` only works with file-based routing. |

---

## Version notes

- `loader` is splittable only in automatic mode. Code Splitting lists four `.lazy.tsx` exports and classes `loader` as critical; Automatic Code Splitting lists five splittable properties, including `loader`, and explicitly discourages it.
- `codeSplittingOptions` is grouping, not flags: `defaultBehavior`/`splitBehavior` take arrays of arrays, each inner array one chunk.
- The Vite plugin is `tanstackRouter` from `@tanstack/router-plugin/vite`, not `TanStackRouterVite` (older material).
- `createRootRouteWithContext` is a double call: `createRootRouteWithContext<T>()({ ... })`.
- Not verified: combining `autoCodeSplitting: true` with hand-written `.lazy.tsx` files in the same project is not covered by the pages consulted.

---

## Antipatterns

```tsx
// WRONG: hook in beforeLoad, which does not run in a render context
beforeLoad: () => {
  const { user } = useAuth()
  if (!user) throw redirect({ to: '/login' })
}

// RIGHT: the hook runs in a component; the value enters through context
function InnerApp() {
  const auth = useAuth()
  return <RouterProvider router={router} context={{ auth }} />
}
beforeLoad: ({ context }) => {
  if (!context.auth.user) throw redirect({ to: '/login' })
}
```

```tsx
// WRONG: loader in the lazy file; the router needs it before render
// posts.lazy.tsx
export const Route = createLazyFileRoute('/posts')({
  loader: () => fetchPosts(), // not a supported .lazy export
  component: Posts,
})
// RIGHT: critical in posts.tsx, component in posts.lazy.tsx
```

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `createRootRoute()` with `context` on `createRouter` | untyped context; `context.x` is `any` or an error | `createRootRouteWithContext<T>()` (`TSR-CTX-02`) |
| Context interface declaring what `beforeLoad` adds | duplicates what TS infers and forces fake values in `createRouter` | declare only the injected values (`TSR-CTX-03`) |
| `beforeLoad: ({ context }) => ({ ...context, permissions })` | redundant, obscures the route's contribution | return only the delta (`TSR-CTX-04`) |
| `undefined!` without `context` on `RouterProvider` | the `!` removes the check: breaks at runtime, not build | pass `context={{ auth }}` (`TSR-CTX-06`) |
| `queryClient` imported from a global module | singleton leaks cache between requests in SSR | inject through context (`TSR-CTX-05`) |
| Auth change without `router.invalidate()` | matches keep the old context; guards do not re-evaluate | `invalidate()` on change (`TSR-CTX-08`) |
| `validateSearch` in `.lazy.tsx` | search is validated during match, before the chunk exists | keep it in the route file (`TSR-SPLIT-01`) |
| `createFileRoute` inside `.lazy.tsx` | duplicates the critical definition instead of extending it | `createLazyFileRoute` (`TSR-SPLIT-03`) |
| Empty critical route file kept | noise; the virtual route already anchors the lazy file | delete the file (`TSR-SPLIT-05`) |
| `loader` in its own chunk | chunk fetch + data fetch, in series; defeats intent preload | do not isolate the loader (`TSR-SPLIT-06`) |
