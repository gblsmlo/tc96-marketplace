---
title: TanStack Router - Data Loading
link: https://tanstack.com/router/latest/docs/framework/react/guide/data-loading
tags:
  - tanstack-router
  - data-loading
  - agent-context
source: "Official documentation, https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Data Loading

## Contents

- [1. Concept: the loader exists to kill the waterfall](#1-concept-the-loader-exists-to-kill-the-waterfall)
- [2. loader](#2-loader)
- [3. loaderDeps: the cache key you write by hand](#3-loaderdeps-the-cache-key-you-write-by-hand)
- [4. beforeLoad](#4-beforeload)
- [5. Consuming the data: useLoaderData and getRouteApi](#5-consuming-the-data-useloaderdata-and-getrouteapi)
- [6. Pending, error and not found](#6-pending-error-and-not-found)
- [7. Freshness and retention: staleTime, gcTime, preload](#7-freshness-and-retention-staletime-gctime-preload)
- [8. External data loading: when to delegate to TanStack Query](#8-external-data-loading-when-to-delegate-to-tanstack-query)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> `loader` · `loaderDeps` · `useLoaderData` · `getRouteApi` · `beforeLoad` · `pendingComponent` / `pendingMs` / `pendingMinMs` · `errorComponent` · `notFoundComponent` · `defaultPreload` · `staleTime` / `gcTime` / `preloadStaleTime` / `preloadGcTime` · `shouldReload` · `staleReloadMode` · `router.invalidate()` · TanStack Query integration via `ensureQueryData`.
>
> **Does not cover:** route definition and hierarchy ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · file conventions ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · match precedence ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · router context and code splitting ([TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md)).

Entry: [TanStack Router](tanstack-router.md)

---

## 1. Concept: the loader exists to kill the waterfall

Fetch-on-render chains network **after** render: the parent loads, renders, mounts the child, the child loads. Each level adds a serial round trip.

The `loader` is declared **on the route**, not in the component. The router knows the matched route tree before rendering, fires every loader in the tree **in parallel**, and only then renders. The component is born with data. The upstream gains: no "flash of loading" states, no component-based fetch waterfall, better SEO because data exists at render time.

This is the concrete counterpart of `REACT-EFFECT-06` (skill `react-developer`), which forbids `fetch` in `useEffect` in new code. The replacement is not another hook: the fetch moves out of the component, onto the route. Server-cache data with a freshness policy is delegated to Query (§ 8).

| ID | Rule |
| --- | --- |
| `TSR-LOAD-01` | Data needed for a route's first render **MUST** come from the `loader` (or `beforeLoad`), and **NEVER** from `fetch` in `useEffect` in the route component. Alias of `REACT-EFFECT-06`. |

### The cycle, in order

1. **Route Matching (top-down)**: `route.params.parse`, `route.validateSearch`.
2. **Route Pre-Loading (serial)**: `route.beforeLoad`, with error handling.
3. **Route Loading (parallel)**: component preload, `route.loader`, pending and error components.

**`beforeLoad` is serial and top-down; `loader` is parallel.** Screen-data fetching in `beforeLoad` turns parallel into a queue and reintroduces the waterfall.

---

## 2. `loader`

The loader receives **a single object**:

| Field | What it is |
| --- | --- |
| `params` | the route's path params |
| `deps` | the return of `loaderDeps` |
| `context` | parent context merged with what this route's `beforeLoad` returned |
| `abortController` | "its signal is cancelled after the invocation becomes outdated" |
| `cause` | `'enter'` \| `'preload'` \| `'stay'` |
| `preload` | `true` when the route is being preloaded |
| `location` | current location |
| `parentMatchPromise` | promise of the parent `RouteMatch` |
| `route` | the route definition |

```tsx
// src/routes/posts.$postId.tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: ({ params: { postId }, abortController }) =>
    fetchPostById(postId, { signal: abortController.signal }),
  component: PostPage,
})

function PostPage() {
  const post = Route.useLoaderData()
  return <article>{post.body}</article>
}
```

When the invocation goes stale (the user navigated again) the signal is cancelled, so the race condition is structurally impossible. Same fix as `REACT-EFFECT-06`, with the router doing the bookkeeping.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-02` | A network request made **directly** inside a `loader` **MUST** pass `abortController.signal`. |

**Scope, to avoid conflicting with Query.** `TSR-LOAD-02` applies when the loader calls `fetch` or an HTTP client itself. When it **delegates** to Query (`context.queryClient.ensureQueryData(...)`), cancellation belongs to Query: the `queryFn` receives its own `signal` in `QueryFunctionContext` and passes it there. There is no documented chaining between the router's and Query's abort controllers, and none is needed: each layer cancels what it started. So `loader: ({ context }) => context.queryClient.ensureQueryData(opts)` satisfies `TSR-LOAD-02` vacuously; the obligation moves to the `queryFn`, under `TSQ-SSR-10`. See § 8.

### Object form

```tsx
loader: () => fetchPosts()

loader: {
  handler: () => fetchPosts(),
  staleReloadMode: 'background', // or 'blocking'
}
```

`staleReloadMode` only applies when the match **already has stale successful data**: `'background'` is stale-while-revalidate (the default: render the existing `loaderData` immediately, refresh in the background); `'blocking'` waits for the stale reload to finish before continuing.

---

## 3. `loaderDeps`: the cache key you write by hand

The router's SWR cache is keyed by the fully parsed pathname (`/posts/1` ≠ `/posts/2`). **Search params are not in the key automatically.** A search param the loader reads must be declared in `loaderDeps`. When deps change between navigations, the route reloads regardless of `staleTime`.

```tsx
// WRONG: any search param (even `?tab=comments`) refetches the list
loaderDeps: ({ search }) => search

// RIGHT: only what the loader consumes
export const Route = createFileRoute('/posts')({
  loaderDeps: ({ search: { offset, limit } }) => ({ offset, limit }),
  loader: ({ deps: { offset, limit } }) => fetchPosts({ offset, limit }),
})
```

Returning the whole `search` object is the mistake upstream flags explicitly. `loaderDeps` must be **deterministic and serializable**: a `Date.now()`, a new object per call or a function inside silently breaks the cache (the key never matches) and the loader runs on every navigation.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-03` | `loaderDeps` **MUST** return only the search params the loader actually reads; **NEVER** return the whole `search` object. |
| `TSR-LOAD-04` | A search param consumed by the loader **MUST** be declared in `loaderDeps`; the loader **NEVER** reads search from `location` directly. |

---

## 4. `beforeLoad`

```
beforeLoad: (opts) => Promise<TRouteContext> | TRouteContext | void
```

Three legitimate uses, only three: **produce context**, **guard access**, **redirect**.

```tsx
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({ to: '/login', search: { redirect: location.href } })
    }
  },
})
```

`beforeLoad` runs **before** child loaders, so the redirect happens before any protected loader fires. A guard in `useEffect` runs after everything was fetched and rendered. Upstream caveat that must survive any review: route guards protect UI only; backend endpoints must authorize independently, since they can be called outside the routing layer.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-05` | `beforeLoad` **MUST** contain only context, guard and redirect; screen-data fetching **NEVER** goes there (it is serial and blocks the parallel loaders). |
| `TSR-LOAD-06` | An access guard **MUST** be `throw redirect(...)` in `beforeLoad`, **NEVER** a `navigate()` inside a component or effect. |

Where `context.auth` comes from, typed: [TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md) § 1.

---

## 5. Consuming the data: `useLoaderData` and `getRouteApi`

```tsx
// Inside the route file
const post = Route.useLoaderData()

// In a separate file, without importing Route back (import cycle)
const route = getRouteApi('/posts/$postId')
function PostBody() {
  const post = route.useLoaderData()
}
```

Hook options: `from` (route id of the nearest parent match, recommended for type safety), `strict` (default `true`; `false` loosens the type when `from` is omitted), `select` (`(loaderData) => TSelected`, re-renders on shallow equality), `structuralSharing`.

`getRouteApi(id)` exposes `useLoaderData`, `useLoaderDeps`, `useMatch`, `useParams`, `useRouteContext`, `useSearch`. It keeps types in components outside the route file, which is what code splitting needs.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-07` | A component in a file separate from the route file **MUST** access data through `getRouteApi('<id>')`; **NEVER** import `Route` back (import cycle). |

**If that component navigates:** `getRouteApi` does not expose `fullPath`, which seems to collide with `TSR-NAV-04` (`from` from `Route.fullPath`, not a repeated string literal). The collision is only apparent: `TSR-NAV-04` forbids **repeating** the literal in each JSX, not using the route id. Declare it once and reuse:

```tsx
// -components/ReviewFilter.tsx
const ROUTE = '/products/$productId' as const
const api = getRouteApi(ROUTE)

export function ReviewFilter() {
  const filter = api.useSearch()
  const navigate = useNavigate({ from: ROUTE })
}
```

One constant per file satisfies both rules. Keeping a small search-writing component in the route file is also valid and often simpler.

---

## 6. Pending, error and not found

### `pendingComponent`, `pendingMs`, `pendingMinMs`

| Option | Default |
| --- | --- |
| `pendingMs` | `routerOptions.defaultPendingMs`: `1000` |
| `pendingMinMs` | `routerOptions.defaultPendingMinMs`: `500` |

**The pending component only shows if the loader takes over 1 second**, and once shown it stays at least 500 ms. The pair works together: `pendingMs` avoids a spinner for an 80 ms response; `pendingMinMs` avoids a spinner that flashes for 30 ms. Dropping `pendingMs` near zero without keeping `pendingMinMs` produces exactly the flicker the defaults prevent.

```tsx
export const Route = createFileRoute('/posts')({
  loader: () => fetchPosts(),
  pendingComponent: () => <PostsSkeleton />,
  pendingMs: 300,
  pendingMinMs: 500,
})
```

| ID | Rule |
| --- | --- |
| `TSR-LOAD-08` | When lowering `pendingMs` below the default, `pendingMinMs` **MUST** stay greater than `0`. |

`wrapInSuspense` exists as a route option. The async-boundary mental model is React's (skill `react-developer`); the router only decides **where** the boundary falls.

### `errorComponent` and `onError`

```tsx
export const Route = createFileRoute('/posts')({
  loader: () => fetchPosts(),
  onError: ({ error }) => reportError(error),
  errorComponent: ({ error, reset }) => (
    <div role="alert">
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  ),
})
```

Router defaults: `defaultErrorComponent`, `defaultOnCatch`. There is also `onCatch: (error: Error, errorInfo: ErrorInfo) => void`. For **loader errors**, `reset` alone is not enough: `router.invalidate()` coordinates the loader reload with the error boundary reset.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-09` | A route with a `loader` **MUST** have its own `errorComponent` or a `defaultErrorComponent` configured on the router. |
| `TSR-LOAD-10` | Loader error recovery **MUST** call `router.invalidate()`, not only the `errorComponent`'s `reset`. |

### `notFoundComponent` and `notFound()`

```tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await fetchPostById(params.postId)
    if (!post) throw notFound()
    return post
  },
})
```

- `notFound()` takes `routeId` to pick the boundary (`throw notFound({ routeId: '/_pathlessLayout' })`) and `data`, which reaches the `notFoundComponent`.
- `notFoundComponent` can use `useParams()`, `useSearch()`, `useRouteContext()`; loader data availability depends on which route threw.
- Leaf routes (no children) never render an `Outlet`, so they cannot handle not-found errors.
- `notFound` and `notFoundComponent` do not work with `NotFoundRoute`.
- Router `notFoundMode`: `'fuzzy'` (default, nearest matched route with a `notFoundComponent`) or `'root'` (everything goes to the root).

| ID | Rule |
| --- | --- |
| `TSR-LOAD-11` | `notFoundComponent` is **NEVER** declared on a leaf route: it renders no `Outlet` and will never show the component. |

---

## 7. Freshness and retention: `staleTime`, `gcTime`, preload

| Option | Default | Meaning |
| --- | --- | --- |
| `staleTime` | `0` | how long navigation data is fresh |
| `preloadStaleTime` | `30_000` | freshness of **preloaded** data |
| `gcTime` | 5 min | retention before it becomes eligible for pruning |
| `preloadGcTime` | 5 min | retention of preloaded data |

`staleTime: 0` means **every navigation revalidates**, but with SWR revalidating is not waiting: the stale match renders with the existing `loaderData` and refreshes in the background. Freshness (when to revalidate) versus retention (when to discard) is the same split as in [TanStack Query - Cache and Freshness](tanstack-query-cache-and-freshness.md); the names collide (`staleTime` and `gcTime` exist in both, with different owners and defaults).

### Preloading

`defaultPreload` on `createRouter`:

| Value | Trigger |
| --- | --- |
| `'intent'` | hover and touch on the `<Link>` |
| `'viewport'` | Intersection Observer: the link becomes visible |
| `'render'` | as soon as the `<Link>` mounts |
| `false` | off |

```tsx
const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
  defaultPreloadDelay: 50,
})
```

Intent focus/hover and viewport preloading start after 50 ms; touch intent preloads immediately. `<Link preload="...">` and `preloadDelay` override per link.

The speculative lane:

- Client-side preloading runs each route's `beforeLoad` with `preload: true`, **and the `loader`**. That is why `preloadStaleTime` exists: it controls whether the retained loader result can be reused without another loader call.
- The speculative lane is never promoted into router state. The later navigation runs its own `beforeLoad` chain and reuses (or joins) in-flight loader work.
- **Exception, easy to misread as the general rule:** only when a route declares `preload: false` does its speculative lane run `beforeLoad` but skip that route's loader.

Consequences:

1. **A side effect in `beforeLoad` fires on hover** (analytics, logging, store writes). Treat `beforeLoad` as pure (`TSR-LOAD-12`).
2. **Every preloading link is a potential real request**, because the loader runs. `defaultPreload: 'render'` on a long list is one loader run per mounted item (`TSR-NAV-07`).

### `shouldReload` + `gcTime`: Remix-style loading

`shouldReload` is `boolean | ((args) => boolean)`. `shouldReload: false` + `gcTime: Infinity` gives "load on entry and when deps change, never again".

### Invalidation

`router.invalidate()` selects matching committed, cached and in-flight loader generations for invalidation and retires matching active preload lanes.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-12` | `beforeLoad` **NEVER** has an observable side effect (analytics, store write): it runs on hover preload. |
| `TSR-LOAD-13` | A mutation that invalidates data served by the native loader **MUST** call `router.invalidate()`. |

---

## 8. External data loading: when to delegate to TanStack Query

The router is a **coordinator**, not the definitive cache layer: any promise-based fetching library works (TanStack Query, SWR, RTK Query, Apollo, Zustand, Redux).

| Situation | Use |
| --- | --- |
| Data belongs to one route, consumed only there, no sophisticated revalidation | native `loader` |
| Same data consumed by several routes or components outside the route | TanStack Query |
| Needs mutation + selective invalidation, retry, refetch on focus/reconnect, pagination, optimistic update | TanStack Query |
| Needs SSR dehydrate/hydrate | either; the router exposes `dehydrate` / `hydrate` callbacks |

Not either/or. The official pattern uses **both**: the loader warms Query's cache to kill the waterfall, and the component reads Query's cache for reactivity.

```tsx
const postsQueryOptions = queryOptions({
  queryKey: ['posts'],
  queryFn: () => fetchPosts(),
})

export const Route = createFileRoute('/posts')({
  loader: ({ context }) => context.queryClient.ensureQueryData(postsQueryOptions),
  component: Posts,
})

function Posts() {
  const { data: posts } = useSuspenseQuery(postsQueryOptions)
  return <PostList posts={posts} />
}
```

Two things make it work, both easy to break:

1. **The same `queryOptions` object on both sides.** Loader `['posts']` and component `['posts', {}]` are two cache entries: the loader warms one, the component fetches the other. The waterfall comes back silently, with no error.
2. **A cache-respecting read, not `fetchQuery`.** `ensureQueryData` resolves immediately from any cached data; `fetchQuery` always fetches. On a version that marks `ensureQueryData` deprecated (5.104.5 does), the same read is `queryClient.query({ ...postsQueryOptions, staleTime: 'static' })`.

The `queryClient` reaches the loader through router context injection: [TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md) § 2.

### The preload setting almost everyone forgets

With an external cache, **Query decides freshness, not the router**. Upstream: set `defaultPreloadStaleTime` to `0` so the external cache determines freshness while the router handles retention.

```tsx
const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreload: 'intent',
  defaultPreloadStaleTime: 0, // required with TanStack Query
})
```

Without it the router treats the preload result as fresh for 30 seconds and **does not call the loader**, so `ensureQueryData` never runs and Query's `staleTime` is never consulted. Symptom: stale data after a mutation, with Query "correct" and the router holding it. For Suspense errors, upstream points at `useQueryErrorResetBoundary` to reset queries before re-rendering.

| ID | Rule |
| --- | --- |
| `TSR-LOAD-14` | With TanStack Query in the loader, the router **MUST** be created with `defaultPreloadStaleTime: 0`. Canonical for this principle; `TSR-NAV-08` is an alias. |
| `TSR-LOAD-15` | Loader and component **MUST** share the same `queryOptions` object (same `queryKey` and same `queryFn`), **NEVER** two parallel constructions. |
| `TSR-LOAD-16` | In the loader, Query cache warming **MUST** respect the cache: `ensureQueryData`, or `queryClient.query({ ...options, staleTime: 'static' })` where `ensureQueryData` is deprecated (or `prefetchQuery` when blocking is not wanted), **NEVER** `fetchQuery`. |

---

## Version notes

- `loader` has an object form, `{ handler, staleReloadMode }` (`'background'` default, `'blocking'`), missing from most third-party examples.
- Two freshness defaults, not one: `staleTime` is `0`, `preloadStaleTime` is `30_000`. The second breaks the Query integration when not zeroed.
- Preload runs `beforeLoad` **and** the `loader`. "Runs `beforeLoad`, but skips that route's loader" is conditional on `preload: false` on the route.
- `pendingComponent` does not show on fast loads: `defaultPendingMs` is `1000`, so expecting a skeleton on every navigation looks like the option is broken.
- `@tanstack/query-core` 5.104.5 marks `ensureQueryData`, `fetchQuery` and `prefetchQuery` `@deprecated` in favour of `queryClient.query()` (and `infiniteQuery()` for the infinite variants); they still work. Follow the installed version: read its types before choosing.
- Not verified: `guide/route-matching` returned `isNotFound`; the lifecycle order here comes from the Data Loading page.

---

## Antipatterns

```tsx
// WRONG: the waterfall the loader exists to remove
function Post() {
  const { postId } = Route.useParams()
  const [post, setPost] = useState(null)
  useEffect(() => { fetchPostById(postId).then(setPost) }, [postId])
  if (!post) return <Spinner />
  return <article>{post.body}</article>
}

// RIGHT
export const Route = createFileRoute('/posts/$postId')({
  loader: ({ params, abortController }) =>
    fetchPostById(params.postId, { signal: abortController.signal }),
  component: Post,
})
```

```tsx
// WRONG: serial beforeLoad fetching screen data rebuilds the waterfall
beforeLoad: async ({ params }) => ({ post: await fetchPostById(params.postId) })

// RIGHT: beforeLoad gives context; loader fetches, in parallel with siblings
beforeLoad: ({ context }) => ({ api: context.api.forPost() }),
loader: ({ context, params }) => context.api.getPost(params.postId),
```

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `loaderDeps: ({ search }) => search` | any search param, even irrelevant, refetches | list only the fields read (`TSR-LOAD-03`) |
| Loader reading search without `loaderDeps` | cache key omits the param: wrong data served from cache | declare in `loaderDeps` (`TSR-LOAD-04`) |
| `loaderDeps` returning something non-deterministic | key never matches; loader runs on every navigation | return only primitives derived from search |
| `notFoundComponent` on a leaf route | a route without children renders no `Outlet` | move the boundary to the parent (`TSR-LOAD-11`) |
| Analytics in `beforeLoad` | `defaultPreload: 'intent'` fires it on hover | move to an event handler, or to the `loader` filtering on `cause` (`TSR-LOAD-12`) |
| Different query keys in loader and component | loader warms a cache entry the component never reads | one shared `queryOptions` (`TSR-LOAD-15`) |
| TanStack Query in the loader without `defaultPreloadStaleTime: 0` | router holds the preload for 30 s and never re-asks Query | set it on `createRouter` (`TSR-LOAD-14`) |
| `pendingMs: 0` | spinner flickers on every fast navigation | keep the defaults or preserve `pendingMinMs` (`TSR-LOAD-08`) |
