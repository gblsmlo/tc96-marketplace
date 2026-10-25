# Patterns — schemas that passed a test

## Contents

- [1. One schema; the type derived from it](#1-one-schema-the-type-derived-from-it)
- [2. A query string that coerces, with defaults and bounds](#2-a-query-string-that-coerces-with-defaults-and-bounds)
- [3. Shared models and the paginated envelope](#3-shared-models-and-the-paginated-envelope)
- [4. A guard that adds to each route, and a response map per route](#4-a-guard-that-adds-to-each-route-and-a-response-map-per-route)
- [5. Zod at the boundary: an upload checked by its bytes](#5-zod-at-the-boundary-an-upload-checked-by-its-bytes)
- [6. A central validation handler: JSON, field messages, no input echoed](#6-a-central-validation-handler-json-field-messages-no-input-echoed)

Every block below passed `bun test` and `tsc --noEmit` on elysia 1.4.30 and zod 4.6.7.

---

## 1. One schema; the type derived from it

```ts
import { Elysia, t } from 'elysia'

export const OrderInput = t.Object({
  sku: t.String({ minLength: 3, error: 'sku must have at least 3 characters' }),   // field message — needs pattern 6, see below
  quantity: t.Number({ minimum: 1 })                     // a JSON number: no coercion in a body — ELYSIA-TYPE-04
})
export type OrderInput = typeof OrderInput.static         // never a hand-written interface — ELYSIA-TYPE-01
```

A field `error` string on its own makes the 422 body that bare string (not valid JSON). Ship it together with the central handler of pattern 6.

## 2. A query string that coerces, with defaults and bounds

```ts
const listQuery = t.Object({
  page: t.Number({ minimum: 1, default: 1 }),             // "2" -> 2; absent -> 1
  pageSize: t.Number({ minimum: 1, maximum: 100, default: 20 }),
  active: t.Optional(t.Boolean()),                        // "true" -> true
  tags: t.Optional(t.Array(t.String()))                   // ?tags=a,b  or  ?tags=a&tags=b
})
```

Keep it flat: a `t.Number` inside a nested `t.Object` in the query is not coerced.

## 3. Shared models and the paginated envelope

```ts
const Order = t.Object({ id: t.Number(), sku: t.String(), quantity: t.Number() })

export const ordersModel = new Elysia({ name: 'orders.model' }).model({
  'orders.input': OrderInput,
  'orders.order': Order,
  'orders.page': t.Object({ items: t.Array(Order), total: t.Number(), hasMore: t.Boolean() }),  // ELYSIA-TYPE-13
  'error': t.Object({ error: t.String() })
})
```

Referenced by name (`body: 'orders.input'`), a model becomes one entry under `components.schemas` in the spec. Prefix names by module — a duplicate name throws.

## 4. A guard that adds to each route, and a response map per route

```ts
export const app = new Elysia()
  .use(ordersModel)
  .guard({
    schema: 'standalone',                                 // without it, a route's own headers REPLACE these — ELYSIA-TYPE-05
    headers: t.Object({ 'x-tenant': t.String() })         // lowercase — ELYSIA-TYPE-03
  })
  .get('/orders', ({ query: { page, pageSize } }) => {
    const items = db.slice((page - 1) * pageSize, page * pageSize)
    return { items, total: db.length, hasMore: page * pageSize < db.length }   // extra row fields are dropped by normalize
  }, { query: listQuery, response: { 200: 'orders.page' } })
  .get('/orders/:id', ({ params: { id }, status }) => {
    const order = db.find((o) => o.id === id)
    if (!order) return status(404, { error: 'not_found' })
    return order
  }, {
    params: t.Object({ id: t.Number() }),
    headers: t.Object({ 'if-none-match': t.Optional(t.String()) }),   // added to x-tenant, not replacing it
    response: { 200: 'orders.order', 404: 'error' }       // a map by status — ELYSIA-TYPE-06
  })
  .post('/orders', ({ body, status }) => status(201, { id: db.length + 1, ...body }), {
    body: 'orders.input',
    response: { 201: 'orders.order' }
  })
```

Verified: `/orders/1` without `x-tenant` → 422; with it → 200; `/orders/9` → 404; `quantity: "2"` in the body → 422; `sku: "A"` → 422 whose body carries the field message.

## 5. Zod at the boundary: an upload checked by its bytes

```ts
import { Elysia, fileType } from 'elysia'
import { z } from 'zod'

export const uploads = new Elysia().post('/avatar', ({ body }) => ({ name: body.photo.name }), {
  // fileType resolves true or REJECTS on a mismatch: map the rejection to false, or it escapes as an unhandled error
  body: z.object({ photo: z.file().refine((f) => fileType(f, 'image/jpeg').catch(() => false), 'photo must be a JPEG') })
})
```

A text file named `b.jpg` with `type: image/jpeg` is refused (422); `z.file()` alone would accept it (`ELYSIA-TYPE-02`). With `t`, `t.File({ type: 'image/jpeg' })` checks the content itself. `fileType` uses the `file-type` package, a peer dependency of `elysia` that Bun installs on its own. Keep the call inline in the refine (or name the helper `fileType…`): the self-check looks for it there. Zod 4 reaches the OpenAPI spec without configuration — `elysia-openapi`.

## 6. A central validation handler: JSON, field messages, no input echoed

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

Verified: `{ sku: 'A', password: 'hunter2' }` answers `{"error":"invalid_request","fields":[{"path":"/sku","message":"sku must have at least 3 characters"},{"path":"/password","message":"Expected string length greater or equal to 10"}]}` — valid JSON, the schema's message kept, the password absent. Elysia's own production 422 echoes the raw input in `found`; this handler replaces it everywhere. With an async Zod refine `fields` is `[]`.
