---
title: Elysia - Routing and Handler
link: https://elysiajs.com/essential/handler.html
tags:
  - elysia
  - http
  - agent-context
source: "Official documentation — https://elysiajs.com/ — behaviour re-executed on elysia 1.4.30 on 2026-10-25"
verified-at: 2026-10-25
---

# Elysia - Routing and Handler

## Contents

- [0. Decision tree — how do I return an error?](#0-decision-tree--how-do-i-return-an-error)
- [1. Concept: the context is an accumulation of earlier decisions, not a fixed object](#1-concept-the-context-is-an-accumulation-of-earlier-decisions-not-a-fixed-object)
- [2. Instance, routes and path precedence](#2-instance-routes-and-path-precedence)
- [3. The context object](#3-the-context-object)
- [4. Response shapes](#4-response-shapes)
- [5. Errors: taxonomy, return × exception, and customization](#5-errors-taxonomy-return--exception-and-customization)
- [6. Testing without starting a server](#6-testing-without-starting-a-server)
- [Anti-patterns](#anti-patterns)
- [Review checklist](#review-checklist)

> Instance and `listen` · verbs, path params, wildcard and precedence · `group` · the context object · response shapes and coercion · `status` and `set` · reactive cookie · redirect, file, stream and SSE · `onError` and the code taxonomy · testing without starting a server.
>
> **Does not cover:** scope, hooks and plugins ([Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md)) · schema and validation ([Elysia - Schema and Validation](elysia-schema-and-validation.md)) · Eden ([Elysia - Eden](elysia-eden.md)) · the HTTP server underneath (`Bun - HTTP e Servidor`).

Entry: [Elysia](elysia.md) · Normative basis: [Elysia](elysia.md) § 6

---

## 0. Decision tree — how do I return an error?

```
Is it an EXPECTED domain error (business validation, 404, 401, 409)?
│
├── and I want the error TYPE to reach the frontend through Eden
│   → return status(code, value)      + declare `response: { 200: …, 4xx: … }`
│     ⚠ RETURNING does not go through onError. It is the path the docs recommend.
├── and I want the central onError to format/log it
│   → throw status(code, value)       ⚠ THROW goes through onError
└── and it is a recurring condition with its own body
    → class MyError extends Error { status = 409; toResponse() {…} }
      + .error({ MY_ERROR: MyError })  → onError narrows by code === 'MY_ERROR'

Is it an UNEXPECTED error (bug, unavailability)?
  → let it blow up. It becomes UNKNOWN / 500 and lands in onError.
    Log it there and return a generic message.

Is it a VALIDATION error and I want to customize the message?
  → t.String({ error: 'message' })      per field
  → onError with code === 'VALIDATION'  central; error.all lists every cause
    ⚠ under NODE_ENV=production the detail is omitted by default
```

> **Returning × throwing** is a real, cited distinction: *"If a `status` is **throw**, it will be caught by `onError` middleware. If a `status` is **return**, it will be **NOT** caught"*. The docs recommend the **never-throw** approach (returning) because only it gives checking against the `response` schema, narrowing by status and error typing in Eden.

---

## 1. Concept: the context is an accumulation of earlier decisions, not a fixed object

The handler receives a single object. The temptation is to treat it as an Express `req`/`res` under other names — and that is where the mental model goes wrong.

The Elysia context has a fixed part (`body`, `query`, `params`, `headers`, `cookie`, `set`, `store`, `request`, `path`, `route`, `status`, `redirect`, `server`) and a part **that was put there** by `decorate`, `derive`, `resolve` and macros registered before this route. The type of `params.id` is `string` or `number` depending on whether there is a schema. The type of `body` is `unknown` without a schema and exact with one. If a plugin with `resolve` is in the chain, `ctx.user` exists; if its scope is `local` and the route is on the parent instance, it does not — and TypeScript warns you.

This has a direct practical consequence: **destructuring in the parameter is the canonical form**, not syntactic sugar. `({ params: { id }, status }) => ...` documents exactly what the route consumes, and it is what the docs use in every example. It is also what the docs recommend when delegating to a service layer: *"it's recommended to destructure properties from inline function to prevent unnecessary type inference"* — passing the whole `Context` to a controller class is explicitly discouraged, because the type is too dynamic to be annotated by hand.

```ts
import { Elysia, t } from 'elysia'

new Elysia()
  .get('/orders/:id', ({ params: { id }, status }) => {
    const order = orders.find(id)          // id is a number: the schema coerced it
    if (!order) return status(404, { error: 'Order not found' })
    return order
  }, {
    params: t.Object({ id: t.Numeric() })
  })
  .listen(3000)
```

| ID | Rule |
| --- | --- |
| `ELYSIA-CORE-02` | The handler **MUST** destructure the context properties it uses — **NEVER** receive the whole `Context` object and pass it on to another layer. |

---

## 2. Instance, routes and path precedence

`new Elysia()` creates the instance; `.listen(port)` starts the server. Every route takes three arguments: path, handler, and an optional metadata object (schema + local hooks).

```ts
new Elysia({ prefix: '/v1' })
  .get('/status', 'ok')                       // literal value, no function
  .post('/orders', ({ body }) => create(body))
  .all('/webhook', ({ request }) => accept(request))
  .route('M-SEARCH', '/discover', 'ok')       // custom verb, UPPERCASE
  .listen(3000)
```

A literal value in place of the function is a real optimization: the docs explain that it lets the response be compiled ahead of time, and with `nativeStaticResponse` on Bun it becomes `Bun.serve.static`. **It does not work on Cloudflare Worker** (a `Response` cannot be built before start).

### Path types

| Form | Syntax | `params` |
| --- | --- | --- |
| static | `/orders` | — |
| dynamic | `/orders/:id` | `params.id` |
| multiple | `/stores/:store/orders/:id` | `params.store`, `params.id` |
| optional | `/orders/:id?` | `params.id` may be missing |
| wildcard | `/files/*` | `params['*']` |

**Precedence, verified:** static → dynamic → wildcard.

In a prefixed instance, register the collection routes as `''`, never mixing `''` and `'/'`. Verified on 1.4.30: `new Elysia({ prefix: '/orders' }).get('', …).post('/', …)` makes the `POST` answer **404** at both `/orders` and `/orders/`; `.post('/')` alone answers both, and is documented in OpenAPI as `/orders/`. `/id/1` beats `/id/:id`, which beats `/id/*`.

Two behavioral traps the official table makes explicit:

- `/orders/:id` does **not** match `/orders` (it is Not Found) nor `/orders/1/items`.
- A trailing slash is tolerated by default. `strictPath: false` (the default) makes `/name` and `/name/` resolve the same; `strictPath: true` follows RFC 3986 and keeps them apart.

Without a `params` schema, every path param is a `string`. With `t.Number()` in the route schema, Elysia converts it to `t.Numeric()` and coerces — details in [Elysia - Schema and Validation](elysia-schema-and-validation.md).

### `group` and `guard`

`group` applies a prefix. It accepts an optional guard as the second argument, which avoids nesting `group` inside `guard`:

```ts
new Elysia()
  .group('/users', (app) => app
    .post('/sign-in', ({ body }) => signIn(body))
    .post('/sign-up', ({ body }) => signUp(body))
  )
  // with a guard as the 2nd argument: schema applied to both routes at once
  .group('/admin', { headers: t.Object({ authorization: t.String() }) }, (app) => app
    .get('/metrics', () => metrics())
    .delete('/cache', () => clearCache())
  )
```

The alternative without nesting is `new Elysia({ prefix: '/users' })` as a separate instance, applied with `.use()`. That is what the docs' feature-based organization recommends: one instance per module, each with its own prefix. Careful: a separate instance brings **scope** semantics along with it — see [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 5.

| ID | Rule |
| --- | --- |
| `ELYSIA-CORE-01` | Hook, plugin and `onError` **MUST** be registered before the routes they should affect — an event only applies to routes registered after it. |

---

## 3. The context object

List verified in `context.d.ts` of 1.4.29.

| Property | What it is | Note |
| --- | --- | --- |
| `body` | parsed body | `unknown` without a schema. Ignored on GET/HEAD by default (RFC 2616) |
| `query` | query string | `Record<string, string>` without a schema |
| `params` | path params | `string` without a schema |
| `headers` | request headers | **always lowercase** |
| `cookie` | reactive cookie jar | it is a Proxy: never `undefined`, only `.value` can be |
| `set` | the response's `{ headers, status }` | `set.redirect` is deprecated |
| `store` | the instance's global state | created by `.state()` |
| `status` | response function with typed status | replaces the old `error` |
| `redirect` | redirect function | also exported by `elysia` |
| `request` | Web Standard `Request` | escape hatch for anything not in the context |
| `server` | server instance | **Bun only**, `null` outside it and before `listen` |
| `path` | URL path | e.g. `/orders/9` |
| `route` | path **registered** in the router | e.g. `/orders/:id` — useful for metrics and logs |
| — | `decorate`, `derive`, `resolve` | everything earlier plugins and hooks added |

`route` is the property almost nobody knows about, and it solves a real problem: grouping metrics and logs by route instead of by concrete URL, without cardinality blowing up.

`onRequest` receives a reduced `PreContext` — only `request`, `set`, `store`, `status`, `redirect`, `server` and decorators. It has no `body`, `query`, `params`, `headers`, `cookie`, `path`, `route` nor anything from `derive`/`resolve`, because it runs before any of that exists. `status` is there, and that is what allows a typed short-circuit: `return status(429, { error: 'Rate limit exceeded' })`. Canonical enumeration and the list of what is left out in [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 2.

---

## 4. Response shapes

The value the handler returns is converted automatically. In most cases there is no need to serialize or set `Content-Type`.

```ts
import { Elysia, file, form, sse } from 'elysia'

new Elysia()
  .get('/text', () => 'ok')                          // text/plain
  .get('/json', () => ({ id: 1, name: 'Ana' }))      // application/json
  .get('/file', file('public/manual.pdf'))           // file
  .get('/bundle', () => form({                       // FormData
    title: 'Report',
    attachments: [file('a.pdf'), file('b.pdf')]
  }))
  .get('/raw', () => new Response('...', { status: 202 }))  // Response passes straight through
```

### Status and headers

Two APIs, and the choice between them matters:

```ts
new Elysia()
  .get('/a', ({ status }) => status(418, "I'm a teapot"))  // typed, checked against the response schema
  .get('/b', ({ set }) => {
    set.status = 418                                        // NOT checked against the schema
    set.headers['x-powered-by'] = 'Elysia'
    return "I'm a teapot"
  })
```

The docs are explicit about the difference: *"Unlike the `status` function, `set.status` cannot infer the return value type, therefore it can't check if the return value is correctly typed to the response schema"*. `set.status` is for the case where a plugin wants to set a default status and let the user return the value. For everything else, `status`.

`status` accepts a number or the status name (`status("I'm a teapot")`), with autocomplete. Response headers go in `set.headers`, always lowercase (`set-cookie`, not `Set-Cookie`) — `headers` without `set.` is the **request**.

### Reactive cookie

The cookie jar is a Proxy. There is no `getCookie`/`setCookie`: you read and write `.value` and the header is kept in sync.

`ELYSIA-CORE-05` is conjunctive: **signed and `httpOnly`**. `httpOnly` alone stops client JavaScript from *reading* the cookie, but does not stop anyone from *forging* one. That is why the canonical session block declares both, and the signing lives in the constructor:

```ts
import { Elysia, env } from 'elysia'      // `env`, not `process.env` — ELYSIA-APP-09

new Elysia({
  cookie: {
    secrets: [env.COOKIE_SECRET_CURRENT!, env.COOKIE_SECRET_PREVIOUS!],
    sign: ['session']           // signs with the first key, verifies with all of them
  }
})
  .get('/sign-in', ({ cookie: { session } }) => {
    session.value = { userId: 42 }            // object: automatic encode/decode
    session.httpOnly = true                   // the two halves of ELYSIA-CORE-05:
    session.secure = true                     // `sign` above + `httpOnly` here
    session.sameSite = 'lax'
    session.maxAge = 7 * 86400
    return 'ok'
  })
  .get('/sign-out', ({ cookie: { session } }) => {
    session.remove()                           // or: delete cookie.session
    return 'ok'
  })
```

The same pair can be declared at once in the route schema, with `t.Cookie(props, { secrets, sign, httpOnly, secure })` — this is the form that also documents the cookie in OpenAPI. See [Elysia - Schema and Validation](elysia-schema-and-validation.md).

`set({...})` resets every cookie property and applies the new ones; `add({...})` overwrites only the ones given.

Putting `null` in the `secrets` array lets unsigned cookies through — the docs present it as a gradual transition and say to use it only during the migration. Secrets come from initialization, not from the code.

> **Type warning:** TypeScript may flag `cookie.name` as possibly `undefined`. The docs clarify: *"Elysia cookie can never be `undefined` because it's a Proxy object"* — only `.value` can be. Declaring a `t.Cookie` schema fixes it.

### Redirect

```ts
new Elysia()
  .get('/old', ({ redirect }) => redirect('/new'))
  .get('/external', ({ redirect }) => redirect('https://example.com', 302))
```

Any value returned after `redirect` is ignored. `set.redirect` still exists, but it is marked `@deprecated` in the types.

### Stream and SSE

A `function*` handler becomes streaming. Wrapping the value in `sse()` turns on `text/event-stream` and the event format.

```ts
import { Elysia, sse } from 'elysia'

new Elysia()
  .get('/progress', function* ({ set }) {
    set.headers['x-job'] = 'import'       // headers only count BEFORE the first yield
    for (const step of steps) {
      yield sse({ event: 'progress', data: { step: step.name, pct: step.pct } })
    }
    yield sse({ event: 'done' })
  })
  .get('/maybe', function* () {
    if (cacheIsWarm) return fullResponse   // no yield: becomes a normal response
    yield* chunks()
  })
```

Three verified behaviors that change code:

1. **Headers after the first `yield` do nothing.** Once the first chunk is sent, the headers are gone.
2. **Returning without `yield` converts to a normal response**, which lets you decide between a stream and a single response at runtime.
3. **Cancellation is automatic**: if the client aborts, Elysia stops the generator.

On the client, Eden interprets the stream as an `AsyncGenerator` — `for await (const chunk of data)`.

| ID | Rule |
| --- | --- |
| `ELYSIA-CORE-04` | `status(code, value)` **MUST** be used instead of `set.status` whenever the route declares a `response` schema — only it is checked against the schema. |
| `ELYSIA-CORE-05` | A session cookie **MUST** be signed (`secrets` + `sign`) and marked `httpOnly`. |
| `ELYSIA-CORE-06` | `set.headers` is **NEVER** changed after the first `yield` of a generator handler — the change is silently ignored. |

---

## 5. Errors: taxonomy, return × exception, and customization

> The decision tree for choosing between these paths is in § 0; this section explains the same rules in prose.

Elysia catches whatever blows up in any phase, classifies it and hands it to `onError` with a `code` that narrows the type of `error`.

**Built-in codes, verified:** `NOT_FOUND`, `PARSE`, `VALIDATION`, `INTERNAL_SERVER_ERROR`, `INVALID_COOKIE_SIGNATURE`, `INVALID_FILE_TYPE`, `UNKNOWN`, **or an HTTP status number**. An unknown error falls into `UNKNOWN` with status 500.

Each built-in class carries a default status, and that is what goes out **with no `onError` at all**. Extracted from `error.js` of `elysia@1.4.29`:

| Code | Class | Default status |
| --- | --- | --- |
| `VALIDATION` | `ValidationError` | **422** |
| `INVALID_FILE_TYPE` | `InvalidFileType` | 422 |
| `NOT_FOUND` | `NotFoundError` | 404 |
| `PARSE` | `ParseError` | 400 |
| `INVALID_COOKIE_SIGNATURE` | `InvalidCookieSignature` | 400 |
| `INTERNAL_SERVER_ERROR` / `UNKNOWN` | `InternalServerError` | 500 |

The validation **422** is the number that surprises the most, because the reflex of anyone coming from other frameworks is 400. It is the status of `ValidationError` in the package, not a choice made by the `onError` in the example below — an app with no `onError` already answers 422 to an invalid payload, and that is why the test in § 6 can assert it. An `onError` that returns 400 for `code === 'VALIDATION'` is **changing** the default, not formalizing it; if the API contract promises 400, that must be declared in the `response` schema and in OpenAPI, otherwise the documentation lies.

```ts
import { Elysia } from 'elysia'

new Elysia()
  .onError(({ code, error, status, route, path }) => {
    switch (code) {
      case 'NOT_FOUND':
        return status(404, { error: 'Resource not found' })
      case 'VALIDATION':
        // error is a ValidationError; error.all lists every cause
        return status(422, { error: 'Invalid payload', causes: error.all })
      default:
        // unexpected: log with context and return a generic message
        logger.error({ code, route, path, err: error })
        return status(500, { error: 'Internal error' })
    }
  })
  .get('/orders/:id', /* ... */)
```

The `switch` above follows the pattern: expected becomes a meaningful response, unexpected becomes an opaque 500 **with a log**. Do not return `error.message` of an unknown error to the client.

Three behaviours verified on 1.4.30 that change how this handler is written:

1. **With no `onError` at all, a thrown `Error`'s message is the 500 body — also under `NODE_ENV=production`.** `throw new Error('db password is hunter2')` answers `db password is hunter2`. `ELYSIA-CORE-07` is therefore not only about what an `onError` returns: an app that throws needs one.
2. **Hooks run in registration order across instances.** An app-level `onError` registered before `.use(module)` runs **before** the module's own `onError`. A catch-all whose `default` branch answers every code (like the one above) swallows the codes the module registered with `.error()`. At the app level, answer only `UNKNOWN` and `INTERNAL_SERVER_ERROR` and return nothing for the rest.
3. **A thrown `status(404, …)` reaches `onError` as `code === 404`** — the number, not `'NOT_FOUND'`. A switch on string codes misses it.

### The distinction that confuses: `return status` × `throw status`

Literal quote from the source, because a paraphrase loses it:

> "If a `status` is **throw**, it will be caught by `onError` middleware. If a `status` is **return**, it will be **NOT** caught by `onError` middleware."

This is not an implementation detail — it is an architectural choice:

| | `return status(...)` | `throw status(...)` |
| --- | --- | --- |
| Goes through `onError` | no | yes |
| Checked against the `response` schema | yes | no |
| Type reaches Eden with narrowing by status | yes | only if the `response` map declares that status (verified on 1.4.30) |
| Use when | the error is part of the API contract | the error crosses layers and a central handler formats it |

The docs recommend the **never-throw** approach for the normal case, and list the three reasons: checking against the schema, autocomplete by status, and error narrowing in Eden.

There is one legitimate case for `throw`: a service layer, far from the handler, that needs to abort. The docs themselves do this in the Best Practice example — `throw status(400, '...')` inside an `Auth.signIn` that knows nothing about the Elysia context.

### Custom errors

```ts
class InsufficientStock extends Error {
  status = 409
  constructor(public sku: string) { super(`Out of stock for ${sku}`) }
  toResponse() { return Response.json({ error: 'stock', sku: this.sku }, { status: 409 }) }
}

new Elysia()
  .error({ STOCK: InsufficientStock })         // registers the code
  .onError(({ code, error, status }) => {
    if (code === 'STOCK') return status(409, { sku: error.sku })  // error is typed
  })
  .post('/cart', ({ body }) => add(body))
```

`status` on the class sets the default status — verified to work even without registering the class in `.error()`; `toResponse()` defines the whole response, and its status wins over the property. Registering it in `.error()` is what gives narrowing by `code` in `onError`.

### Validation message

Per field, with `error` in the schema; or centrally, narrowing on `code === 'VALIDATION'`. Verified on 1.4.30: with a per-field `error` string and no central handler, the 422 body **is that bare string**, sent as `application/json` but not valid JSON — a client's `res.json()` throws. Use a central `VALIDATION` handler that answers JSON (pattern in [Elysia - Schema and Validation](elysia-schema-and-validation.md) § 5). Details in [Elysia - Schema and Validation](elysia-schema-and-validation.md). One behavior to know right now: **under `NODE_ENV=production` validation details are omitted by default** — the response says it failed, without revealing field names and expected types. `allowUnsafeValidationDetails: true` in the constructor reverts this, and the docs warn that it leaks the shape of the schema.

| ID | Rule |
| --- | --- |
| `ELYSIA-CORE-03` | An expected error **MUST** be `return status(...)`, not `throw`, when the type needs to reach Eden typed. |
| `ELYSIA-CORE-07` | `onError` **NEVER** returns `error.message` of an `UNKNOWN` error to the client — log the detail and respond generically. |
| `ELYSIA-CORE-08` | A recurring domain error **MUST** be registered in `.error({...})` to get its own `code` and narrowing in `onError`. |

---

## 6. Testing without starting a server

`app.fetch(request)` and `app.handle(request)` process a Web Standard `Request` and return a `Response` — no port, no network. The docs insist that it is **not a mock**: *"you can expect it to behave like an actual request sent to the server"*, with the full lifecycle.

```ts
import { describe, it, expect } from 'bun:test'
import { Elysia, t } from 'elysia'

const app = new Elysia()
  .post('/orders', ({ body, status }) => status(201, { id: 1, ...body }), {
    body: t.Object({ sku: t.String(), quantity: t.Number() })
  })

describe('POST /orders', () => {
  it('creates and returns 201', async () => {
    const res = await app.fetch(new Request('http://localhost/orders', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ sku: 'ABC', quantity: 2 })
    }))

    expect(res.status).toBe(201)
    expect(await res.json()).toEqual({ id: 1, sku: 'ABC', quantity: 2 })
  })

  it('rejects an invalid payload', async () => {
    const res = await app.fetch(new Request('http://localhost/orders', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ sku: 'ABC' })         // quantity is missing
    }))

    // 422 is the default status of ValidationError — this app has no onError. See § 5.
    expect(res.status).toBe(422)
  })
})
```

If the app uses an async plugin or a lazy `import()`, wait for `await app.modules` before the **first request** — deferred modules register after start. Verified: a lazy `import()` recovers once awaited, but an async plugin *function* that was still pending when a request arrived keeps that route **404 for good**, even after `await app.modules` and although it is listed in `app.routes`.

Use an origin of at least eleven characters in test requests — `http://localhost/orders`. Elysia slices the path from index 11, so `http://x/orders` answers 404 for every route and looks like a missing route.

The same function is what makes Elysia embeddable: `app.fetch(request)` is literally what the Next.js, Astro, Expo, Vercel and TanStack Start guides use to mount Elysia in an API route.

For tests with end-to-end types, `treaty(app)` takes the instance directly and makes no network request — see [Elysia - Eden](elysia-eden.md).

| ID | Rule |
| --- | --- |
| `ELYSIA-CORE-09` | A route test **MUST** use `app.fetch`/`app.handle` — **NEVER** start a server and request over the network. |
| `ELYSIA-CORE-10` | An app with an async plugin or a lazy `import()` **MUST** await `app.modules` before the assertions. |

---

## Anti-patterns

| Anti-pattern | Why it fails | What to do |
| --- | --- | --- |
| `onError` at the end of the chain | an event only applies to routes registered after it; the routes above are left unhandled and nobody notices until production | register `onError` before any route — `ELYSIA-CORE-01` |
| `return status(404)` expecting it to land in `onError` | a return does not go through `onError`; the central formatting handler never runs | `throw status(404)` if `onError` should format it; `return` if the contract belongs to the route — `ELYSIA-CORE-03` |
| `set.status = 422` with a `response` schema declared | it is not checked against the schema, and Eden does not narrow the error type | `status(422, value)` — `ELYSIA-CORE-04` |
| Controller class receiving the whole `Context` | `Context` is dynamic and depends on plugins; annotating it by hand loses type integrity, and the docs themselves discourage it | destructure in the inline handler and pass primitive values to the service — `ELYSIA-CORE-02` |
| `set.headers[...]` inside a generator's loop | after the first `yield` the headers have already been sent; the assignment is silently ignored | set every header before the first `yield` — `ELYSIA-CORE-06` |
| Returning `error.message` in the `default` branch of `onError` | the message of an unknown error leaks stack, SQL query, file path | log the detail, respond with a generic message — `ELYSIA-CORE-07` |
| Starting the server with `listen` inside the test | port in use, slow test, flakiness in parallel — and it is unnecessary | `app.fetch(new Request(...))` — `ELYSIA-CORE-09` |
| Uppercase `Cookie`/`Set-Cookie` in `set.headers` | Elysia normalizes headers to lowercase; the uppercase key may be duplicated | use `set-cookie`, or better, the context's cookie API |
| Session cookie without `httpOnly` or signing | readable and forgeable by JavaScript on the client | `t.Cookie` with `secrets` + `sign` + `httpOnly` — `ELYSIA-CORE-05` |

---

## Review checklist

- [ ] Does every `onError`, `guard` and `.use()` appear before the routes it should affect? → `ELYSIA-CORE-01`
- [ ] Does no handler receive the whole `Context` to pass it on? → `ELYSIA-CORE-02`
- [ ] Is `return` × `throw` of `status` consistent with who should format the error? → `ELYSIA-CORE-03`
- [ ] Where there is a `response` schema, does the status go out through `status()` and not `set.status`? → `ELYSIA-CORE-04`
- [ ] Do session cookies have `sign` + `httpOnly`, with the secret coming from the environment? → `ELYSIA-CORE-05`
- [ ] Do generator handlers set headers before the first `yield`? → `ELYSIA-CORE-06`
- [ ] Does the `default` branch of `onError` log the detail and return a generic message? → `ELYSIA-CORE-07`
- [ ] Are recurring domain errors registered in `.error({...})`? → `ELYSIA-CORE-08`
- [ ] Do tests use `app.fetch` without starting a server? → `ELYSIA-CORE-09`
- [ ] Is there an `await app.modules` wherever an async plugin exists? → `ELYSIA-CORE-10`
