# Patterns — OpenAPI that passed a test

## Contents

- [1. The plugin, once, at the root](#1-the-plugin-once-at-the-root)
- [2. Models with names a generator keeps](#2-models-with-names-a-generator-keeps)
- [3. A module: defaults on the constructor, specifics on the route](#3-a-module-defaults-on-the-constructor-specifics-on-the-route)
- [4. Public and hidden routes](#4-public-and-hidden-routes)
- [5. The docs behind a token](#5-the-docs-behind-a-token)
- [6. The test that keeps the spec honest](#6-the-test-that-keeps-the-spec-honest)

Every block passed `bun test` and `tsc --noEmit` on elysia 1.4.30, @elysia/openapi 1.4.16 and zod 4.6.7. The spec excerpts are what `/openapi/json` actually returned.

---

## 1. The plugin, once, at the root

```ts
import { Elysia, t, env } from 'elysia'
import { openapi } from '@elysia/openapi'
import { z } from 'zod'

const docs = openapi({
  enabled: env.EXPOSE_DOCS === 'true',                          // fail closed: unset means off — ELYSIA-TYPE-19
  documentation: {
    info: { title: 'Orders API', version: '1.4.0', description: 'Order lifecycle' },
    tags: [{ name: 'orders', description: 'Create and read orders' }, { name: 'health' }],
    components: { securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } } }
  }
  // no mapJsonSchema: t and Zod 4 are read natively — ELYSIA-TYPE-07
})
```

## 2. Models with names a generator keeps

```ts
const models = new Elysia({ name: 'models' }).model({
  Order: t.Object({ id: t.Number(), sku: t.String(), quantity: t.Number() }),
  ApiError: t.Object({ error: t.String() }),
  ValidationError: t.Object({ type: t.Literal('validation'), message: t.String() })
})
```

Each becomes `components.schemas.<Name>` and every use is a `$ref`. For a list of a model, write `t.Array(t.Ref('#/components/schemas/Order'))` — verified to produce a resolving `$ref` and to keep response validation; `t.Ref('Order')` dangles and `'Order[]'` does not compile.

## 3. A module: defaults on the constructor, specifics on the route

```ts
const ordersModule = new Elysia({
  prefix: '/orders',
  detail: { tags: ['orders'], security: [{ bearerAuth: [] }] }   // inherited; a route's own keys win — ELYSIA-TYPE-20
})
  .use(models)
  .get('/:id', ({ params: { id }, status }) => (id === 1 ? { id, sku: 'ABC', quantity: 2 } : status(404, { error: 'not_found' })), {
    params: t.Object({ id: t.Number() }),
    response: { 200: 'Order', 401: 'ApiError', 404: 'ApiError', 422: 'ValidationError' },   // every status — ELYSIA-TYPE-06
    detail: { summary: 'Get an order', operationId: 'getOrder' }                             // explicit, unique — ELYSIA-TYPE-18
  })
  .post('', ({ body, status }) => status(201, { id: 2, ...body }), {   // '' not '/': '/' documents as /orders/
    body: z.object({ sku: z.string().min(3), quantity: z.number().int().min(1).default(1) }),
    response: { 201: 'Order', 401: 'ApiError', 422: 'ValidationError' },
    detail: { summary: 'Create an order', operationId: 'createOrder' }
  })
```

What the spec got for `GET /orders/{id}`: `tags: ["orders"]`, `security: [{ "bearerAuth": [] }]`, `responses` 200/401/404/422 with `$ref`s. For the Zod body: `required: ["sku"]` and `quantity` with `default: 1` — the input view, without `mapJsonSchema`.

## 4. Public and hidden routes

```ts
export const app = new Elysia()
  .use(docs)
  .get('/health', () => ({ ok: true }), {
    response: { 200: t.Object({ ok: t.Boolean() }) },
    detail: { summary: 'Liveness', operationId: 'getHealth', tags: ['health'], security: [] }   // public on purpose
  })
  .get('/internal/metrics', () => 'm', { detail: { hide: true } })   // served, not documented
  .use(ordersModule)
```

## 5. The docs behind a token

```ts
const guarded = new Elysia()
  .onRequest(({ request, status }) => {
    const { pathname } = new URL(request.url)
    if (pathname.startsWith('/openapi') && request.headers.get('authorization') !== `Bearer ${env.DOCS_TOKEN}`)
      return status(401, 'unauthorized')
  })
  .use(openapi())
```

Verified: `/openapi` and `/openapi/json` answer 401 without the token and 200 with it; other routes are untouched. `openapi({ enabled: false })` registers nothing (404).

## 6. The test that keeps the spec honest

```ts
test('every operation is documented for consumers', async () => {
  const res = await app.handle(new Request('http://localhost/openapi/json'))
  const spec = await res.json()
  const ops = Object.entries(spec.paths).flatMap(([path, methods]: [string, any]) =>
    Object.entries(methods).map(([m, op]: [string, any]) => ({ where: `${m.toUpperCase()} ${path}`, ...op })))
  const ids = ops.map((o) => o.operationId)
  expect(new Set(ids).size).toBe(ids.length)
  for (const op of ops) {
    expect(op.summary, op.where).toBeTruthy()
    expect(op.tags?.length, op.where).toBeGreaterThan(0)
    expect(Object.keys(op.responses ?? {}).length, op.where).toBeGreaterThan(0)
  }
  expect(spec.paths['/orders/{id}'].get.security).toEqual([{ bearerAuth: [] }])
  expect(spec.paths['/health'].get.security).toEqual([])
  expect(spec.paths['/internal/metrics']).toBeUndefined()
})
```

`scripts/spec-lint.mjs` runs the same checks over a dumped JSON, plus trailing slashes, unknown security schemes, empty request-body schemas and inputs that document no 422.
