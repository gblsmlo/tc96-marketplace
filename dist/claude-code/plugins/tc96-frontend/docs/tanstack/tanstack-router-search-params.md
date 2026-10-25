---
title: TanStack Router - Search Params
link: https://tanstack.com/router/latest/docs/framework/react/guide/search-params
tags:
  - tanstack-router
  - search-params
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Search Params

## Contents

- [1. Concept: a search param is application state, not a URL string](#1-concept-a-search-param-is-application-state-not-a-url-string)
- [2. `validateSearch`](#2-validatesearch)
- [3. Adapters and Standard Schema](#3-adapters-and-standard-schema)
- [4. Reading: `useSearch`](#4-reading-usesearch)
- [5. Inheritance between routes](#5-inheritance-between-routes)
- [6. Updating: object replaces, function gives access to the previous value](#6-updating-object-replaces-function-gives-access-to-the-previous-value)
- [7. Search middlewares](#7-search-middlewares)
- [8. Custom serialization](#8-custom-serialization)
- [9. Full case: the post-login `redirect` param](#9-full-case-the-post-login-redirect-param)
- [Antipatterns](#antipatterns)

> `validateSearch` · adapters (Zod, Valibot, ArkType, Effect/Schema) · `useSearch` · `getRouteApi().useSearch` · updating through `<Link search>` and `navigate({ search })` · inheritance between routes · `search.middlewares` (`retainSearchParams`, `stripSearchParams`) · `parseSearchWith` / `stringifySearchWith`.
>
> **Does not cover:** `<Link>` and imperative navigation in general: [TanStack Router - Navigation](tanstack-router-navigation.md) · path params (`$id`, `{-$opt}`) and `params.parse`: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · using search in the `loader`: [TanStack Router - Data Loading](tanstack-router-data-loading.md).

Entry: [TanStack Router](tanstack-router.md)

---

## 1. Concept: a search param is application state, not a URL string

Most routers hand out `string | null` from `URLSearchParams`, and the app scatters `Number(params.get('page') ?? '1')` across components. TanStack Router treats the query string as **a typed, validated slice of application state**, with a schema declared on the route. URL state survives refresh and the back button, is shareable and is observable: what `REACT-PAT-10` (skill `react-developer`) mandates. No new ID here: **`REACT-PAT-10` is the rule; this doc is how to meet it with type safety.**

Search params "still came from **a user-facing raw-text input**": anyone can type `?page=banana`, which without a schema becomes `NaN` three components down. A search param is untrusted boundary input, like a request body or an env var; the TypeScript type disappears at runtime, so the schema, not the annotation, guarantees the shape.

**JSON-first serialization.** The first level stays flat and `URLSearchParams`-compatible; nested values become JSON strings, so `page` comes back as `number` and `desc` as `boolean` with no manual conversion:

```tsx
search={{ pageIndex: 3, includeCategories: ['electronics', 'gifts'], sortBy: 'price', desc: true }}
// /shop?pageIndex=3&includeCategories=%5B%22electronics%22%2C%22gifts%22%5D&sortBy=price&desc=true
```

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-01` | A route that reads a search param **MUST** declare `validateSearch`: without a schema there is no type, no default and no shape guarantee. |
| `TSR-SEARCH-02` | `window.location.search`, `URLSearchParams` and another library's `useSearchParams` are **NEVER** used to read search inside a router route: the source is `useSearch`. |

---

## 2. `validateSearch`

At its rawest, a function from `Record<string, unknown>` to the validated type:

```tsx
type ProductSearch = { page: number; filter: string; sort: 'newest' | 'oldest' | 'price' }

export const Route = createFileRoute('/shop/products')({
  validateSearch: (search: Record<string, unknown>): ProductSearch => ({
    page: Number(search?.page ?? 1),
    filter: (search.filter as string) || '',
    sort: (search.sort as ProductSearch['sort']) || 'newest',
  }),
})
```

Every key has defined behaviour for missing and for invalid, so `page` is never `undefined`: that is what makes the output type trustworthy, and why the input is `Record<string, unknown>`, not an already-typed object.

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-03` | Every key of the search schema **MUST** define behaviour for a missing value and for an invalid value: `.catch()`, `.default()` or an explicit fallback. A schema that only describes the happy path validates nothing. |

---

## 3. Adapters and Standard Schema

**Zod v4, Valibot, ArkType and Effect/Schema** implement Standard Schema and are passed directly; **Zod v3** needs `zodValidator`:

```tsx
const productSearchSchema = z.object({
  page: z.number().catch(1),
  filter: z.string().catch(''),
  sort: z.enum(['newest', 'oldest', 'price']).catch('newest'),
})

createFileRoute('/shop/products/')({ validateSearch: productSearchSchema })               // Standard Schema
createFileRoute('/shop/products/')({ validateSearch: zodValidator(productSearchSchema) }) // Zod v3, from @tanstack/zod-adapter
```

**`.catch()` or `.default()` is a product decision.** Upstream uses `.catch()` so a malformed param does not "halt the user's experience [...] to show a big fat error message", and `.default()` when you "**do want to show an error message**". `.catch()` degrades silently to a sensible value; `.default()` only covers absence, and a malformed value goes to the route's error handling. A list filter wants `.catch()`; a param that changes the page's meaning (a resource id, a form mode) probably wants the visible error.

**The Zod v3 trap.** In Zod v3, `.catch()` turns the keys' types into `unknown`. `fallback()` keeps the type and supplies the value on failure:

```tsx
import { fallback, zodValidator } from '@tanstack/zod-adapter'

const productSearchSchema = z.object({
  page: fallback(z.number(), 1).default(1),
  filter: fallback(z.string(), '').default(''),
  sort: fallback(z.enum(['newest', 'oldest', 'price']), 'newest').default('newest'),
})
```

The symptom is silent: the schema works, `useSearch` returns `unknown`, and TypeScript stops flagging misuse. **Not verified:** configuring diverging `input`/`output` types in the adapter (mentioned upstream, signature not shown).

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-04` | The choice between `.catch()` and `.default()` **MUST** be deliberate: `.catch()` when a malformed value should degrade silently; `.default()` when it should become a visible error. |
| `TSR-SEARCH-05` | With Zod v3, `.catch()` in the search schema **NEVER** appears without `fallback()` from `@tanstack/zod-adapter`: the type collapses to `unknown`. |
| `TSR-SEARCH-06` | Zod v3 **MUST** go through `zodValidator`; libraries that implement Standard Schema (Zod v4, Valibot, ArkType, Effect/Schema) **MUST** be passed directly, without a wrapper. |

---

## 4. Reading: `useSearch`

```tsx
const { page, filter, sort } = Route.useSearch()
//      ^? number, string, 'newest' | 'oldest' | 'price'

// component that cannot import Route (separate file, internal library): same type, no circular import
const routeApi = getRouteApi('/shop/products')
const routeSearch = routeApi.useSearch()
```

| Option | Behaviour |
| --- | --- |
| `from` | route id to read from; required in the strict form |
| `strict` (default `true`) | `false` ignores `from` and loosens types to `Partial<FullSearchSchema>` |
| `shouldThrow` (default `true`) | `false` does not throw an invariant when no match is found |
| `select` | `(search) => TSelected`; the hook returns its result |
| `structuralSharing` | structural sharing for the `select` result |

`select` narrows what the component observes; with `structuralSharing` it avoids re-renders when another key changes:

```tsx
const page = Route.useSearch({ select: (search) => search.page }) // re-renders only when page changes
```

`strict: false` is the escape hatch for genuinely generic components (a `<Pagination>` used across routes); the price is `Partial<...>`, so the component must handle absence.

---

## 5. Inheritance between routes

Child routes see the search validated by their ancestors, with merged types:

```tsx
export const Route = createFileRoute('/shop/products/$productId')({
  beforeLoad: ({ search }) => {
    search // ProductSearch, inherited from the parent route
  },
})
```

**Where you declare `validateSearch` defines the state's scope**: on `/shop/products`, the whole subtree; on the root, the whole app. The retention middlewares (§ 7) live with the schema because scope and propagation policy are one decision.

---

## 6. Updating: object replaces, function gives access to the previous value

```tsx
<Link from={Route.fullPath} search={{ page: 2, filter: 'new' }}>Next Page</Link>                // defines the resulting search
<Link from={Route.fullPath} search={(prev) => ({ ...prev, page: prev.page + 1 })}>Next Page</Link>
<Link to="." search={(prev) => ({ ...prev, page: prev.page + 1 })}>Next Page</Link>             // generic: keeps current route

const navigate = useNavigate({ from: Route.fullPath })
navigate({ search: (prev) => ({ page: prev.page + 1 }) })
router.navigate({ search: (prev) => ({ ...prev, page: 2 }) })
```

The upstream `navigate` example above does **not** spread `prev`, so it drops `filter` and `sort`: intentional to reset filters on paging, a bug otherwise. The functional form does not merge by itself; it only gives access to the previous value.

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-07` | An update of a single search key **MUST** use the functional form with spread (`(prev) => ({ ...prev, page })`): an object literal and a function without spread replace the whole search. |
| `TSR-SEARCH-08` | A component reused by several routes **MUST** navigate with `to="."` and the functional form, **NEVER** with the route path written by hand. |
| `TSR-SEARCH-09` | A value that already lives in search is **NEVER** copied into `useState`: alias of `REACT-PAT-01` and `REACT-PAT-03` (skill `react-developer`). Two sources of truth diverge on the back button. |
| `TSR-SEARCH-10` | Tokens, credentials, session ids and personal data **NEVER** go into a search param: the URL goes to history, server logs, `Referer` and shared links. |

---

## 7. Search middlewares

Middlewares transform search **when links are generated**, before the URL is built, so a param can follow the user across navigation without `search={(prev) => ...}` on every `<Link>`.

```tsx
export const Route = createRootRoute({
  validateSearch: zodValidator(searchSchema),
  search: {
    middlewares: [
      ({ search, next }) => {
        const result = next(search)
        return { rootValue: search.rootValue, ...result }
      },
    ],
  },
})
```

**`retainSearchParams`** takes `true` (retain all) or a list of keys: `retainSearchParams(['rootValue'])`, `retainSearchParams(true)`. Typical case: `?tenant=` or `?locale=` that must not disappear on any link click.

**`stripSearchParams`**:

| Input | Semantics |
| --- | --- |
| `true` | strips all; only when the schema has no required params |
| array of keys | always strips those keys; only optional keys allowed |
| object (partial input schema) | strips a param when its value is deeply equal to the object's |

```tsx
search: { middlewares: [stripSearchParams({ one: 'abc', two: 'xyz' })] } // strips params at their default
```

The object form gives clean URLs (`/shop/products` instead of `/shop/products?page=1&filter=&sort=newest`) but couples the middleware to the schema: if the schema default becomes `sort: 'price'` and `stripSearchParams` keeps `'newest'`, the URL carries `?sort=newest` as if the user chose it.

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-11` | A middleware that retains or strips a key **MUST** be declared on the same route that validates that key: the schema's scope is the policy's scope. |
| `TSR-SEARCH-12` | The values passed to `stripSearchParams({ ... })` **MUST** be exactly the schema defaults. A mismatch turns the old default into an explicit URL param. |
| `TSR-SEARCH-13` | `stripSearchParams` with an array **MUST** list only optional keys, and the `true` form **MUST** be used only when the schema has no required key. |

---

## 8. Custom serialization

`createRouter` takes `parseSearch` / `stringifySearch`, built with `parseSearchWith` / `stringifySearchWith`. Default is `JSON.parse` / `JSON.stringify` (`filters: { author: 'tanner' }` becomes `filters=%7B%22author%22%3A%22tanner%22%7D`). Documented alternatives: Base64, `query-string`, JSURL2, Zipson (compressed).

```tsx
const router = createRouter({
  routeTree,
  parseSearch: parseSearchWith(JSON.parse),
  stringifySearch: stringifySearchWith(JSON.stringify),
})
```

Upstream warnings: Base64 over user input risks "a collision with the URL deserialization"; native `atob`/`btoa` "aren't guaranteed to work properly with non-UTF8 characters", and the docs provide safe encoding utilities instead.

**Serialization is part of your URLs' public contract.** Shared links, bookmarks, history and URLs in emails keep the old format; switching `JSON` to JSURL2 after launch breaks all of them at once, and the symptom is `validateSearch` falling into the fallback.

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-14` | `parseSearch`/`stringifySearch` **MUST** be decided once, in `createRouter`, before the app goes public: serialization is the contract of already-shared URLs. |
| `TSR-SEARCH-15` | Base64 is **NEVER** applied to user input in the URL (deserialization collision risk), and native `atob`/`btoa` are **NEVER** used as the encoder: use the documented safe utilities. |

---

## 9. Full case: the post-login `redirect` param

The most common search param carrying navigation state, and the one where it becomes **attack surface**. The guard writes the destination ([TanStack Router - Navigation](tanstack-router-navigation.md) § 6):

```tsx
// routes/_authenticated.tsx
beforeLoad: ({ context, location }) => {
  if (!context.auth.isAuthenticated) throw redirect({ to: '/login', search: { redirect: location.href } })
}
```

`/login` validates that key like any other, missing and invalid included (`TSR-SEARCH-03`):

```tsx
// routes/login.tsx
const safeInternalPath = z
  .string()
  .refine((v) => v.startsWith('/') && !v.startsWith('//'), 'external destination')
  .catch('/')

export const Route = createFileRoute('/login')({
  validateSearch: zodValidator(z.object({ redirect: fallback(safeInternalPath, '/') })),
})

function Login() {
  const { redirect: destination } = Route.useSearch()
  const navigate = useNavigate()

  async function onSignIn(credentials: Credentials) {
    await authenticate(credentials)
    navigate({ to: destination, replace: true }) // replace: TSR-NAV-09
  }
}
```

**The `refine` is not optional.** Anyone can send `/login?redirect=https://evil.example/phish`; without validation your real login screen drops the authenticated user on a third-party domain (**open redirect**). Coming "from your own router" does not make the value trusted. Both checks matter: starts with `/` (internal path) and does **not** start with `//` (protocol-relative URL, an external host).

| ID | Rule |
| --- | --- |
| `TSR-SEARCH-16` | A search param that becomes a navigation destination **MUST** be validated as an internal path (starts with `/`, not with `//`) before use. Without it, it is an open redirect. |
| `TSR-SEARCH-17` | A navigation that consumes a stored destination **MUST** have a fallback defined for a missing or rejected value, never navigating to `undefined`. |

**Not verified:** whether `location.href` in `beforeLoad` is the router's relative href or the browser's absolute one. `TSR-SEARCH-16` is safe either way: an absolute same-origin href is rejected and falls back (losing the destination). Confirm the format before relaxing the rule.

---

## Antipatterns

```tsx
// WRONG: two sources of truth, the back button changes the URL and local state goes stale
const [page, setPage] = useState(1)
const search = Route.useSearch()
useEffect(() => setPage(search.page), [search.page])

// RIGHT: the URL is the state
const { page } = Route.useSearch()
const navigate = useNavigate({ from: Route.fullPath })
const setPage = (page: number) => navigate({ search: (prev) => ({ ...prev, page }) })
```

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Zod v3 `z.number().catch(1)` through `zodValidator` | search reads as `unknown`, no misuse is caught | `fallback(z.number(), 1).default(1)` (`TSR-SEARCH-05`) |
| `<Link to="." search={{ page: page + 1 }}>` | the object literal drops `filter` and `sort` | `(prev) => ({ ...prev, page: prev.page + 1 })` (`TSR-SEARCH-07`) |
| Reading `new URLSearchParams(location.search)` in a route | ignores the router's schema, types and reactivity | `useSearch` (`TSR-SEARCH-02`) |
| Schema keys without `.catch()`/`.default()` | `?page=banana` reaches the component as `NaN` | explicit behaviour per key (`TSR-SEARCH-03`) |
| `validateSearch` typing its argument as already validated | the function exists to convert `unknown` | signature `(search: Record<string, unknown>)` |
| `stripSearchParams` with defaults out of sync with the schema | the old default leaks into the URL as an explicit choice | mirror the defaults (`TSR-SEARCH-12`) |
| `?token=` or `?email=` to "pass between screens" | the URL goes to history, logs and `Referer` | route context or `state` (`TSR-SEARCH-10`) |
| Changing serialization after launch | shared URLs stop deserializing | decide once (`TSR-SEARCH-14`) |
