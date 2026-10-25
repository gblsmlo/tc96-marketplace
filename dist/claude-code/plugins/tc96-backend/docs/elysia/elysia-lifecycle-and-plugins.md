---
title: Elysia - Lifecycle and Plugins
link: https://elysiajs.com/essential/plugin.html
tags:
  - elysia
  - plugins
  - agent-context
source: "Official documentation — https://elysiajs.com/ — behaviour re-executed on elysia 1.4.30 on 2026-10-25"
verified-at: 2026-10-25
---

# Elysia - Lifecycle and Plugins

## Contents

- [0. Decision trees](#0-decision-trees)
- [1. Concept: scope is the only thing that decides whether a plugin affects a route — and the default is the most restrictive](#1-concept-scope-is-the-only-thing-that-decides-whether-a-plugin-affects-a-route--and-the-default-is-the-most-restrictive)
- [2. The lifecycle order](#2-the-lifecycle-order)
- [3. state × decorate × derive × resolve](#3-state--decorate--derive--resolve)
- [4. A plugin is an instance, and use() is the only way to compose](#4-a-plugin-is-an-instance-and-use-is-the-only-way-to-compose)
- [5. Scope: local, scoped, global and the as() method](#5-scope-local-scoped-global-and-the-as-method)
- [6. macro: reusable hook, activated declaratively](#6-macro-reusable-hook-activated-declaratively)
- [7. guard: schema and hooks for several routes](#7-guard-schema-and-hooks-for-several-routes)
- [8. Official plugins in production](#8-official-plugins-in-production)
- [Anti-patterns](#anti-patterns)
- [Review checklist](#review-checklist)

> The full lifecycle order and what each hook can do · `state` × `decorate` × `derive` × `resolve` · `macro` · plugin as an instance and `use()` · deduplication by `name`/`seed` · **`local`/`scoped`/`global` scope and `as()`** · `guard` · official production plugins.
>
> **Does not cover:** routes, context and responses ([Elysia - Routing and Handler](elysia-routing-and-handler.md)) · schema ([Elysia - Schema and Validation](elysia-schema-and-validation.md)) and Eden ([Elysia - Eden](elysia-eden.md)) · the runtime underneath (`Bun - Runtime e APIs`).

Entry: [Elysia](elysia.md) · Normative basis: [Elysia](elysia.md) § 6

---

## 0. Decision trees

### 0.1 Which hook gets a value into the handler?

This is the decision that produces the most wrong code in Elysia, because the four APIs look alike and two of them differ **only in the lifecycle phase**.

```
Does the value depend on the request (headers, body, query, cookie)?
├── NO — it is constant for the life of the process
│   └── Is it a primitive that someone will MUTATE (counter, flag)?
│       ├── YES → .state('k', v)   → read at ctx.store.k
│       │         ⚠ destructuring a primitive from the store loses the reference
│       └── NO → .decorate('k', v)  → read at ctx.k
│                 (class, singleton, database connection, logger)
│                 ⚠ decorate must NOT be mutated
│
└── YES — it has to be computed on every request
    └── Does the value depend on data that MUST be validated?
        ├── YES → .resolve(fn)     runs in beforeHandle, AFTER validation
        │         → this is the auth case: session, userId, permissions
        │         → the type of what you read is the schema's type
        └── NO → .derive(fn)      runs in transform, BEFORE validation
                  → what you read is `unknown`-ish: it has not gone through a schema yet
                  → use it for things that do not decide security (requestId, IP, timing)
```

> The docs are explicit about the default: *"You might want to use resolve instead of derive in most cases. Resolve is similar to derive but execute after validation. This makes resolve more secure"*. Rule of thumb: **if the value decides access, it is `resolve`**. Full table in § 3.

### 0.2 Where in the lifecycle does this logic go?

```
I need to reject/respond BEFORE any parsing (rate limit, IP block, cache)
  → onRequest        PreContext: request, set, store, status, redirect, server
                     and decorators — and nothing else. It is GLOBAL, it ignores
                     route order. `status(...)` is there: typed short-circuit.

The content-type is not json/text/form-data/urlencoded
  → onParse          return the body; or `parse: 'none'` to skip parsing
                     (needed when handing the raw Request to another lib)

I need to change the data so it PASSES validation (manual coercion)
  → onTransform / derive

I need to decide whether the request goes on (authentication, authorization)
  → onBeforeHandle / resolve      return != undefined skips the handler

I need to transform the return value (header by type, envelope)
  → onAfterHandle    reads ctx.responseValue
                     ⚠ returning here does NOT skip the following afterHandle

I need to produce a Web Standard Response (gzip, binary format)
  → mapResponse      returning here SKIPS the following mapResponse

Something failed
  → onError          code: NOT_FOUND | PARSE | VALIDATION |
                     INTERNAL_SERVER_ERROR | INVALID_COOKIE_SIGNATURE |
                     INVALID_FILE_TYPE | UNKNOWN | <status number>

I already responded, I want to record it
  → onAfterResponse  logging and analytics
```

### 0.3 Why does my plugin not affect this route?

The tree that solves Elysia's most common class of bug.

```
Is the route registered AFTER the hook/plugin in the chain?
├── NO → that's it. An event only applies to routes registered after it.
│         Move the .use()/.onX() up. (exception: onRequest is global)
└── YES
    └── Is the hook in an instance the route does NOT belong to?
        ├── NO (same instance) → it should work; check the name/typo
        └── YES → it is scope. The default is `local`: it does not go up to the parent.

            Who needs to be affected?
            ├── only this instance and its children → local (default, do nothing)
            ├── + the instance that called .use()  → scoped
            └── all of them, at any level           → global

            How to apply it:
            ├── one hook only            → .onBeforeHandle({ as: 'scoped' }, fn)
            ├── every hook of a guard    → .guard({ as: 'scoped', ... })
            └── everything in the instance → .as('scoped') at the end of the chain
                                             (accepts only 'scoped' | 'global')
```

> `as('scoped')` goes up **one** level. To cross two, each intermediate instance needs its own `as('scoped')` — or use `global`. Full example, with the failing case, in § 5.

---

## 1. Concept: scope is the only thing that decides whether a plugin affects a route — and the default is the most restrictive

In almost every server framework, registering a middleware on the app means it runs for everything. Not in Elysia. A hook registered on an instance applies to **that instance and its descendants**, and to no one else — not even to whoever called `.use()` on it.

The docs chose an exact analogy:

> "**Elysia isolate lifecycle by default** unless explicitly stated. This is similar to **export** in JavaScript, where you need to export the function to make it available outside the module."

The problem is that the failure is **silent and inverted relative to intuition**: you write an authentication plugin, apply it to the app, and the app's routes are left unprotected. Nothing breaks. No type complains. The plugin's tests pass, because *its own* routes are protected.

```ts
import { Elysia } from 'elysia'

const profile = new Elysia()
  .onBeforeHandle(({ cookie }) => {
    // ⚠️ DEFECT 2: `throw new Error` is not a domain error. Elysia classifies it
    //    as UNKNOWN and responds 500 — not 401 — and Eden sees no typed error.
    //    The right way is `return status(401, { error: 'Not authenticated' })` — ELYSIA-CORE-03.
    if (!isSessionValid(cookie)) throw new Error('not authenticated')
  })
  .get('/profile', () => loadProfile())

const app = new Elysia()
  .use(profile)
  // ⚠️ DEFECT 1: there is NO session check. Open route. No warning.
  //    The hook above is `local`: it protects the routes of `profile` and nothing else.
  .patch('/profile/rename', ({ body }) => rename(body))
```

**There are two defects, and only one of them is about scope.** The scope one (`ELYSIA-LIFE-01`) leaves the consumer's route open; the signaling one (`ELYSIA-CORE-03`) makes the *protected* route respond 500 instead of 401 when the session is invalid. Fixing one without the other leaves the block wrong. This note exists largely because of this block. The complete fix is in § 5.

There is a second reach rule, orthogonal to scope and just as silent: **an event only applies to routes registered after it**. The two combine, and when facing "my hook does not run" both have to be checked, in this order: first order, then scope.

---

## 2. The lifecycle order

```
   request
      │
 ┌────▼──────────┐  onRequest        PreContext only. GLOBAL (ignores route
 │               │                   order). A return short-circuits everything.
 ├───────────────┤  onParse          fills body for a content-type not covered
 ├───────────────┤  onTransform      mutates the context so it passes validation
 │               │  + derive         adds a property — SAME queue as transform
 ├═══════════════┤  ►► VALIDATION of body/query/params/headers/cookie
 ├───────────────┤  onBeforeHandle   authorization. Return != undefined SKIPS the handler.
 │               │  + resolve        adds a property — SAME queue as beforeHandle
 ├───────────────┤  ►► HANDLER
 ├───────────────┤  onAfterHandle    reads responseValue. Returning does NOT skip the next ones.
 ├───────────────┤  mapResponse      produces a Response. Returning SKIPS the next ones.
 └────┬──────────┘
      │  ►► response sent
 ┌────▼──────────┐  onAfterResponse  logging and analytics
 └───────────────┘
        onError intercepts an error thrown in ANY phase above
```

What each one can and cannot do:

| Hook | Sees | Can | Cannot |
| --- | --- | --- | --- |
| `onRequest` | `request`, `set`, `store`, `status`, `redirect`, `server` and decorators | rate limit, cache, IP blocking, global header, typed short-circuit with `status(...)` | read `body`, `query`, `params`, `cookie`, or any `derive` |
| `onParse` | context + `contentType` | return the parsed body | assume it runs: if an earlier parser filled the body, it stops |
| `onTransform` | raw context | mutate the context | trust the type — nothing has been validated |
| `derive` | raw context | add properties | trust the type of what it read |
| `onBeforeHandle` | **validated** context | authorize, short-circuit | change what was already validated without consequence |
| `resolve` | **validated** context | add typed properties | be used in a local hook (only in `guard`, instance or macro) |
| `onAfterHandle` | `responseValue` | transform the return, set a header by type | stop the following `afterHandle` |
| `mapResponse` | `responseValue` | return a `Response` | count on running if an earlier `mapResponse` already returned |
| `onError` | `error`, `code` | format, log, respond | catch `return status(...)` — it only catches what was thrown |
| `onAfterResponse` | `responseValue`, `set` | log, measure | change the response — it is already gone |

### The `PreContext` of `onRequest` — canonical enumeration

This is the enumeration the three Elysia notes must repeat. It is extracted from `PreContext` in `context.d.ts` of `elysia@1.4.29`, which is the source, not the Lifecycle page (the page lists only `request`, `set`, `store` and decorators, and is incomplete):

| Property | Note |
| --- | --- |
| `request` | the Web Standard `Request` — the only way to read anything from the body here |
| `set` | the response's `{ headers, status?, redirect? }` |
| `store` | the instance's global state, created by `.state()` |
| `status` | **the `status(code, value)` function** — it is what allows a typed short-circuit |
| `redirect` | redirect function |
| `server` | `Server \| null` (**Bun only**) |
| decorators | everything `.decorate()` added |

The item most often missing from second-hand enumerations is `status`. Without it, the only way out of an `onRequest` that wants to block the request is building a `Response` by hand; with it, `return status(429, { error: 'Rate limit exceeded' })` short-circuits and is the same typed value as in the rest of the lifecycle.

Not in the `PreContext`, because they do not exist yet when `onRequest` runs: `body`, `query`, `params`, `headers` (read `request.headers`), `cookie`, `route`, `responseValue`, and any `derive`/`resolve`. Verified on 1.4.30: `path` **is** present at runtime.

Two queue details the docs verify with runnable examples: `onTransform` and `derive` share the same queue (they run in registration order, not "all transforms then all derives"), and the same holds for `onBeforeHandle` and `resolve`.

Besides the request lifecycle there are `onStart` and `onStop`, which belong to the **server** — they run once on startup and shutdown, not per request.

| ID | Rule |
| --- | --- |
| `ELYSIA-LIFE-04` | `onRequest` is **NEVER** used for logic that needs `body`, `query`, `params`, `headers` or `cookie` — the `PreContext` does not contain them (headers come from `request.headers`). |

---

## 3. `state` × `decorate` × `derive` × `resolve`

Four APIs for "putting something in the context", separated by two questions: **when** the value is computed, and **whether** the input data has already been validated.

| | `state` | `decorate` | `derive` | `resolve` |
| --- | --- | --- | --- | --- |
| When it runs | once, at boot | once, at boot | on every request | on every request |
| Phase | — | — | `transform` (before validation) | `beforeHandle` (after validation) |
| Where it is read | `ctx.store.x` | `ctx.x` | `ctx.x` | `ctx.x` |
| Shared across requests | **yes** | **yes** | no | no |
| Sees `headers`/`body`/`query` | no | no | yes, **not validated** | yes, **validated and typed** |
| What it is for | counter, mutable flag | class, singleton, connection, logger | requestId, IP, timing | session, user, permission |
| Mutate | yes, that is the purpose | **no** — the docs say `SHOULD NOT` | n/a | n/a |

The distinction that causes the most bugs is the last column against the one before it. The docs are not ambiguous:

> "You might want to use [resolve] instead of derive in most cases. Resolve is similar to derive but execute after validation. This makes resolve more secure as we can validate the incoming data before using it to derive new properties."

**If the value decides access, it is `resolve`.** `derive` runs before validation; what it reads has not gone through any schema yet, and the docs themselves mark the page with the warning *"Derive doesn't handle type integrity"*.

```ts
import { Elysia, t } from 'elysia'

const context = new Elysia()
  // cheap, decides nothing: derive is fine
  .derive(({ server, request }) => ({
    ip: server?.requestIP(request)?.address,
    receivedAt: Date.now()
  }))

const auth = new Elysia({ name: 'auth' })
  .guard({
    headers: t.Object({
      authorization: t.TemplateLiteral('Bearer ${string}')
    })
  })
  // decides access: resolve, after validation. `authorization` is a guaranteed string.
  .resolve(({ headers: { authorization }, status }) => {
    const user = verifyToken(authorization.slice(7))
    if (!user) return status(401, { error: 'Invalid token' })
    return { user }
  })
  .get('/me', ({ user }) => user)      // user is typed
```

Note that both `derive` and `resolve` can **abort** by returning `status(...)`: they are lifecycle hooks, and the return has the same short-circuit effect. It is the standard pattern for authentication.

### The `store` trap

`store` is a shared mutable object. Destructuring a primitive from it takes a **snapshot at that moment**:

```ts
new Elysia()
  .state('counter', 0)
  .post('/inc', async ({ store }) => {
    const { counter } = store             // ❌ snapshot
    store.counter++                       // ✅ mutates the store
    await audit()
    return { before: counter, now: store.counter }   // `counter` never sees the write
  })
```

Verified on 1.4.30: the snapshot is stale only against writes **later in the same call**, including after an `await`. Destructuring in the handler's parameter (`({ store: { counter } }) => counter`) is re-evaluated per request, so it does see increments from earlier requests — the earlier claim that such a route "always returns 0" was wrong. In a handler that writes, read and write through `store.x`.

`state` also accepts remapping — `.state(({ old, ...rest }) => ({ ...rest, new: 1 }))` — and the docs warn that the returned object **replaces** the store, removing whatever is not in it.

| ID | Rule |
| --- | --- |
| `ELYSIA-LIFE-02` | An authentication or authorization decision **NEVER** uses `derive` — it **MUST** use `resolve` or `macro.resolve`, which run after validation. |
| `ELYSIA-LIFE-05` | A `decorate` value is **NEVER** mutated — for mutable state use `state`. |
| `ELYSIA-LIFE-06` | A `store` primitive is **NEVER** destructured in a handler that also writes it — the destructured value is a snapshot and does not see the write. *(wording revised 2026-10-25)* |

---

## 4. A plugin is an instance, and `use()` is the only way to compose

There is no `Plugin` type in Elysia. A plugin is an `Elysia` instance, which could run on its own:

```ts
// auth/index.ts
import { Elysia } from 'elysia'
import { Auth } from './service'

export const auth = new Elysia({ name: 'auth', prefix: '/auth' })
  .post('/sign-in', ({ body, cookie: { session } }) => Auth.signIn(body, session), {
    body: AuthModel.signInBody,
    response: { 200: AuthModel.signInOk, 400: AuthModel.signInInvalid }
  })

// index.ts
new Elysia().use(auth).use(orders).use(users).listen(3000)
```

`use()` accepts an instance, a function `(app) => app`, an async plugin and `import('./plugin')` (lazy — the module registers after start, and `await app.modules` waits for it).

The docs recommend an **instance** over a functional callback, and state the reason: callbacks *"make encapsulation and scope harder to handle correctly"*. On cost they are blunt: *"Elysia can create 10k instances in a matter of milliseconds"* — it is not a performance decision.

### Dependency is explicit

What a plugin adds through `decorate`/`state`/`model` **is** inherited by whoever calls `.use()` — but only after the `use()`, and you have to declare it:

```ts
const auth = new Elysia().decorate('Auth', AuthService)

new Elysia()
  .get('/a', ({ Auth }) => Auth.profile())   // ❌ type error: 'Auth' does not exist here
  .use(auth)
  .get('/b', ({ Auth }) => Auth.profile())   // ✅
```

What is **not** inherited is the lifecycle — see § 5. This is Elysia's central asymmetry: properties go up, hooks do not.

### Deduplication by `name` and `seed`

Without `name`, a plugin applied by three instances **runs three times**. With `name`, Elysia deduplicates it. Verified on 1.4.30: an unnamed plugin used by two sibling instances runs its global `onRequest`, `derive` and `onBeforeHandle` **twice per request**; named, once.

```ts
const ip = new Elysia({ name: 'ip' })            // without this, it runs once per .use()
  .derive({ as: 'global' }, ({ server, request }) => ({
    ip: server?.requestIP(request)
  }))

const routesA = new Elysia().use(ip).get('/a', ({ ip }) => ip)
const routesB = new Elysia().use(ip).get('/b', ({ ip }) => ip)
new Elysia().use(routesA).use(routesB)           // `ip` registers only once
```

`seed` complements it: when the same plugin is applied with different configurations and each configuration must count as a distinct instance, the `seed` (any value, not only a string) goes into the checksum.

### Global × explicit: the docs' criterion

| Make it **global** | Make it **explicit** |
| --- | --- |
| a plugin that adds no types — cors, compress, helmet | a plugin that adds types — macro, state, model |
| lifecycle no instance should control — tracing, logging | business logic the instance interacts with — Auth, Database |
| a single OpenAPI document, a single tracer, a single logger | store/session, ORM, feature module |

| ID | Rule |
| --- | --- |
| `ELYSIA-LIFE-03` | A plugin applied by more than one instance **MUST** declare `name` — without it the lifecycle runs once per application. |
| `ELYSIA-LIFE-07` | A new plugin **MUST** be a `new Elysia()` instance, not an `(app) => app` callback — the callback makes encapsulation and scope harder. |

---

## 5. Scope: `local`, `scoped`, `global` and the `as()` method

The most important section of this note.

### The three levels

| Scope | Reaches |
| --- | --- |
| `local` (**default**) | the current instance and its descendants |
| `scoped` | **+ the immediate parent** (whoever called `.use()`) |
| `global` | every instance, at any level |

The official table, with four nested instances (`child` inside `current` inside `parent` inside `main`), and the hook registered in `current`:

| hook scope | child | current | parent | main |
| --- | --- | --- | --- | --- |
| `local` | ✅ | ✅ | ❌ | ❌ |
| `scoped` | ✅ | ✅ | ✅ | ❌ |
| `global` | ✅ | ✅ | ✅ | ✅ |

Look at `scoped`: it goes up **one** level, not all of them. It is the source of the second round of confusion, after people discover that `local` does not go up.

### The three ways to declare scope

```ts
// 1. inline — a single hook
new Elysia()
  .derive({ as: 'scoped' }, () => ({ requestId: crypto.randomUUID() }))

// 2. guard — every hook and schema in a block
new Elysia()
  .guard({
    as: 'scoped',
    response: t.String(),
    beforeHandle() { /* ... */ }
  })
  .get('/child', 'ok')

// 3. instance — everything the instance registered, at the end of the chain
new Elysia()
  .derive(() => ({ hi: 'ok' }))
  .get('/child', ({ hi }) => hi)
  .as('scoped')                        // accepts 'scoped' | 'global', not 'local'
```

`guard` with `as` is convenient but has a verified limit: *"it doesn't support `derive` and `resolve` method"*. To raise the scope of a `resolve`, use `as` inline on the `resolve` itself or `.as()` on the instance.

### The authentication plugin, fixed

The broken block from § 1, with the two possible fixes:

```ts
import { Elysia, t } from 'elysia'

// ── Option A: explicit scope on the hook ───────────────────────
const auth = new Elysia({ name: 'auth' })
  .resolve({ as: 'scoped' }, ({ cookie: { session }, status }) => {
    const user = validateSession(session.value)
    if (!user) return status(401, { error: 'Not authenticated' })
    return { user }
  })

const app = new Elysia()
  .use(auth)
  .get('/profile', ({ user }) => user)                          // ✅ protected
  .patch('/profile/rename', ({ user, body }) => rename(user, body))  // ✅ protected

// ── Option B: macro, applied route by route ────────────────────
const authMacro = new Elysia({ name: 'auth.macro' })
  .macro({
    authenticated: {
      resolve: ({ cookie: { session }, status }) => {
        const user = validateSession(session.value)
        if (!user) return status(401, { error: 'Not authenticated' })
        return { user }
      }
    }
  })

const publicAndPrivate = new Elysia()
  .use(authMacro)
  .get('/health', () => 'ok')                                       // open, by design
  .get('/profile', ({ user }) => user, { authenticated: true })     // protected, explicit
```

**Validation runs before `resolve` and `onBeforeHandle`** (§ 2). Verified on 1.4.30: an anonymous request with an invalid body or params is answered **422 — describing the schema** — before the auth hook ever runs; a member sending bad params under `/admin` gets 422, not 403. When unauthenticated callers must get 401 first, add a cheap credential-presence check in `onRequest` on the protected prefix (it has `request.headers` and `status`), keep the real decision in `resolve`, and test the "no token + bad body" case.

**The choice between A and B is architectural, not a matter of taste.** Option A protects everything from that point on and fails toward the safe side: forgetting means being over-protected. Option B makes each route self-documenting and lets open and closed routes mix in the same instance, but fails toward the unsafe side: forgetting `authenticated: true` leaves the route open. In a fully authenticated module, A; where there is a mix, B, with a review that every new route declares the flag.

### Stacking `as('scoped')`

Since `scoped` goes up only one level, crossing two requires `as('scoped')` on every intermediate instance:

```ts
const plugin = new Elysia()
  .guard({ response: t.String() })
  .onBeforeHandle(() => { console.log('called') })
  .get('/ok', () => 'ok')
  .as('scoped')

const intermediate = new Elysia()
  .use(plugin)
  .get('/also-ok', () => 'ok')
  .as('scoped')          // without this line, `parent` is not affected

const parent = new Elysia()
  .use(intermediate)
  .get('/now-applies', () => 'ok')
```

If the intent is "it applies everywhere, period" — tracing, logging, CORS — use `global` and avoid the chain of `as`.

| ID | Rule |
| --- | --- |
| `ELYSIA-LIFE-01` | A plugin hook that must apply to whoever consumes it **MUST** declare scope (`{ as: 'scoped' }`, `guard({ as })` or `.as()`) — the `local` default does not go up, and the failure is silent. |
| `ELYSIA-LIFE-08` | An authentication plugin **MUST** prove in a test that a route of the **consuming** instance is rejected without credentials — testing only the plugin's own routes does not catch a scope error. |
| `ELYSIA-LIFE-09` | A cross-cutting hook that must apply across the whole tree (tracing, logging, CORS) **MUST** use `global`, not a chain of `as('scoped')`. |

---

## 6. `macro`: reusable hook, activated declaratively

`macro` turns a set of hooks and schemas into a property that routes activate in the local hook. It is the mechanism that gives per-route readable authentication.

```ts
import { Elysia, t, status } from 'elysia'

const rbac = new Elysia({ name: 'rbac' })
  .macro({
    // shorthand form: the object becomes a function that receives a boolean
    authenticated: {
      resolve: ({ cookie: { session } }) => {
        const user = validateSession(session.value)
        if (!user) return status(401, { error: 'Not authenticated' })
        return { user }
      }
    },
    // parameterized form
    role: (required: 'admin' | 'operator') => ({
      seed: required,                         // goes into the deduplication checksum
      beforeHandle({ user, status }) {
        if (user.role !== required) return status(403, { error: 'Forbidden' })
      }
    })
  })

new Elysia()
  .use(rbac)
  .delete('/orders/:id', ({ params: { id } }) => cancel(id), {
    authenticated: true,
    role: 'admin'
  })
```

Four verified points that change code:

1. **A macro can declare a schema**, and it accumulates with the route's schema instead of replacing it — including schemas from different libraries.
2. **`return status(...)`, not `throw`.** The docs: *"It's recommended that you `return status` instead of `throw new Error()`"*, because `throw` becomes a 500, and because only the return preserves inference for Eden and for the OpenAPI generated from types.
3. **A macro deduplicates the lifecycle on its own**, using the property's value as the seed. An explicit `seed` covers the parameterized case.
4. **TypeScript limitation:** a macro that extends another does not infer types inside the `resolve`. The documented workaround is the named form `.macro('name', { ... })`. The same applies to using the macro's own schema in one of its hooks.

| ID | Rule |
| --- | --- |
| `ELYSIA-LIFE-10` | A macro **MUST** signal failure with `return status(...)` — `throw` becomes a 500 and loses inference for Eden and OpenAPI. |

---

## 7. `guard`: schema and hooks for several routes

`guard` applies schema and hooks to the instance's following routes (or to the block, in the callback form). It is equivalent to repeating the local hook on every route.

```ts
new Elysia()
  .get('/public', () => 'ok')                  // outside the guard
  .guard({
    headers: t.Object({ authorization: t.String() }),
    beforeHandle: [verifyToken, logAccess]     // accepts an array
  })
  .get('/private-1', () => 'ok')               // inside
  .get('/private-2', () => 'ok')               // inside
```

Schema precedence, verified: *"If multiple global schemas are defined for the same property, the latest one will take precedence. If both local and global schemas are defined, the local one will take precedence."*

And the behavior that tends to surprise: by default the route's schema **replaces** the guard's, it does not add to it — for the **flat** form (`.guard({ body }).post(...)`). Verified on 1.4.30: the **callback** form `.guard({ body }, (app) => …)` always enforces both, as if `schema: 'standalone'` were set. To add them up, `schema: 'standalone'` — details and example in [Elysia - Schema and Validation](elysia-schema-and-validation.md) § 4.

`group` with three arguments (`prefix`, `guard`, `callback`) is the condensed form of `group` + `guard`.

---

## 8. Official plugins in production

```ts
import { Elysia, env } from 'elysia'          // `env`, not `process.env` — ELYSIA-APP-09
import { cors } from '@elysia/cors'
import { openapi } from '@elysia/openapi'
import { jwt } from '@elysia/jwt'
import { opentelemetry } from '@elysia/opentelemetry'

new Elysia()
  .use(opentelemetry())                       // first: instruments the rest
  .use(cors({ origin: /\.mydomain\.com$/, credentials: true }))
  .use(openapi())                             // documentation at /openapi
  .use(jwt({ name: 'jwt', secret: env.JWT_SECRET!, exp: '7d' }))
  .use(auth)
  .use(orders)
  .listen(3000)
```

| Plugin | Calibration note |
| --- | --- |
| `@elysia/cors` | `origin` defaults to `true` and `credentials` to `true`. Verified on 1.4.2: it **reflects whatever `Origin` arrives** (`access-control-allow-origin: https://evil.example`) with `allow-credentials: true` — any site can make credentialed calls. Restrict `origin` with a regex or a list. |
| `@elysia/openapi` | exposes `/openapi` (Scalar) and `/openapi/json`. `fromTypes()` generates the docs from types, with no runtime schema. See [Elysia - OpenAPI](elysia-openapi.md). |
| `@elysia/jwt` | wraps `jose`; `alg` defaults to `HS256` (symmetric). Asymmetric keys and rotation via JWKS are not what the defaults give you. |
| `@elysia/static` | `public` folder, `/public` prefix. Does not work on Cloudflare Workers |
| `@elysia/opentelemetry` | `record()`, `getCurrentSpan()`, `setAttributes()`. |
| `@elysia/bearer`, `@elysia/cron`, `@elysia/html`, `@elysia/server-timing` | token extraction, cron, HTML/JSX, `Server-Timing` header |

### Name your hook functions

A small detail with a big effect on observability: the OpenTelemetry plugin uses the hook's **function name** as the span name. An anonymous arrow function becomes `anonymous` in the trace.

```ts
// ⚠️ span: "anonymous"
app.resolve(async ({ cookie: { session } }) => ({ user: await fetchProfile(session.value) }))

// ✅ span: "fetchUser"
app.resolve(async function fetchUser({ cookie: { session }, status }) {
  const user = await fetchProfile(session.value)
  if (!user) return status(401, { error: 'Not authenticated' })
  return { user }
})
```

The hook is `resolve`, not `derive`, and that is not a detail of the example: resolving a session is an access decision, and `derive` runs before validation — `ELYSIA-LIFE-02`. The observability point applies equally to both hooks; the choice of which hook to use comes before it.

Two verified production notes: instrumentations that rely on monkey-patching (`PgInstrumentation`) require the SDK to load **before** the instrumented module — isolate it in `src/instrumentation.ts` and use `preload` in `bunfig.toml`. And when compiling with `bun build`, the instrumented library has to stay out of the bundle (`--external pg`), otherwise the patch does not take.

| ID | Rule |
| --- | --- |
| `ELYSIA-LIFE-11` | A hook in an app instrumented with OpenTelemetry **MUST** be a named function — an anonymous arrow produces an `anonymous` span and makes the trace useless. |
| `ELYSIA-LIFE-12` | `cors()` in an authenticated API **NEVER** keeps the default `origin` (`*`) — combined with `credentials: true` it is too permissive. |

---

## Anti-patterns

| Anti-pattern | Why it fails | What to do |
| --- | --- | --- |
| **Auth plugin with no declared scope** | `local` is the default: the `onBeforeHandle`/`resolve` protects only the plugin's own routes. The routes of whoever called `.use()` are left **open**, with no error and no type warning | `{ as: 'scoped' }`, `.as('scoped')` or a per-route macro — `ELYSIA-LIFE-01`, and a test on the consumer side — `ELYSIA-LIFE-08` |
| `derive` to resolve a session or permission | runs in `transform`, **before** validation: the header/cookie it reads has not gone through a schema, and the docs mark `derive` as having no type integrity | `resolve` or `macro.resolve` — `ELYSIA-LIFE-02` |
| Plugin without `name`, applied by several modules | the lifecycle runs once **per application** — duplicated hook, duplicated log, duplicated check | `new Elysia({ name: 'auth' })` — `ELYSIA-LIFE-03` |
| `.use(plugin)` after the routes it should affect | an event only applies to routes registered after it; the routes above are left without the hook | move the `.use()` before them — `ELYSIA-CORE-01` |
| `as('scoped')` expected to cross two levels | `scoped` goes up **one** level; the intermediate instance needs its own `as`, or nothing reaches the top | chain `as('scoped')` at every level, or use `global` — `ELYSIA-LIFE-09` |
| Macro that does `throw new Error()` when denying access | becomes `500 Internal Server Error` instead of 401/403, and Eden does not see the typed error | `return status(401, ...)` — `ELYSIA-LIFE-10` |
| `decorate` of an object that is mutated on every request | `decorate` is shared across requests: the mutation leaks from one user to another | `state` for mutable, `resolve` for a per-request value — `ELYSIA-LIFE-05` |
| `const { counter } = store; store.counter++` in one handler | the destructured value is a snapshot; it never sees the write | read and write through `store.counter` — `ELYSIA-LIFE-06` |
| Logic that reads `body` inside `onRequest` | `PreContext` has no `body`, `query`, `params` or `cookie` — they have not been parsed yet | `onParse`, `onTransform` or `onBeforeHandle` — `ELYSIA-LIFE-04` |

---

## Review checklist

- [ ] Does every plugin hook that must affect the consumer declare scope? → `ELYSIA-LIFE-01`
- [ ] Does no access decision use `derive`? → `ELYSIA-LIFE-02`
- [ ] Does every reused plugin have a `name`? → `ELYSIA-LIFE-03`
- [ ] Does no `onRequest` depend on `body`/`query`/`params`/`cookie`? → `ELYSIA-LIFE-04`
- [ ] Is no `decorate` value mutated? → `ELYSIA-LIFE-05`
- [ ] Is no `store` primitive destructured? → `ELYSIA-LIFE-06`
- [ ] Are new plugins instances, not `(app) => app` callbacks? → `ELYSIA-LIFE-07`
- [ ] Is there a test proving rejection on a route of the auth plugin's **consuming** instance? → `ELYSIA-LIFE-08`
- [ ] Do cross-cutting hooks use `global` instead of a chain of `as('scoped')`? → `ELYSIA-LIFE-09`
- [ ] Do macros deny access with `return status`, never `throw`? → `ELYSIA-LIFE-10`
- [ ] Are hooks named functions where OpenTelemetry is present? → `ELYSIA-LIFE-11`
- [ ] Does `cors()` have a restricted `origin`? → `ELYSIA-LIFE-12`
