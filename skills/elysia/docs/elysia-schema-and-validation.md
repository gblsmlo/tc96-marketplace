---
title: Elysia - Schema and Validation
link: https://elysiajs.com/essential/validation.html
tags:
  - elysia
  - schema
  - agent-context
source: "Official documentation — https://elysiajs.com/ — behaviour re-executed on elysia 1.4.30 and zod 4.6.7 on 2026-10-25"
verified-at: 2026-10-25
---

# Elysia — Schema and Validation

## Contents

- [1. Concept: one declaration produces four artifacts — duplicating any of them is a regression](#1-concept-one-declaration-produces-four-artifacts--duplicating-any-of-them-is-a-regression)
- [2. t × Standard Schema: where Zod still makes sense](#2-t--standard-schema-where-zod-still-makes-sense)
- [3. Per-route schema and automatic coercion](#3-per-route-schema-and-automatic-coercion)
- [4. guard, precedence and standalone; reference models](#4-guard-precedence-and-standalone-reference-models)
- [5. response per status, and the validation error](#5-response-per-status-and-the-validation-error)
- [Antipatterns](#antipatterns)
- [Review checklist](#review-checklist)

> `t` (TypeBox) and Standard Schema · per-route schema and automatic coercion · `guard`, precedence and `standalone` · reference models · `response` per status · validation error.
>
> **Does not cover:** routes and responses ([Elysia - Routing and Handler](elysia-routing-and-handler.md)) · scope, hooks and plugins ([Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md)) · OpenAPI documentation ([Elysia - OpenAPI](elysia-openapi.md)) · the Eden client and TanStack Query ([Elysia - Eden](elysia-eden.md)).

Entry: [Elysia](elysia.md) · Normative basis: [Elysia](elysia.md) § 6

---

## 1. Concept: one declaration produces four artifacts — duplicating any of them is a regression

The sentence is quoted verbatim from the source:

> "A single Elysia/TypeBox schema can be used for: Runtime validation · Data coercion · TypeScript type · OpenAPI schema"

And there is a fifth, which the docs cover on another page: the same schema is the **contract Eden consumes on the frontend** ([Elysia - Eden](elysia-eden.md)). One declaration, five effects.

```ts
import { Elysia, t } from 'elysia'

const app = new Elysia()
  .post('/orders', ({ body, status }) => {
    // body is { sku: string, quantity: number } — no annotation, no cast
    const order = create(body)
    if (!order) return status(409, { error: 'Out of stock' })
    return status(201, order)     // 201 is in `response`: success goes out through `status`
  }, {
    body: t.Object({
      sku: t.String({ minLength: 3 }),
      quantity: t.Number({ minimum: 1 })
    }),
    response: {
      201: t.Object({ id: t.Number(), sku: t.String() }),
      409: t.Object({ error: t.String() })
    }
  })

export type App = typeof app
```

From that block, without a single extra line, you get: rejection of malformed payloads at runtime; the type of `body` in the handler; the return type checked against `response`; the entry in `/openapi`; and the type the frontend's `treaty<App>()` sees, including the 409 as a typed error variant.

> **Note the `status(201, order)`.** Declaring `201` in `response` does not change the status of anything — a bare `return order` goes out as **200**, and 200 is not even in the map. The declared status and the emitted status are two different things, and `status(code, value)` is what ties them together; `ELYSIA-CORE-04` exists exactly for this reason. A `response` map listing codes the handler never emits is false documentation: it passes the build, generates wrong OpenAPI, and the frontend's `switch (error.status)` covers a dead case.

The corollary is the most important rule in this note: **any hand-written TypeScript `interface` describing a payload that already has a schema is duplication and will diverge.** When you need the type outside the handler, extract it:

```ts
export const OrderBody = t.Object({ sku: t.String(), quantity: t.Number() })
export type OrderBody = typeof OrderBody.static     // ← do not rewrite it
```

It is the usual case against duplicated types, with one difference: here the tool makes the duplication unnecessary instead of merely undesirable.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-01` | The TypeScript type of a validated payload **MUST** derive from the schema (`typeof S.static`) — **NEVER** be rewritten by hand. |

---

## 2. `t` × Standard Schema: where Zod still makes sense

Elysia 1.4 supports **Standard Schema**. The verified list is Zod, Valibot, ArkType, Effect Schema, Yup and Joi — and the source is explicit about mixing them: *"You can use any validator together in the same handler without any issue."*

```ts
import { Elysia } from 'elysia'
import { z } from 'zod'
import * as v from 'valibot'

new Elysia()
  .get('/id/:id', ({ params: { id }, query: { name } }) => id, {
    params: z.object({ id: z.coerce.number() }),     // Zod
    query: v.object({ name: v.literal('Lilith') })   // Valibot, on the same route
  })
```

So the question stops being "can I use Zod" and becomes "where". The verified trade-offs:

| | `t` (TypeBox) | Zod via Standard Schema |
| --- | --- | --- |
| Query/params coercion | **automatic** — `t.Number()` becomes `t.Numeric()` in a route schema | manual: `z.coerce.number()` |
| OpenAPI | direct, no configuration | Zod 4: read natively (Standard JSON Schema) — no `mapJsonSchema`; Zod 3 and Valibot need it ([Elysia - OpenAPI](elysia-openapi.md) § 6) |
| File validation | `t.File({ type: 'image/*' })` actually validates | needs `fileType()` — see below |
| Cookie options in the schema | `t.Cookie(props, { secrets, sign, httpOnly })` | no equivalent |
| Sharing the schema with the frontend | the type travels through Eden; the schema itself stays on the server | the whole schema is importable on both sides |
| Already used elsewhere in the project | no — new | yes |

**Calibration.** Use `t` at the HTTP boundary: query, params, headers, cookie, upload. That is where Elysia's types do work Zod does not do for free, and where OpenAPI comes out with no configuration. Use Zod where the schema is **shared with the frontend** — form validation that needs the same rules as the server, domain types that already live in a shared package. The two coexist, even on the same route, and a `standalone` `guard` in Zod can add up with a local schema in `t` (§ 4).

What **not** to do is declare a shape in Zod and redeclare the same shape in `t`. That is the duplication from § 1 with extra steps.

> **File validation with Standard Schema needs care.** The docs are blunt: *"most validators don't actually validate the file"* — they check the declared `content-type`, which the client controls. Elysia exports `fileType`, which checks by magic number. It relies on the `file-type` package, a peer dependency of `elysia` that Bun installs automatically (add it explicitly with a package manager that skips peers), and it resolves `true` or **rejects** on a mismatch — hence the `.catch(() => false)`:
>
> ```ts
> import { Elysia, fileType } from 'elysia'
> import { z } from 'zod'
>
> new Elysia().post('/upload', ({ body }) => body, {
>   body: z.object({
>     // fileType resolves true or REJECTS on a mismatch: map the rejection to false
>     photo: z.file().refine((f) => fileType(f, 'image/jpeg').catch(() => false))
>   })
> })
> ```

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-02` | An upload validated by Standard Schema **MUST** use `fileType()` — generic validators check the `content-type` declared by the client, not the content. |

---

## 3. Per-route schema and automatic coercion

Six keys in the route's third argument: `body`, `query`, `params`, `headers`, `cookie`, `response`.

```ts
new Elysia()
  .get('/orders', ({ query }) => list(query), {
    query: t.Object({
      page: t.Number({ minimum: 1, default: 1 }),     // "2" → 2
      active: t.Boolean(),                            // "true" → true
      tags: t.Array(t.String()),                      // ?tags=a,b  or  ?tags=a&tags=b
      filter: t.Optional(t.ObjectString({ state: t.String() }))  // JSON in a string
    })
  })
```

### The three coercion rules

1. **`t.Number` becomes `t.Numeric` in a route schema.** Because headers, query and path params always arrive as strings. This applies to `params`, `query`, `headers`, `cookie` — **not to `body`**, nor to a nested `t.Object`. A `t.Number()` outside a route schema is not converted either.
2. **`t.Boolean` becomes `t.BooleanString`**, for the same reason and with the same exceptions.
3. **An array in query accepts two formats:** comma (`?tags=a,b,c`, the `nuqs` format) and repeated key (`?tags=a&tags=b`, the HTML form format). You must declare `t.Array(...)` — without it, a repeated key becomes a single string.

This asymmetry between `body` and the rest is deliberate, and it is the source of a recurring bug: `t.Number()` in a `body` **rejects** `"2"`, because JSON has real numbers and there is no reason to coerce. Verified on 1.4.30, with one exception: **`t.Integer()` in a body does coerce `"2"`** — do not infer the rule from it. And a `t.Number` nested inside a query `t.Object` is not coerced (`?f[n]=2` is not parsed as an object either).

### Per-key behavior

- **`headers`**: `additionalProperties: true` by default (extra headers pass), and **names are always lowercase** — declaring `Authorization` does not match.
- **`cookie`**: also `additionalProperties: true`. `t.Cookie(props, opts)` accepts cookie options in the second argument (`secrets`, `sign`, `httpOnly`, `secure`, `maxAge`, …), which makes signing and key rotation declarative.
- **`params`**: rarely needed — Elysia already infers `string` from the path. Declare it when you need a number, a format or a template literal.
- **`body`**: ignored on GET and HEAD by default (RFC 2616). The parser is chosen from the schema (object → JSON; object with a `t.File` one level down → multipart; `t.URLEncoded` → urlencoded; primitive → text), and it can be forced with `parse: 'json' | 'formdata' | 'urlencoded' | 'text' | 'none'`.
- **`t.Optional`** at the route level makes the *whole key* optional (`query: t.Optional(t.Object({...}))`), which differs from plain TypeBox, where `Optional` marks an object field.

### `normalize`: fields outside the schema disappear

The constructor has `normalize`, defaulting to **`true`**: undeclared properties are silently removed from the input **and from the output**. With `normalize: false`, they become a validation error — verified: **422 "Unexpected property"**, on the input and on the response.

The default is convenient, with one good security consequence (mass assignment does not get through) and one trap: a field you think you are returning, but forgot to declare in `response`, vanishes from the response without warning.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-03` | A `headers` schema **MUST** declare names in lowercase — Elysia normalizes them, and a capitalized name never matches. |
| `ELYSIA-TYPE-04` | A numeric `body` field **NEVER** relies on coercion — only `params`, `query`, `headers` and `cookie` convert `t.Number` into `t.Numeric`. |

---

## 4. `guard`, precedence and `standalone`; reference models

`guard` applies a schema to several routes. The precedence, verified: among global schemas the **last** one wins; between global and local, the **local** one wins.

And the behavior that surprises people: the route's schema **replaces** the guard's instead of adding to it.

```ts
new Elysia()
  .guard({ body: t.Object({ age: t.Number() }) })
  .post('/user', ({ body }) => body, {
    body: t.Object({ name: t.String() })    // replaces it: `age` is no longer required
  })
```

To add them up, use `schema: 'standalone'`:

```ts
new Elysia()
  .guard({
    schema: 'standalone',                    // [!code ++]
    body: t.Object({ age: t.Number() })
  })
  .post('/user', ({ body }) => body, {       // body requires age AND name
    body: t.Object({ name: t.String() })
  })
```

`standalone` runs both schemas independently, and — a verified detail — **they can come from different libraries**: a Zod guard adding up with a local `t` schema works.

### Reference models

`.model()` registers schemas by name, referenceable by string, with autocomplete:

```ts
// auth.model.ts
export const authModel = new Elysia()
  .model({
    'auth.signIn': t.Object({ user: t.String(), password: t.String() }),
    'auth.profile': t.Object({ id: t.Number(), user: t.String() })
  })

// auth/index.ts
new Elysia()
  .use(authModel)
  .post('/sign-in', ({ body }) => signIn(body), {
    body: 'auth.signIn',
    response: { 200: 'auth.profile' }
  })
```

Two effects: the schema appears in the OpenAPI `components` section and is referenced by `$ref` instead of being repeated inline; and duplicate names make Elysia **throw**, which the docs work around with a namespace-prefix convention (`admin.auth`, `user.auth`).

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-05` | A `guard` schema that needs to **add up** with the route's **MUST** declare `schema: 'standalone'` — the default `override` makes the local schema replace the guard's. |

---

## 5. `response` per status, and the validation error

Declaring `response` does four things at once, and it is the highest-leverage declaration in Elysia:

1. **validates the output** — the handler cannot return the wrong shape;
2. **constrains the handler's return type** at compile time;
3. **types `status(code, value)`**, which then only accepts the declared codes and shapes;
4. **hands Eden the per-status union of results**, which is what gives error narrowing on the frontend.

```ts
new Elysia()
  .get('/orders/:id', ({ params: { id }, status }) => {
    const order = find(id)
    if (!order) return status(404, { error: 'Not found' })
    if (!canView(order)) return status(403, { error: 'Forbidden' })
    return order
  }, {
    params: t.Object({ id: t.Numeric() }),
    response: {
      200: t.Object({ id: t.Number(), total: t.Number() }),
      403: t.Object({ error: t.String() }),
      404: t.Object({ error: t.String() })
    }
  })
```

Without the per-status map, Eden does not know 404 exists and the error arrives as `unknown`. With it, the frontend does `switch (error.status)` with autocomplete — see [Elysia - Eden](elysia-eden.md).

`withHeader` (from `@elysia/openapi`) documents response headers, but the docs warn: *"`withHeader` is an annotation only, and does not enforce or validate the actual response headers."*

### Validation error

Two layers. Per field, with the schema's `error` property (a string or a function):

```ts
body: t.Object({
  quantity: t.Number({ error: 'quantity must be a number' }),
  email: t.String({ format: 'email', error: 'invalid email' })
})
```

And centrally, narrowing `code === 'VALIDATION'` in `onError`:

```ts
new Elysia()
  .onError(({ code, error, status }) => {
    if (code === 'VALIDATION') {
      // error is a ValidationError; `all` lists every cause, with `path` in OpenAPI format
      return status(422, {
        error: 'Invalid payload',
        fields: error.all.map((e) => ({ field: e.path, message: e.summary }))
      })
    }
  })
```

**Verified on 1.4.30 — do not ship per-field `error` strings without a central handler.** With a field `error` and no `onError`, the 422 body is the bare string, sent as `application/json` but not valid JSON. A central handler that answers JSON, keeps the schema's field message and echoes no input:

```ts
export const validation = new Elysia({ name: 'validation' }).onError({ as: 'global' }, function formatValidation({ code, error, status }) {
  if (code !== 'VALIDATION') return
  const fields = error.all.map((e) => ({
    path: 'path' in e ? e.path : '',
    message: ('schema' in e && (e.schema as { error?: string }).error) || e.summary || e.message
  }))
  return status(422, { error: 'invalid_request', fields })
})
```

Two limits, verified: with a Zod schema that has an **async** refine (such as the `fileType()` check in § 2), `error.all` is **empty**, so `fields` is `[]` — do not build UI that depends on it there; and each `error.all` item carries the submitted field value in `value`, which this handler deliberately leaves out.

`ValidationError` exposes `all` (every cause) and `validator` (TypeBox's `TypeCheck`). A field's `error` function **is only called if that field fails** — if the whole value is not an object, the field's function does not run, only the object's.

**The default status is 422.** `ValidationError.status = 422` in the package, and that is what an app **with no `onError` at all** sends — the `onError` above restates the default, it does not create it. If your API contract promises 400 for an invalid payload, the `onError` has to change the number **and** the `response` schema has to declare it; otherwise the client handles one number and the server sends another. Note that the OpenAPI spec documents a 422 only when the `response` map declares it ([Elysia - OpenAPI](elysia-openapi.md) § 2). The full table of default statuses per error class is in [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 5.

Four verified production behaviors:

- **With `NODE_ENV=production`, details are trimmed by default.** Verified on 1.4.30: the response carries `type`, `on` and `found` — and **`found` echoes the full raw input**, so a payload with a password comes back in the 422. Do not count on production mode to keep input out of error bodies; a central `onError` for `VALIDATION` decides what goes back.
- **`allowUnsafeValidationDetails: true` (default `false`) reverts the omission**, and the docs warn that it leaks the schema's shape — field names, expected types, constraints. It is free reconnaissance for anyone probing the API, and the option is global: there is no way to turn it on for a single route. If the detail is needed in development, make it conditional on the environment instead of leaving it on.
- **`validationDetail('message')`** (exported by `elysia`) includes the detail anyway, field by field — it is the surgical path when a specific field needs an actionable message in production.
- **`error.detail(error.message)`** in `onError` applies that to all of them at once.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-06` | A route that returns more than one status **MUST** declare `response` as a per-status map — without it the error reaches Eden as `unknown`. |
| `ELYSIA-TYPE-12` | `allowUnsafeValidationDetails: true` **NEVER** stays on in production — the option is global and makes the error response publish the schema's shape. |

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `interface Order {...}` on the frontend duplicating the server's `t.Object` | two sources of truth for the same shape; the divergence shows up in production, not in the build | `typeof S.static` on the server, `treaty<App>` on the client — `ELYSIA-TYPE-01` |
| Route with 404/403 and no per-status `response` map | Eden types the error as `unknown`; `switch (error.status)` loses narrowing and becomes `any` | declare `response: { 200: …, 403: …, 404: … }` — `ELYSIA-TYPE-06` |
| `guard` with a schema, expecting it to add up with the route's | the default is `override`: the local schema **replaces** the guard's, and the validation you thought was guaranteed disappears | `schema: 'standalone'` on the guard — `ELYSIA-TYPE-05` |
| `t.Number()` in a `body` field, expecting it to accept `"2"` | coercion only happens in `params`/`query`/`headers`/`cookie`; in `body` the number has to be a number | an explicit `t.Numeric()` if the client sends a string — `ELYSIA-TYPE-04` |
| `headers: t.Object({ Authorization: t.String() })` | Elysia normalizes headers to lowercase; the capitalized key never matches and validation always fails | `authorization` — `ELYSIA-TYPE-03` |
| `z.file()` without `fileType()` on an upload | validates the `content-type` declared by the client, which can be forged — an executable passes as an image | `.refine((f) => fileType(f, 'image/jpeg').catch(() => false))` — `ELYSIA-TYPE-02` |
| `response: { 201: ... }` with the handler doing `return order` | the bare return goes out as **200**, which is not even in the map; OpenAPI publishes a 201 that never happens | `return status(201, order)` — `ELYSIA-CORE-04` |
| `allowUnsafeValidationDetails: true` left on in production | the error response starts listing the schema's fields, types and constraints to any malformed request | make it conditional on the environment, or use `validationDetail()` field by field — `ELYSIA-TYPE-12` |

---

## Review checklist

- [ ] No payload type is rewritten by hand? → `ELYSIA-TYPE-01`
- [ ] Uploads validated by Standard Schema use `fileType()`? → `ELYSIA-TYPE-02`
- [ ] Header names in the schema are lowercase? → `ELYSIA-TYPE-03`
- [ ] No `body` field depends on coercion? → `ELYSIA-TYPE-04`
- [ ] Guards that need to add up declare `schema: 'standalone'`? → `ELYSIA-TYPE-05`
- [ ] Every route with multiple statuses has a `response` map? → `ELYSIA-TYPE-06`
- [ ] No production environment turns on `allowUnsafeValidationDetails`? → `ELYSIA-TYPE-12`
- [ ] Every status declared in `response` is actually emitted by a `status(code, value)`? → `ELYSIA-CORE-04`
