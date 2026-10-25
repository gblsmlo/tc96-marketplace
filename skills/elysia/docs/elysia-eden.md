---
title: Elysia - Eden
link: https://elysiajs.com/eden/overview.html
tags:
  - elysia
  - eden
  - agent-context
source: "Official documentation — https://elysiajs.com/ — cross-checked by executing every behaviour on elysia 1.4.30, @elysia/eden 1.4.10 and @tanstack/query-core 5.104.5"
verified-at: 2026-10-25
---

# Elysia — Eden

## Contents

- [0. Decision tree — how does this client call this server?](#0-decision-tree--how-does-this-client-call-this-server)
- [1. Concept: the type crosses, the code does not](#1-concept-the-type-crosses-the-code-does-not)
- [2. Eden Treaty: config and call shapes](#2-eden-treaty-config-and-call-shapes)
- [3. The return value: a union you narrow by status](#3-the-return-value-a-union-you-narrow-by-status)
- [4. The TanStack Query bridge](#4-the-tanstack-query-bridge)
- [5. A typed domain error reaching the form](#5-a-typed-domain-error-reaching-the-form)
- [6. The paginated envelope](#6-the-paginated-envelope)
- [7. Tests](#7-tests)
- [8. Files, streams and WebSocket](#8-files-streams-and-websocket)
- [9. Eden Fetch](#9-eden-fetch)
- [10. When Eden returns any (or loses a route)](#10-when-eden-returns-any-or-loses-a-route)
- [Antipatterns](#antipatterns)
- [Review checklist](#review-checklist)

> `export type App` and `import type` · Eden Treaty: config, call shapes, the return union · narrowing errors by status · the TanStack Query bridge (unwrap, retry, `parseDate`) · typed domain errors in a form · the paginated envelope · tests with `treaty(app)` · files, SSE, WebSocket · Eden Fetch · when Eden returns `any`.
>
> **Does not cover:** the schemas the contract is built from ([Elysia - Schema and Validation](elysia-schema-and-validation.md)) · routes and errors on the server ([Elysia - Routing and Handler](elysia-routing-and-handler.md)) · the OpenAPI document, for clients that are not TypeScript ([Elysia - OpenAPI](elysia-openapi.md)).

Entry: [Elysia](elysia.md) · Normative basis: [Elysia](elysia.md) § 6

Behaviour marked *verified* was executed on 2026-10-25 with the versions above; the tests live outside this repository, in the authoring playground.

---

## 0. Decision tree — how does this client call this server?

```
Is the consumer TypeScript, in the same repository or workspace as the server?
├── NO → publish the OpenAPI document and generate a client from it  → Elysia - OpenAPI
└── YES → Eden. Which form?
    ├── more than ~500 routes consumed by ONE frontend → edenFetch (cheaper for the compiler)
    └── otherwise → treaty (the default)
        │
        Where does the result go?
        ├── into TanStack Query → unwrap and throw in queryFn/mutationFn          § 4
        │                          retry only 5xx; parseDate: false               § 4
        ├── into a form (a mutation's error) → narrow error.status, read value    § 5
        └── used directly → check error before data; switch on error.status       § 3
        │
        Who calls it in tests?
        ├── a server-side test → treaty(app): no fetcher, no network              § 7
        └── the production client config under test → URL form + a fetcher
                                                      that calls app.handle       § 7
```

---

## 1. Concept: the type crosses, the code does not

Eden is a client typed by `typeof app`, with no code generation. The server ends its chain with `export type App = typeof app`; the client imports **only that type** and gets every route, every body and query, and every response status declared in a `response` map, as a discriminated union.

Three conditions, all verified:

1. **Unbroken method chaining on the server** (`ELYSIA-APP-01`). A route registered in a separate statement still serves, but `keyof typeof api` does not have it — the client cannot call it without an error.
2. **`strict: true` and TypeScript >= 5.0 on both sides** (`ELYSIA-APP-04`), and **one `elysia` version** across client and server (`ELYSIA-TYPE-11`).
3. **`import type`** on the client (`ELYSIA-TYPE-14`). A value import of the server module pulls the server — and everything it imports — into the browser bundle.

What the client sees is exactly what the server *declares*. Verified: a status declared in the route's `response` map is in the client type whether the handler returns or throws it; without a map, a **returned** `status(404, …)` still enters the type with its literal value, and a **thrown** one does not. At runtime both arrive the same way. The safe habit is both rules together: declare every status (`ELYSIA-TYPE-06`) and return expected errors (`ELYSIA-CORE-03`) — returning is also what checks the body against the schema.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-14` | A client **MUST** import the server's app type with `import type` — **NEVER** a value import, which bundles the server into the client. *(added 2026-10-25)* |

---

## 2. Eden Treaty: config and call shapes

```ts
import { treaty } from '@elysia/eden'
import type { App } from '@acme/server'            // ELYSIA-TYPE-14

export const api = treaty<App>('https://api.example.com', {
  parseDate: false,                                // ELYSIA-TYPE-10, § 4
  headers: () => {                                 // credentials once, for every call
    const token = session.token()
    return token ? { authorization: `Bearer ${token}` } : undefined
  }
})
```

### Config keys (`Treaty.Config`, eden 1.4.10 — verified)

| Key | What it does |
| --- | --- |
| `fetch` | a default `RequestInit` merged into every request (`credentials: 'include'` for cookie sessions) |
| `fetcher` | a replacement for `fetch`; ignored when an app instance is passed |
| `headers` | an object, a function `(path, init) => headers \| void` (may be async), or **an array mixing both**; per-call headers merge on top |
| `onRequest` | `(path, init) => Partial<RequestInit> \| void`; the return is merged into the request |
| `onResponse` | `(response) => unknown`; **any non-null return replaces `data` and skips the status check** — an observer must return `undefined` (`ELYSIA-TYPE-17`) |
| `keepDomain` | URL form: keep the URL exactly as given |
| `parseDate` | default **`true`**: any string that looks like a date becomes a `Date` |
| `throwHttpError` | `boolean \| (error: EdenFetchError) => boolean`; default `false`. The function receives the Eden error, not the `Response`. Also settable per call |

### Call shapes

| Route | Eden |
| --- | --- |
| `GET /orders` | `api.orders.get({ query: { page: 1, pageSize: 20 } })` |
| `GET /orders/:id` | `api.orders({ id: 9 }).get()` |
| `POST /orders` | `api.orders.post({ sku: 'A', quantity: 2 }, { headers, query, fetch })` |
| `GET /orders/:id/items` | `api.orders({ id: 9 }).items.get()` |

Methods with a body take `(body, options?)`; `GET`/`HEAD` take `(options?)`. Options are `{ query, headers, fetch, throwHttpError }`. A route from a sub-instance mounted with `.use()` appears under its prefix (`api.catalog.items.get()`).

A query key with a `default` is still **required** in the client's type (verified). Wrap it in `t.Optional(t.Number({ default: 20 }))` if callers may omit it — the server then types it `number | undefined` even though the default fills it at runtime.

---

## 3. The return value: a union you narrow by status

```ts
| { data: T,    error: null,                    response, status, headers }
| { data: null, error: { status: S, value: V }, response, status, headers }
```

What decides code (verified):

1. **`data` is `null` for any status >= 300 — redirects included.** A 302 is an `error`.
2. **The error type is a union by status**, with `value` typed by the `response` schema for that status. A route with **any** schema or a `:param` also gets `{ status: 422, value: { type: 'validation', … } }` in that union, even when it cannot fail validation — handle `case 422`.
3. **At runtime `error` is an `EdenFetchError`**: `instanceof Error` is true, and its `message` is `String(value)` — usually `"[object Object]"`. Narrow on `error.status`, read `error.value`; never branch on `instanceof` or show `error.message`.
4. **Without a response map** and without a returned `status()`, the error is `{ status: unknown; value: unknown }`.
5. **Eden does not throw** unless `throwHttpError` says so.

```ts
const { data, error } = await api.orders({ id }).get()
if (error) {
  switch (error.status) {
    case 401: return redirectToSignIn()
    case 404: return showNotFound(error.value.error)   // value typed by response[404]
    case 422: return showInvalid()
    default:  throw error
  }
}
render(data)                                          // narrowed: no null
```

`Treaty.Data<typeof api.orders.get>` and `Treaty.Error<…>` extract the two types for use elsewhere.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-08` | An Eden return value **MUST** have `error` checked before `data` is used — `data` is `null` for any status >= 300. |
| `ELYSIA-TYPE-15` | Code that handles an Eden error **MUST** narrow on `error.status` (with a `422` branch whenever the route has a schema or a path param) and read `error.value` — **NEVER** `instanceof` or `error.message`, which is `"[object Object]"`. *(added 2026-10-25)* |

---

## 4. The TanStack Query bridge

TanStack Query decides success or failure by whether the `queryFn` **throws**. Eden does not throw, so a `queryFn` that returns Eden's result ends in **`success`** on a 404 — `isError` false, no retry, no error boundary, and the component receives `{ data: null, error }` as if it were data (verified).

Unwrap once, at the boundary:

```ts
export async function unwrap<R extends { data: unknown; error: unknown }>(call: Promise<R>) {
  const { data, error } = await call
  if (error) throw error                 // ELYSIA-TYPE-09
  return data as Exclude<R['data'], null>
}

export const orderOptions = (id: number) =>
  queryOptions({
    queryKey: ['orders', 'detail', id] as const,
    queryFn: ({ signal }) => unwrap(api.orders({ id }).get({ fetch: { signal } })),
    retry: (failures, error: { status?: number }) => (error.status ?? 500) >= 500 && failures < 3,   // ELYSIA-TYPE-16
    staleTime: 60_000
  })
```

Once the error is thrown, Query **retries it — 4xx included** (verified: with `retry: 1`, a 404 ran twice). In a browser the default is three retries; under Bun, `@tanstack/query-core` sees a server (`isServer` is true) and defaults to **none** — so a test of the retry policy must set `retry` explicitly, or it passes for the wrong reason. A 404 or 401 does not get better on a second try, and the default three retries delay the error screen by seconds. Retry only 5xx.

**`parseDate: false`** (`ELYSIA-TYPE-10`). With the default, a value the type calls `string` arrives as a `Date`; a `Date` defeats Query's structural sharing (`replaceEqualDeep` keeps old references only for JSON values), so every refetch hands every consumer a new object and re-renders the list (verified end to end). Convert in `select` or in the component.

**Aborting and network failures.** The URL form honours `fetch: { signal }`, but an abort **resolves** with `error.status === 503` and `error.value.name === 'AbortError'`; a failed `fetch` (network down) resolves the same way, with `error.value` the `TypeError` — both reject only under `throwHttpError` (verified). That 503 is **not** in the route's typed error union, so the default branch of every `switch (error.status)` must handle it. The instance form `treaty(app)` ignores the signal.

**The alternative policy** is `throwHttpError: true` on the client, which makes every call reject with the `EdenFetchError`. Shorter, but every non-Query call site loses the typed `{ error }`. Pick one policy for the whole client.

**`queryKey` does not come from Eden.** The key is a domain decision (`['orders', 'detail', id]`, `['orders', 'list', { page }]`) and has to match what mutations invalidate.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-09` | A `queryFn`/`mutationFn` that calls Eden **MUST** throw on error (or the client **MUST** use `throwHttpError: true`) — without it the query stays `success` with null data. |
| `ELYSIA-TYPE-10` | An Eden client that feeds the TanStack Query cache **MUST** use `parseDate: false` — `Date` breaks structural sharing. |
| `ELYSIA-TYPE-16` | A query that throws Eden errors **MUST** limit `retry` to server errors (`error.status >= 500`) — thrown 4xx are retried by default. *(added 2026-10-25)* |
| `ELYSIA-TYPE-17` | An `onResponse` hook on the Treaty config that only observes **MUST** return `undefined` — any non-null return replaces `data` and skips error detection. *(added 2026-10-25)* |

---

## 5. A typed domain error reaching the form

The case that decides UI is the **mutation**: a 409 for stock or a 422 for validation has to become a message on the right field, not a generic toast. What reaches `useMutation`'s `error` is the same `EdenFetchError`, narrowed by `status`, with `value` typed by the server's `response` map (`ELYSIA-TYPE-06`).

```tsx
// server: response: { 201: 'Order', 409: t.Object({ error: t.Literal('out_of_stock'), sku: t.String() }) }

function OrderForm() {
  // TanStack types errors as Error by default: name the Eden union so `status` narrows `value`
  const create = useMutation<Treaty.Data<typeof api.orders.post>, Treaty.Error<typeof api.orders.post>, OrderInput>({
    mutationFn: (input) => unwrap(api.orders.post(input)),               // ELYSIA-TYPE-09
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['orders', 'list'] })
  })
  const stockError = create.error?.status === 409 ? create.error.value : undefined

  return (
    <form onSubmit={(e) => { e.preventDefault(); create.mutate(readForm(e)) }}>
      <input name="sku" aria-invalid={stockError !== undefined} />
      {stockError && <span role="alert">Out of stock for {stockError.sku}</span>}
      {create.error && create.error.status >= 500 && <span role="alert">Something went wrong. Try again.</span>}
      <button disabled={create.isPending}>Create</button>
    </form>
  )
}
```

`Treaty.Data` and `Treaty.Error` come from `import type { Treaty } from '@elysia/eden'` (verified with a `MutationObserver`: a 409 narrows `value` to `{ error, sku }`). An expected domain error gets its own message; anything else stays opaque by design.

---

## 6. The paginated envelope

Elysia does not prescribe a list format; this project does. The frontend disables "next" with `isPlaceholderData || !data?.hasMore` (`TSQ-PATTERN-05` in `TanStack Query - Padrões de Consulta`), so **`hasMore` must come from the server**. Inferring it as `items.length === pageSize` is wrong exactly when the total is a multiple of the page size.

```ts
// server
.get('/orders', ({ query: { page, pageSize } }) => {
  const { items, total } = repository.list({ page, pageSize })
  return { items, total, hasMore: page * pageSize < total }
}, {
  query: t.Object({ page: t.Number({ minimum: 1, default: 1 }), pageSize: t.Number({ minimum: 1, maximum: 100, default: 20 }) }),
  response: { 200: 'OrderPage' }          // t.Object({ items: t.Array(Order), total: t.Number(), hasMore: t.Boolean() })
})

// client
export const ordersOptions = (page: number) =>
  queryOptions({
    queryKey: ['orders', 'list', { page }] as const,
    queryFn: ({ signal }) => unwrap(api.orders.get({ query: { page, pageSize: 20 }, fetch: { signal } })),
    placeholderData: keepPreviousData
  })
```

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-13` | A paginated list route **MUST** declare in `response` an envelope with `items`, `total` and `hasMore` — returning the raw array makes `TSQ-PATTERN-05` unsatisfiable on the frontend. |

---

## 7. Tests

Two forms, two purposes (verified):

```ts
// 1. A server-side test, typed end to end: the instance, no network.
const local = treaty(app, { headers: { authorization: 'Bearer test-token' } })
expect((await local.orders({ id: 1 }).get()).status).toBe(200)

// 2. The production client config under test: the URL form, routed through app.handle.
const api = createApi('http://localhost', () => 'test-token',
  ((input: RequestInfo | URL, init?: RequestInit) => app.handle(new Request(input, init))) as typeof fetch)
```

Use an origin of at least eleven characters (`http://localhost`): Elysia slices the path from index 11, and `http://x/orders` answers 404 for every route. Await `app.modules` first when the app has lazy or async plugins. The instance form ignores `fetch.signal`; test aborting with the URL form.

---

## 8. Files, streams and WebSocket

- **Files:** when any top-level body value is a `File` or `Blob`, Eden sends `multipart/form-data` (verified: `api.upload.post({ file: new File(['hello'], 'a.txt') })` arrives as `body.file`).
- **Streams:** a generator or `sse()` route gives `data` as an `AsyncGenerator`; iterate with `for await`. Plain generator chunks arrive parsed; `sse()` chunks arrive as `{ event, data }` with `data` parsed. `parseDate` applies to chunks too.
- **WebSocket:** a `.ws()` route is `api.chat.subscribe()`, an `EdenWS` that extends `WebSocket` (`.raw` is the native socket); `body`/`response` schemas type the messages.

```ts
const chat = api.chat.subscribe()
chat.subscribe((m) => console.log('received', m.data))
chat.on('open', () => chat.send('hello'))
```

---

## 9. Eden Fetch

```ts
import { edenFetch } from '@elysia/eden'
const fetchApi = edenFetch<App>('https://api.example.com')
const { data, error, retry } = await fetchApi('/orders/:id', { params: { id: '9' } })
```

Not the same shape as Treaty (verified): it takes a **URL only** (route it in-process with `fetcher`), returns `{ data, error, status, headers, retry }` with **no `response`**, and types `error` as `EdenFetchError<Status, Value>`. The docs' reason to prefer it is compiler performance above ~500 routes in one frontend; it is no longer faster at runtime. `edenTreaty` (lowercase, Treaty 1) is legacy and still compiles — use `treaty`.

---

## 10. When Eden returns `any` (or loses a route)

| Symptom | Cause | Check |
| --- | --- | --- |
| every route is `any` | `strict` off, or TypeScript < 5.0, on either side | both `tsconfig.json` (`ELYSIA-APP-04`) |
| `any` after an upgrade on one side | two `elysia` versions resolved | `bun pm ls --all \| grep elysia@` or `npm why elysia` — one version (`ELYSIA-TYPE-11`) |
| one route missing, the rest fine | registered in a separate statement | the server chain (`ELYSIA-APP-01`) |
| everything degrades in a monorepo only | a path alias that resolves to a **different file** on each side | the `paths` mapping and the package `exports` the client resolves |
| an error status missing from the union | not in the `response` map **and** thrown rather than returned | `ELYSIA-TYPE-06`, `ELYSIA-CORE-03` |
| `value` of an error is `unknown` | no `response` map for that route | `ELYSIA-TYPE-06` |

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-11` | Client and server **MUST** resolve the same `elysia` version, with `strict: true` and TypeScript >= 5.0 on both. |

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `queryFn: () => api.orders.get()` | returns the result and never throws: a 404 is a `success` | `unwrap` and throw — `ELYSIA-TYPE-09` |
| `if (error instanceof Error) toast(error.message)` | it is always an `Error`, and the message is `"[object Object]"` | `switch (error.status)`, read `error.value` — `ELYSIA-TYPE-15` |
| a `switch (error.status)` with no `case 422` | the default branch silently swallows validation failures | add the branch — `ELYSIA-TYPE-15` |
| default `retry` on a query that throws Eden errors | a 404 or 401 is retried three times; the error screen comes late | `retry: (n, e) => e.status >= 500 && n < 3` — `ELYSIA-TYPE-16` |
| default `parseDate` feeding the Query cache | `Date` defeats structural sharing; every refetch re-renders; the type still says `string` | `parseDate: false` — `ELYSIA-TYPE-10` |
| an `onResponse` that logs and returns the response | the response becomes `data`; errors are no longer detected | return `undefined` — `ELYSIA-TYPE-17` |
| `import { App } from '@acme/server'` | the server is bundled into the client | `import type` — `ELYSIA-TYPE-14` |
| `data!` without checking `error` | `data` is `null` on any status >= 300, redirects included | check `error` first — `ELYSIA-TYPE-08` |
| two `elysia` versions in the workspace | the client degrades to `any` without an error | one version, checked — `ELYSIA-TYPE-11` |
| a paginated route answering a bare array | the frontend cannot know whether there is a next page | `{ items, total, hasMore }` — `ELYSIA-TYPE-13` |
| `edenTreaty(...)` in new code | Treaty 1, legacy | `treaty` |

## Review checklist

- [ ] The client imports `type App`, never the value? → `ELYSIA-TYPE-14`
- [ ] Every direct call checks `error` before `data`? → `ELYSIA-TYPE-08`
- [ ] Error handling narrows on `error.status`, with a `422` branch? → `ELYSIA-TYPE-15`
- [ ] Every `queryFn`/`mutationFn` throws (or the client sets `throwHttpError`)? → `ELYSIA-TYPE-09`
- [ ] Queries that throw retry only 5xx? → `ELYSIA-TYPE-16`
- [ ] The client feeding the cache uses `parseDate: false`? → `ELYSIA-TYPE-10`
- [ ] `onResponse` observers return `undefined`? → `ELYSIA-TYPE-17`
- [ ] One `elysia` version, `strict: true` and TS >= 5.0 on both sides? → `ELYSIA-TYPE-11`, `ELYSIA-APP-04`
- [ ] Paginated lists return `{ items, total, hasMore }`? → `ELYSIA-TYPE-13`
- [ ] Tests use `treaty(app)` or a `fetcher` over `app.handle`, with `http://localhost`?
