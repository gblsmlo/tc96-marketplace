---
title: Elysia - OpenAPI
link: https://elysiajs.com/patterns/openapi.html
tags:
  - elysia
  - openapi
  - agent-context
source: "Official documentation — https://elysiajs.com/ — cross-checked by executing every behaviour on elysia 1.4.30, @elysia/openapi 1.4.16 and zod 4.6.7"
verified-at: 2026-10-25
---

# Elysia — OpenAPI

## Contents

- [0. Decision tree — what does this spec need?](#0-decision-tree--what-does-this-spec-need)
- [1. Concept: the spec is generated from what the routes declare — nothing more](#1-concept-the-spec-is-generated-from-what-the-routes-declare--nothing-more)
- [2. What reaches the spec from a route](#2-what-reaches-the-spec-from-a-route)
- [3. detail: per route, per guard, per instance](#3-detail-per-route-per-guard-per-instance)
- [4. operationId for code generators](#4-operationid-for-code-generators)
- [5. Security schemes](#5-security-schemes)
- [6. Zod, Valibot and other Standard Schema libraries](#6-zod-valibot-and-other-standard-schema-libraries)
- [7. fromTypes() and withHeaders](#7-fromtypes-and-withheaders)
- [8. Exposing the docs](#8-exposing-the-docs)
- [9. A test that keeps the spec honest](#9-a-test-that-keeps-the-spec-honest)
- [Antipatterns](#antipatterns)
- [Review checklist](#review-checklist)

> The `openapi()` plugin and its options · what reaches the spec from a schema, and what does not · `detail` per route, guard and instance · models as components · security schemes · `operationId` for code generators · Zod and other Standard Schema libraries · `fromTypes()` · `withHeaders` · `hide` and `exclude` · exposing the docs per environment · a test that keeps the spec honest.
>
> **Does not cover:** the schemas themselves ([Elysia - Schema and Validation](elysia-schema-and-validation.md)) · the typed TypeScript client, which needs no spec ([Elysia - Eden](elysia-eden.md)).

Entry: [Elysia](elysia.md) · Normative basis: [Elysia](elysia.md) § 6

Behaviour marked *verified* was executed on 2026-10-25 with the versions above.

---

## 0. Decision tree — what does this spec need?

```
Who reads the spec?
├── only people, in the browser          → the plugin's UI; summary + tags + a response map per route
├── a code generator (non-TS clients)    → all of the above + an explicit, unique operationId per route  § 4
│                                           + every error status declared                              § 2
└── an API gateway / contract test       → all of the above + security per protected route            § 5
│
Where do the schemas come from?
├── t (TypeBox)                          → nothing to configure
├── Zod 4                                → nothing to configure (Standard JSON Schema)                  § 6
├── Zod 3, Valibot, Effect, other        → mapJsonSchema for that vendor — confirm in /openapi/json     § 6
└── a route with no schema at all        → no `responses` in the spec: declare `response`,
                                            or fromTypes() (needs tsc on PATH)                          § 7
│
Should production serve /openapi?
└── decide it: enabled per environment, or protect the prefix with onRequest                           § 8
```

---

## 1. Concept: the spec is generated from what the routes declare — nothing more

The plugin reads each route's schemas and `detail` at runtime. Whatever a route does not *declare* does not exist for the spec: a status the handler emits but the `response` map omits, a 422 Elysia sends automatically, a header set in `set.headers`. A spec that compiles and renders can still describe a different API from the one that answers.

```ts
import { Elysia } from 'elysia'
import { openapi } from '@elysia/openapi'

const app = new Elysia()
  .use(openapi({
    enabled: env.EXPOSE_DOCS === 'true',             // fail closed: unset means off
    documentation: {
      info: { title: 'Orders API', version: '1.4.0', description: 'Order lifecycle' },
      tags: [{ name: 'orders', description: 'Create and read orders' }, { name: 'health' }],
      components: { securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } } }
    }
  }))
```

UI at **`/openapi`** (Scalar, loaded from a CDN), JSON at **`/openapi/json`**, OpenAPI **3.1.2** (verified). The two doc routes hide themselves from the spec.

### Plugin options (`@elysia/openapi` 1.4.16 — verified)

| Option | Default | What it does |
| --- | --- | --- |
| `enabled` | `true` | `false` registers no routes at all |
| `path` / `specPath` | `/openapi` / `/openapi/json` | UI and JSON routes |
| `provider` | `'scalar'` | `'swagger-ui'`, or `null` for no UI (JSON still served) |
| `openapiVersion` | `'3.1.2'` | a `3.0.x` value also switches Standard Schema output to draft-07 |
| `documentation` | `{}` | a partial OpenAPI document merged in: `info`, `servers`, `tags`, `security`, `components` |
| `exclude` | `{ methods: ['options'], staticFile: true }` | `paths` (Elysia form `/orders/:id`, or a RegExp), `methods` (replaces the default), `tags`, `staticFile` (drops any path with a `.`) |
| `references` | — | extra schemas per path, such as `fromTypes()`; they fill only slots a route did not declare |
| `mapJsonSchema` | — | `{ vendor: (schema) => JSONSchema }`; overrides the Standard JSON Schema path |
| `scalar` / `swagger` / `embedSpec` | — | UI configuration |

---

## 2. What reaches the spec from a route

| The route declares | The spec gets (verified) |
| --- | --- |
| `params`, `query`, `headers` | `parameters`, with `required` from the schema; `:id` becomes `{id}` |
| `body` | `requestBody` with three content types: JSON, urlencoded, multipart |
| `response: { 200, 404, 422 }` | exactly those three `responses` |
| `response` absent | **no `responses` key at all** — a code generator gets nothing back |
| a body schema, but no `422` in the map | **no 422**, although Elysia answers 422 to invalid input and Eden types it |
| `response: t.String()` | documented as `text/plain` |
| `body: 'Order'` (a model) | `$ref: '#/components/schemas/Order'` and one entry in `components.schemas` |
| `t.Array(t.Ref('#/components/schemas/Order'))` | an array of `$ref`s that resolve — and the response is still validated |
| `t.Array(Order)` (the schema object) | the item schema inlined (with `$id`), validated |
| `t.Array(t.Ref('Order'))` | `$ref: 'Order'` — **dangling** |
| `'Order[]'` | a type error, a dangling `$ref`, and **no response validation** |

So the rule that makes the client honest also makes the spec honest: every status a route can answer goes into its `response` map (`ELYSIA-TYPE-06`), including the `422` and the `401` a guard or a hook produces, and every declared status is really emitted (`ELYSIA-CORE-04`). Name models for code generators (`Order`, `ApiError`) — dotted names like `orders.page` are legal but some generators mangle them.

---

## 3. `detail`: per route, per guard, per instance

`detail` is the OpenAPI Operation Object plus `hide`: `summary`, `description`, `tags`, `operationId`, `security`, `deprecated`, `externalDocs`, any `x-*` (copied verbatim).

| Where | Merge behaviour (verified) |
| --- | --- |
| route `{ detail }` | the operation itself |
| `new Elysia({ prefix, detail: { tags, security } })` | a **default** for every route of the instance; a route's own keys win |
| `.guard({ detail }, (app) => …)` (callback form) | applied to the routes inside — and **the guard wins** over the route on a conflicting key (the route's `tags` and `summary` are dropped) |
| `.guard({ detail })` (chained form) | a default for the routes after it; a route's own keys win (verified) |
| any | tags are **replaced**, never concatenated |

Put module-wide `tags` and `security` on the instance constructor, and `summary`/`operationId` on each route. Avoid `detail` on callback guards whose routes have their own `detail`.

`hide: true` removes a route from the spec; it still serves.

---

## 4. `operationId` for code generators

The plugin generates `method + PascalCase(path) + By<Param>` (`getOrdersById`), and **does not guarantee uniqueness** (verified): `/users/:id` and `/users/byId` both become `getUsersById`; `/a/b` and `/aB` both become `getAB`; `.all()` gives eight methods one id; an optional param emits one path per variant, duplicating an explicit id. A generator that meets two identical ids drops one method or fails.

```ts
.get('/:id', handler, { detail: { summary: 'Get an order', operationId: 'getOrder' } })
```

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-18` | A spec that feeds a code generator **MUST** set an explicit, unique `detail.operationId` on every route — generated ids collide. *(added 2026-10-25)* |

---

## 5. Security schemes

Declare the scheme once in `documentation.components.securitySchemes`, then say which operations need it — on the module's constructor `detail` for a protected module, per route otherwise. A public route inside a protected document declares `security: []`. `documentation.security` sets a document-wide default.

```ts
const orders = new Elysia({ prefix: '/orders', detail: { tags: ['orders'], security: [{ bearerAuth: [] }] } })
const health = new Elysia().get('/health', () => ({ ok: true }), { detail: { security: [], tags: ['health'], summary: 'Liveness', operationId: 'getHealth' } })
```

The spec does not enforce anything: the auth plugin does (`Elysia - Lifecycle and Plugins` § 5). What the spec must not do is describe a protected route as public, or the reverse.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-20` | A route protected by an auth hook **MUST** declare `security` naming a scheme from `components.securitySchemes`, and a public route in a protected document **MUST** declare `security: []`. *(added 2026-10-25)* |

---

## 6. Zod, Valibot and other Standard Schema libraries

| Library | In the spec without configuration? (verified for Zod 4) |
| --- | --- |
| `t` | yes |
| **Zod 4** | **yes** — it implements Standard JSON Schema, and the plugin picks the right view: *input* for body, query and params (a field with `.default()` is optional), *output* for responses |
| Zod 3, Valibot, Effect, others without Standard JSON Schema | add `mapJsonSchema` for the vendor (`zodToJsonSchema`, `@valibot/to-json-schema`, `JSONSchema.make`) — and confirm in `/openapi/json` |

With Zod 4, **do not** pass `mapJsonSchema: { zod: z.toJSONSchema }`: it is called without an input/output hint, so request bodies get the *output* view — defaulted fields become required and `additionalProperties: false` appears, and the spec rejects requests the server accepts (verified). If something forces it, pass `(s) => z.toJSONSchema(s, { io: 'input' })`.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-07` | A route whose schema library does not expose Standard JSON Schema (Zod 3, Valibot, Effect…) **MUST** have `mapJsonSchema` configured on the OpenAPI plugin, or its schemas are missing from the spec; with Zod 4, `mapJsonSchema: { zod: z.toJSONSchema }` **NEVER** goes in without `io: 'input'`. *(revised 2026-10-25: Zod 4 is read natively)* |

---

## 7. `fromTypes()` and `withHeaders`

`openapi({ references: fromTypes('src/index.ts') })` documents routes from their TypeScript types, including routes with no schema. It **shells out to `tsc`** (verified): when `tsc` is not on `PATH` — plain `bun test` or `bun file.ts` — it produces nothing and only warns. It needs a `.ts` file that **exports** the app, reads `tsconfig.json` from `projectRoot` (pass `projectRoot`/`tsconfigPath` in a monorepo), and deletes its `tmpRoot` (`os.tmpdir()/.ElysiaAutoOpenAPI` by default). Runtime schemas take precedence over the types. It does not work on Cloudflare Workers. Prefer declaring `response`; use `fromTypes()` for a legacy app you cannot annotate yet, and check the output.

`withHeaders(schema, { 'x-rate-limit': t.Number() })` (plural — `withHeader` does not exist) documents response headers. It neither sets nor validates them: `set.headers` still has to.

---

## 8. Exposing the docs

The spec of an internal API is reconnaissance for anyone who finds it. There is no auth option on the plugin (verified). Two ways to decide it:

```ts
// 1. On only where it is meant to be served — fail closed: an unset variable means off
openapi({ enabled: env.EXPOSE_DOCS === 'true' })
// not: enabled: env.NODE_ENV !== 'production' — it serves the docs wherever NODE_ENV is unset

// 2. Served, behind auth: a global onRequest on the prefix (onRequest has request and status)
new Elysia()
  .onRequest(({ request, status }) => {
    const { pathname } = new URL(request.url)
    if (pathname.startsWith('/openapi') && request.headers.get('authorization') !== `Bearer ${env.DOCS_TOKEN}`)
      return status(401, 'unauthorized')
  })
  .use(openapi())
```

`exclude.paths` takes the Elysia form (`/orders/:id`), not `{id}`; `exclude.methods` replaces the default `['options']`. **Bug in 1.4.16:** `exclude.tags` with any route that has no `detail` makes `/openapi/json` answer 500 — use `hide` instead, or give every route a `detail`.

| ID | Rule |
| --- | --- |
| `ELYSIA-TYPE-19` | The OpenAPI plugin **MUST** be either disabled with `enabled` or protected (an `onRequest` guard on its prefix) in environments that must not publish the API's shape — the plugin has no auth of its own. *(added 2026-10-25)* |

---

## 9. A test that keeps the spec honest

Rendering is not evidence. Fetch the JSON through `app.handle` and assert what consumers depend on:

```ts
test('every operation is documented for consumers', async () => {
  const spec = await (await app.handle(new Request('http://localhost/openapi/json'))).json()
  const ops = Object.entries(spec.paths).flatMap(([path, methods]: [string, any]) =>
    Object.entries(methods).map(([m, op]: [string, any]) => ({ where: `${m.toUpperCase()} ${path}`, ...op })))
  const ids = ops.map((o) => o.operationId)
  expect(new Set(ids).size).toBe(ids.length)                          // ELYSIA-TYPE-18
  for (const op of ops) {
    expect(op.summary, op.where).toBeTruthy()
    expect(op.tags?.length, op.where).toBeGreaterThan(0)
    expect(Object.keys(op.responses ?? {}).length, op.where).toBeGreaterThan(0)
  }
  expect(spec.paths['/orders/{id}'].get.security).toEqual([{ bearerAuth: [] }])   // ELYSIA-TYPE-20
})
```

In a prefixed instance, register the collection route as `.post('', …)`: `.post('/', …)` is documented as `/orders/` with a trailing slash (verified).

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| a route with no `response` | no `responses` in the spec; a generated client returns `unknown` | declare the map — `ELYSIA-TYPE-06` |
| a 401/404/422 the route answers but does not declare | the spec lists only declared statuses; consumers do not handle the rest | declare every status — `ELYSIA-TYPE-06` |
| `response: { 201 }` with `return value` | the spec promises 201, the server sends 200 | `return status(201, …)` — `ELYSIA-CORE-04` |
| generated `operationId`s feeding a generator | collisions drop or break methods | explicit, unique ids — `ELYSIA-TYPE-18` |
| `mapJsonSchema: { zod: z.toJSONSchema }` with Zod 4 | request bodies use the output view: defaults become required | remove it, or `io: 'input'` — `ELYSIA-TYPE-07` |
| Valibot/Zod 3 routes with no `mapJsonSchema` | their schemas are missing from the spec | map the vendor — `ELYSIA-TYPE-07` |
| docs served in production by default | the API's shape is public | `enabled` per environment, or protect the prefix — `ELYSIA-TYPE-19` |
| protected routes with no `security` | the spec calls them public | `security` on the module's constructor `detail` — `ELYSIA-TYPE-20` |
| `detail` on a guard and on its routes | the guard's keys overwrite the route's | instance constructor for defaults, route for specifics |
| `exclude.tags` with routes lacking `detail` | `/openapi/json` answers 500 (1.4.16) | `hide`, or `detail` everywhere |
| `@elysiajs/swagger` | discontinued | `@elysia/openapi` — `ELYSIA-APP-07` |

## Review checklist

- [ ] Every route declares a `response` map with every status it can answer, 401/422 included? → `ELYSIA-TYPE-06`
- [ ] Every declared status is emitted with `status(code, …)`? → `ELYSIA-CORE-04`
- [ ] Explicit, unique `operationId` when a generator consumes the spec? → `ELYSIA-TYPE-18`
- [ ] Schema libraries without Standard JSON Schema mapped; Zod 4 left alone? → `ELYSIA-TYPE-07`
- [ ] The docs disabled or protected where the API's shape must not be public? → `ELYSIA-TYPE-19`
- [ ] Protected routes declare `security`; public ones in a protected document declare `[]`? → `ELYSIA-TYPE-20`
- [ ] A test fetches `/openapi/json` and asserts ids, summaries, tags, responses and security?
- [ ] `@elysia/openapi`, never `@elysiajs/swagger`? → `ELYSIA-APP-07`
