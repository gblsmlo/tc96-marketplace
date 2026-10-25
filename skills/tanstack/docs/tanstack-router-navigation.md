---
title: TanStack Router - Navigation
link: https://tanstack.com/router/latest/docs/framework/react/guide/navigation
tags:
  - tanstack-router
  - navigation
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Navigation

## Contents

- [1. Concept: every navigation is relative and typed](#1-concept-every-navigation-is-relative-and-typed)
- [2. `<Link>` is the default, and not for style](#2-link-is-the-default-and-not-for-style)
- [3. Active state](#3-active-state)
- [4. Preload: perceived performance has a price](#4-preload-perceived-performance-has-a-price)
- [5. Imperative navigation](#5-imperative-navigation)
- [6. `redirect()` in `beforeLoad` and `loader`](#6-redirect-in-beforeload-and-loader)
- [7. Reading router state](#7-reading-router-state)
- [8. Navigation blocking](#8-navigation-blocking)
- [9. Route masking](#9-route-masking)
- [10. `linkOptions`](#10-linkoptions)
- [Antipatterns](#antipatterns)

> `<Link>` · `useNavigate` · `<Navigate>` · `router.navigate` · `redirect` · `useRouter` · `useMatch` / `useMatches` · `useMatchRoute` / `<MatchRoute>` · `useBlocker` / `<Block>` · `linkOptions` · route masking.
>
> **Does not cover:** path syntax and route definition (`$param`, `{-$opt}`, layouts): [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · validating and reading search params: [TanStack Router - Search Params](tanstack-router-search-params.md) · what `loader` and `beforeLoad` load: [TanStack Router - Data Loading](tanstack-router-data-loading.md).

Entry: [TanStack Router](tanstack-router.md)

---

## 1. Concept: every navigation is relative and typed

**Relative.** Every navigation has an origin (`from`) and a destination (`to`), "even if you aren't using explicit relative path syntax". Without `from`, "the router will assume you are navigating from the root `/` route": `..` climbs from `/`, not from the current route.

**Typed.** `to` is a literal union generated from the route tree. A typo like `/psots/$postId` is a compile error, not a runtime 404. The type of `to` decides which `params` and `search` keys are required (`/posts/$postId` requires `params.postId`; a route with `validateSearch` requires its schema keys). Renaming a route file breaks compilation at every link to it instead of leaving silent dead links.

### The three option layers

```ts
type ToOptions = {
  from?: string
  to: string
  params?: Record<string, unknown> | ((prevParams: Record<string, unknown>) => Record<string, unknown>)
  search?: Record<string, unknown> | ((prevSearch: Record<string, unknown>) => Record<string, unknown>)
  hash?: string | ((prevHash: string) => string)
  state?: Record<string, any> | ((prevState: Record<string, unknown>) => Record<string, unknown>)
  mask?: ToMaskOptions<TRouteTree>
}

type NavigateOptions = ToOptions & {
  replace?: boolean
  resetScroll?: boolean
  hashScrollIntoView?: boolean | ScrollIntoViewOptions
  viewTransition?: boolean | ViewTransitionOptions
  ignoreBlocker?: boolean
  reloadDocument?: boolean
  href?: string
}

type LinkOptions = NavigateOptions & {
  target?: HTMLAnchorElement['target']
  activeOptions?: { exact?: boolean; includeHash?: boolean; includeSearch?: boolean; explicitUndefined?: boolean }
  preload?: false | 'intent' | 'viewport' | 'render'
  preloadDelay?: number
  disabled?: boolean
}
```

`<Link>` takes all of it; `navigate()` and `redirect()` take `NavigateOptions`. Upstream: do not interpolate path params, hash or search into `to`; `params` is "the only way to interpolate dynamic parameters into the final URL."

| ID | Rule |
| --- | --- |
| `TSR-NAV-01` | `to` **NEVER** takes an interpolated string (`` `/posts/${id}` ``): path params go in `params`, query in `search`, fragment in `hash`. |

Interpolation drops the string out of the literal union, the type degrades to `string`, and no destination error is caught at build time.

---

## 2. `<Link>` is the default, and not for style

`<Link>` renders a real anchor with `href`, which gives for free: Ctrl/Cmd + click and middle click to a new tab, "copy link address", the destination in the status bar, the `link` role for screen readers, intent preload (§ 4) and active state (§ 3). `onClick={() => navigate(...)}` on a `<button>` or `<div>` loses all of them. Upstream recommends `Link` "for anything the user can interact with", and `useNavigate` only for "side-effect navigations".

| ID | Rule |
| --- | --- |
| `TSR-NAV-02` | An element the user clicks to change route **MUST** be a `<Link>`. `useNavigate` in `onClick` is **NEVER** used when the destination is already known at render time. |

**Side-effect navigation criterion:** `navigate()` is fine when the destination only exists after an effect (id returned by a mutation, auth result, session expiry, end of a wizard, `setTimeout`). If you can write `to` and `params` during render, it is `<Link>`.

### Absolute, relative, `.` and `..`

Links are absolute by default; relative requires `from`. Use `route.fullPath`, "a reference that will update if you refactor your application". `.` reloads the current location (or the one in `from`); `..` climbs one route.

```tsx
const postIdRoute = createRoute({ path: '/blog/post/$postId' })
const link = <Link from={postIdRoute.fullPath} to="../categories">Categories</Link>

// inside createFileRoute('/posts/$postId')
<Link to=".">Reload the current route of /posts/$postId</Link>
<Link to="..">Navigate back to /posts</Link>
<Link from="/posts" to=".">Navigate back to /posts</Link>
<Link from="/posts" to="..">Navigate to root</Link>
```

`from="/posts"` with `to=".."` goes to the root: relativity is always against `from`, and a missing `from` means `/`. In a pathless layout route, "the `from` location is regarded as the parent of the pathless layout route."

| ID | Rule |
| --- | --- |
| `TSR-NAV-03` | A link with a relative `to` (`.`, `..`, `../something`) **MUST** declare `from`: without it the origin is `/`, not the current route. |
| `TSR-NAV-04` | `from` **MUST** come from `Route.fullPath` / `route.fullPath`, **NEVER** from a string literal repeated in JSX. |

### `params`: object replaces, function inherits

With optional params (`{-$param}`), "not mentioned" and "passed `undefined`" differ:

```tsx
<Link to="/posts/{-$category}" params={{}}>All Posts</Link>                     {/* inherits current param */}
<Link to="/posts/{-$category}" params={{ category: undefined }}>All Posts</Link> {/* removes it */}
<Link to="/articles/{-$category}/{-$slug}" params={(prev) => ({ ...prev, category: 'news' })}>
  News Articles
</Link>
```

### `hash`: the hydration-mismatch caveat

The browser never sends the fragment to the server, so under SSR "the hash fragment will not be available on the server-side, and hydration mismatches can occur when using the hash for rendering markup". Problem patterns: echoing the hash in markup, conditional rendering on it, active link state from it.

| ID | Rule |
| --- | --- |
| `TSR-NAV-05` | In an SSR app, `hash` **NEVER** decides rendered markup, conditional rendering or active state: only a scroll target. |

### `state`: history API, not URL

`state` lives in the history API: it does not survive sharing the link, is not in the URL, and is lost when the user reloads by typing the address. Use it for ephemeral transition data (origin scroll position, "came from"). State the user expects back when pasting the link belongs in `search`: `REACT-PAT-10` (skill `react-developer`), detailed in [TanStack Router - Search Params](tanstack-router-search-params.md).

---

## 3. Active state

`activeProps` / `inactiveProps`: props other than style and class override the `Link` props; styles and classes are merged. Two cheaper outputs:

```tsx
<Link to="/posts" activeProps={{ style: { fontWeight: 'bold' } }}>Posts</Link>

// data-status="active" | undefined on the DOM: style with a[data-status='active']
<Link to="/posts">Posts</Link>

<Link to="/blog/post">
  {({ isActive }) => <span className={isActive ? 'active' : 'inactive'}>My Blog Post</span>}
</Link>
```

### `activeOptions` and the classic "Home" link bug

Defaults: the resulting **pathname** is checked as a prefix of the current route; provided search params must match _inclusively_; hashes are not checked.

| Option | Effect |
| --- | --- |
| `exact: true` | the link stops being active on a child route |
| `includeHash: true` | includes the hash in the comparison |
| `includeSearch: false` | ignores search params in the comparison |
| `explicitUndefined: true` | keys explicitly `undefined` in `search` must **not** exist in the current URL for the link to count as active |

`/` prefixes everything, so the home link is permanently active without `exact`:

```tsx
<Link to="/" activeOptions={{ exact: true }}>Home</Link>
```

| ID | Rule |
| --- | --- |
| `TSR-NAV-06` | A link whose `to` is a prefix of other routes (`/`, any parent route with children) **MUST** declare `activeOptions={{ exact: true }}` if the highlight should apply only to it. |

---

## 4. Preload: perceived performance has a price

| `preload` | Behaviour |
| --- | --- |
| `false` | turns off automatic preload |
| `'intent'` | on focus, hover or touch |
| `'viewport'` | when the link enters the viewport (Intersection Observer) |
| `'render'` | as soon as the link is rendered in the DOM |

For `'intent'` and `'viewport'`, `preloadDelay` (default **50 ms**) waits before preloading; if focus/hover ends or the link leaves the viewport first, the queued preload is cancelled. Touch intent preloads immediately.

```tsx
<Link to="/blog/post/$postId" preload="intent" preloadDelay={100}>Blog Post</Link>
```

**Cost.** Preload runs the target route's dependencies, `loader` included, not just the code chunk: every preloading link is a potential real request. `'intent'` with a delay costs in proportion to shown intent; `'render'` on a 200-item list fires 200 loaders on mount; `'viewport'` sits in between.

Two independent cache policies: freshness defaults to **30 seconds** (`defaultPreloadStaleTime` or a route's `preloadStaleTime`); unused retention defaults to **5 minutes** (`defaultPreloadGcTime` or a route's `preloadGcTime`). If the loader delegates to [TanStack Query](tanstack-query.md), two caches overlap and the router's must step aside: with `0`, "Settled preload data then becomes immediately stale in the Router, while retention still follows `preloadGcTime`."

```tsx
const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
  defaultPreloadStaleTime: 0, // freshness policy belongs to TanStack Query
})
```

| ID | Rule |
| --- | --- |
| `TSR-NAV-07` | `preload="render"` is **NEVER** applied to a link inside an unbounded list: every link mounts and fires the target's loader. |
| `TSR-NAV-08` | If the `loader` uses TanStack Query, `defaultPreloadStaleTime` **MUST** be `0`, so freshness is decided in one cache. **Alias of `TSR-LOAD-14`**: cite the canonical in review. |

---

## 5. Imperative navigation

```tsx
const navigate = useNavigate({ from: '/posts/$postId' }) // from on the hook, not per call, "to reduce on potential error"

const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault()
  const response = await fetch('/posts', { method: 'POST', body: JSON.stringify({ title: 'My First Post' }) })
  const { id: postId } = await response.json()
  if (response.ok) navigate({ to: '/posts/$postId', params: { postId } })
}
```

| API | When |
| --- | --- |
| `useNavigate({ from })` | inside a component, navigation as a side effect |
| `<Navigate to="..." />` | client-only redirect on component mount; "_definitely not_ a substitute for handling server-aware redirects responsibly on the server" |
| `router.navigate({ ... })` | outside React (HTTP interceptor, websocket listener, third-party code): available wherever the `router` instance is |

| `NavigateOptions` | Effect |
| --- | --- |
| `replace` | replace the current history entry instead of pushing a new one |
| `resetScroll` | reset scroll position to 0,0 |
| `hashScrollIntoView` | scroll the element whose id matches the hash into view |
| `viewTransition` | if and how `document.startViewTransition()` is called |
| `ignoreBlocker` | ignore any blockers |
| `reloadDocument` | full page load |
| `href` | used in place of `to` with a full built href |

| ID | Rule |
| --- | --- |
| `TSR-NAV-09` | A navigation that consumes the current route (post-login, post-wizard submit, redirect from an intermediate route) **MUST** use `replace: true`, or the back button returns the user to an already-consumed state. |

---

## 6. `redirect()` in `beforeLoad` and `loader`

**`redirect()` does not redirect by itself by default.** With `throw: true` the `Redirect` object is thrown; with `throw: false | undefined` it is returned. A bare `redirect({ to: '/login' })` statement creates an object and discards it. Correct forms: `throw redirect({ ... })` or `redirect({ ..., throw: true })`.

```tsx
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({ to: '/login', search: { redirect: location.href } })
    }
  },
})
```

`search.redirect = location.href` is the documented way to resume the destination after login ([TanStack Router - Search Params](tanstack-router-search-params.md) § 9). Inside `try/catch`, the redirect is caught by your own error handling; re-throw it:

```tsx
try {
  const user = await verifySession()
  if (!user) throw redirect({ to: '/login', search: { redirect: location.href } })
  return { user }
} catch (error) {
  if (isRedirect(error)) throw error
  // handle real auth failures
}
```

`Route.redirect` and `getRouteApi().redirect` are preferred upstream over the standalone `redirect` (type safety, automatic path resolution). None of these replaces a server-side redirect: to redirect before the app mounts, redirect on the server.

| ID | Rule |
| --- | --- |
| `TSR-NAV-10` | `redirect()` **MUST** be thrown (`throw redirect(...)`) or receive `throw: true`: a call without either is a no-op. |
| `TSR-NAV-11` | A `try/catch` around code that calls `redirect` **MUST** re-throw when `isRedirect(error)` is true. |
| `TSR-NAV-12` | Access control **NEVER** exists only as a client-side redirect: the protected data is still served if the server does not deny it. |

---

## 7. Reading router state

### `useRouter` and the `router.state` trap

> "`router.state` is always up to date, but NOT REACTIVE. If you use `router.state` in a component, the component will not re-render when the router state changes."

Reactive state comes from `useRouterState`. `useRouter` is for the instance: `router.navigate`, `router.matchRoute`, `router.invalidate`.

| ID | Rule |
| --- | --- |
| `TSR-NAV-13` | `router.state` is **NEVER** read during render to derive UI: use `useRouterState`, `useMatch` or `useMatches`. |

### `useMatch` and `useMatches`

`useMatches()` returns the full presented `RouteMatch[]` **regardless of the caller's position in the tree** (what makes breadcrumbs work anywhere). Caveat: it "can include still-loading descendants or matches below a pending/error/not-found render boundary". Hierarchical slices: `useParentMatches`, `useChildMatches`.

| Option | `useMatch` | `useMatches` |
| --- | --- | --- |
| `from` | match route id; optional, recommended for full type safety | n/a |
| `strict` | default `true`; `false` loosens the types | n/a |
| `shouldThrow` | default `true`; `false` does not throw an invariant when no match is found | n/a |
| `select` | `(match: RouteMatch) => TSelected` | `(matches: RouteMatch[]) => TSelected` |
| `structuralSharing` | structural sharing for the `select` result | same |

### `useMatchRoute` vs `router.matchRoute`

```tsx
<Link to="/users">
  Users
  <MatchRoute to="/users" pending><Spinner /></MatchRoute>
</Link>
```

The `matchRoute` returned by `useMatchRoute` changes identity when the relevant router state changes. To check the route when an event occurs, use the stable instance:

```tsx
const router = useRouter()
<button onClick={() => { if (router.matchRoute({ to: '/users' }, { fuzzy: true })) console.info('active') }}>
  Check current route
</button>
```

| ID | Rule |
| --- | --- |
| `TSR-NAV-14` | A route check inside an event handler or an effect dependency **MUST** use `router.matchRoute`: `useMatchRoute` changes identity on every relevant state change. |

---

## 8. Navigation blocking

```tsx
useBlocker({
  shouldBlockFn: () => {
    if (!formIsDirty) return false
    const shouldLeave = confirm('Are you sure you want to leave?')
    return !shouldLeave
  },
})

// own UI instead of confirm(): status === 'blocked' renders the dialog, proceed() releases, reset() cancels
const { proceed, reset, status } = useBlocker({
  shouldBlockFn: ({ current, next }) => current.routeId === '/foo' && next.fullPath === '/bar/$id',
  withResolver: true,
})
```

`<Block>` offers the same through render props.

**Ambiguity in the source.** The page prose says a blocker returning `true` allows navigation and `false` cancels it. That contradicts the option name and the page's own examples (`return false` on a clean form **allows** leaving; `return !shouldLeave` **blocks** when the user cancels), which only make sense with "`true` blocks"; the prose seems to describe the old `blockerFn`. Treat `shouldBlockFn` as its name says, and confirm with observed behaviour before inverting any condition.

Leaving the document (close tab, reload) is a separate channel: "even if `shouldBlockFn` returns `false`, the browser's `beforeunload` event may still be triggered". `enableBeforeUnload` takes a boolean or a function. **Not verified:** the default of `enableBeforeUnload` and the exact behaviour of `disabled`. `navigate({ ..., ignoreBlocker: true })` bypasses blockers.

| ID | Rule |
| --- | --- |
| `TSR-NAV-15` | A form with unsaved changes **MUST** block both internal navigation (`shouldBlockFn`) and document exit (`enableBeforeUnload`): they are two separate channels. |
| `TSR-NAV-16` | The navigation the flow itself fires after saving **MUST** use `ignoreBlocker: true`, or the user sees the discard dialog on the happy path. |

---

## 9. Route masking

Show one URL, navigate to another. Canonical case: a modal whose real route is `/photos/$photoId/modal`, displayed as `/photos/$photoId`. `navigate()` takes the same `mask` object as `<Link>`.

```tsx
<Link
  to="/photos/$photoId/modal"
  params={{ photoId: 5 }}
  mask={{ to: '/photos/$photoId', params: { photoId: 5 } }}
>
  Open Photo
</Link>

// declarative, at router level
const photoModalToPhotoMask = createRouteMask({
  routeTree,
  from: '/photos/$photoId/modal',
  to: '/photos/$photoId',
  params: (prev) => ({ photoId: prev.photoId }),
})
const router = createRouter({ routeTree, routeMasks: [photoModalToPhotoMask] })
```

**Mechanism.** The real location lives in history `location.state` under `__tempLocation`; the original URL stays in `location.maskedLocation`. Sharing the link unmasks (state does not travel); reloading does **not** unmask by default (state survives in history). `unmaskOnReload` changes that, at three priority levels: router default option, `createRouteMask()` return, direct prop on `<Link>`/`navigate()`.

| ID | Rule |
| --- | --- |
| `TSR-NAV-17` | A mask is **NEVER** used to hide sensitive information from the URL: the shared link opens the real route, unmasked. |

---

## 10. `linkOptions`

A navigation object literal is only type-checked when spread into `Link`. `linkOptions` checks it like `Link` would and returns it as is; it accepts an array and keeps extra properties `Link` lacks (the shape for menus).

```tsx
const dashboardLinkOptions = linkOptions({ to: '/dashboard', search: { search: '' } })
const link = <Link {...dashboardLinkOptions} />

const options = linkOptions([
  { to: '/dashboard', label: 'Summary', activeOptions: { exact: true } },
  { to: '/dashboard/invoices', label: 'Invoices' },
])
```

| ID | Rule |
| --- | --- |
| `TSR-NAV-18` | A navigation object declared outside JSX (menus, constants, config) **MUST** go through `linkOptions`: without it the destination is not checked until the spread. |

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `` <Link to={`/posts/${post.id}`}> `` | the type degrades to `string`, invalid destinations stop being compile errors | `to="/posts/$postId" params={{ postId: post.id }}` (`TSR-NAV-01`) |
| `<button onClick={() => navigate(...)}>` to a known destination | loses href, ctrl+click, new tab, link role and preload | `<Link>` (`TSR-NAV-02`) |
| `<Link to="..">` without `from` | `..` climbs from `/` | `from={Route.fullPath}` (`TSR-NAV-03`) |
| Bare `redirect({ to: '/login' })` in `beforeLoad` | returns an object that is discarded | `throw redirect(...)` (`TSR-NAV-10`) |
| `<Link to="/">Home</Link>` with active styling | `/` prefixes every route, always active | `activeOptions={{ exact: true }}` (`TSR-NAV-06`) |
| Global `defaultPreload: 'render'` | fires the loader of every mounted link, long lists included | `'intent'` as default, `'render'` case by case (`TSR-NAV-07`) |
| Reading `router.state.location` in render | `router.state` is not reactive, no re-render | `useRouterState` / `useMatch` (`TSR-NAV-13`) |
| `try/catch` swallowing `redirect` in `beforeLoad` | the redirect becomes a "handled error", navigation never happens | `if (isRedirect(error)) throw error` (`TSR-NAV-11`) |
| `mask` to hide an id or token from the URL | the shared link opens the real route | keep the data out of the route (`TSR-NAV-17`) |
| Navigation menu with loose object literals | invalid destinations fail only at the spread, or not at all | `linkOptions` (`TSR-NAV-18`) |
