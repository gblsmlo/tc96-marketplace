---
nome: elysia-openapi
descricao: Document an Elysia API with `@elysia/openapi` so the spec matches what the server answers — plugin setup and options, `detail` per route and per module, models as components, every status in the response map, security schemes, explicit `operationId` for code generators, Zod 4 and other Standard Schema libraries, `fromTypes()`, `withHeaders`, `hide`/`exclude`, gating the docs per environment, and a test plus a linter over `/openapi/json` — citing `ELYSIA-TYPE-*` IDs. Use when the task is adding or fixing API documentation, a Swagger/Scalar page, generating a client for another language from the spec, a route missing or wrong in `/openapi/json`, protecting the docs in production, or migrating off `@elysiajs/swagger`. Do not use to declare the schemas themselves (elysia-schema), for the TypeScript client that needs no spec (elysia-eden), nor for HTTP semantics such as which status to return (http-contract).
tipo: skill
familia: elysia
idioma: en
fonte: "[Elysia - OpenAPI](../docs/elysia-openapi.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
  - openapi
---

# elysia-openapi

> **Source of this skill:** [Elysia - OpenAPI](../docs/elysia-openapi.md) — § 0 is the decision tree, and `ELYSIA-TYPE-07`, `-18`, `-19`, `-20` have their bodies there.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`, topics `openapi plugin`, `openapi patterns`, `fromTypes`, `detail`. Signatures come from there; the rule and the ID come from the family docs.

`@elysia/openapi` builds the spec from what routes *declare*, so the spec is exactly as honest as the declarations. The usual gaps are invisible in the rendered page: a 404 the handler returns but the map omits, the 422 Elysia sends on its own, generated `operationId`s that collide in a code generator, protected routes described as public, and docs served to the internet by default. This skill closes those gaps and keeps them closed with a test over `/openapi/json`.

---

## When to use

| Situation | Go to |
| --- | --- |
| `body`/`query`/`response` schemas, coercion, models | `elysia-schema` |
| a TypeScript frontend calling the API | `elysia-eden` — it needs no spec |
| the auth plugin that `security` documents | `elysia-build` |
| which status or header the protocol requires | `http-contract` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia - OpenAPI](../docs/elysia-openapi.md) | options, what reaches the spec, `detail` merging, ids, security, Zod, exposure — the one doc this skill needs |
| 2 | [Elysia - Schema and Validation](../docs/elysia-schema-and-validation.md) § 4, § 5 | only when routes need models or a `response` map they do not have yet |

**Never load the routing, lifecycle or Eden docs to document an API.**

| File | What for |
| --- | --- |
| `references/patterns.md` | shapes that passed a test: plugin setup, models, a module with default `detail`, explicit ids, public routes, docs behind a token, the spec test |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | every `ELYSIA-*` ID and where its body lives |
| `scripts/self-check.sh` | the AST scan (groups `openapi` and `schema`) |
| `scripts/spec-lint.mjs` | reads a spec JSON and lists operations without `operationId`, duplicates, missing summary/tags/responses/security |

---

## Step 1 — Mount it once, and decide exposure

`@elysia/openapi`, never `@elysiajs/swagger` (`ELYSIA-APP-07`). Configure `documentation` (`info`, `tags`, `components.securitySchemes`) once at the root. The plugin has **no auth**: gate it with `enabled` **failing closed** (`env.EXPOSE_DOCS === 'true'`, not `NODE_ENV !== 'production'`, which serves the docs wherever the variable is unset), or guard its prefix with an `onRequest` (`ELYSIA-TYPE-19`).

## Step 2 — Every status, declared and emitted

The spec lists only the statuses in a route's `response` map, and **no 422** unless declared — although Elysia sends 422 for invalid input. A route with no map has **no `responses`** at all. Declare every status the route can answer, including the 401 a hook returns and the 422 (`ELYSIA-TYPE-06`); emit each with `status(code, …)` — a raw `return` goes out as 200 (`ELYSIA-CORE-04`). Shared shapes are models (`Order`, `ApiError`), which land in `components.schemas`.

## Step 3 — `detail`: defaults on the module, specifics on the route

`new Elysia({ prefix: '/orders', detail: { tags: ['orders'], security: [{ bearerAuth: [] }] } })` is a default every route inherits, and a route's own keys win. A callback guard's `detail` (`.guard({ detail }, (app) => …)`) is the opposite — it overwrites the route's keys — so keep `detail` off callback guards whose routes have their own. Each route: `summary` and, when a generator reads the spec, an explicit unique `operationId` (`ELYSIA-TYPE-18`; generated ids collide). Protected routes carry `security`; public ones inside a protected document carry `security: []` (`ELYSIA-TYPE-20`). In a prefixed module the collection route is `''`, not `'/'`, or it is documented with a trailing slash.

## Step 4 — Schema libraries

`t` and **Zod 4** need nothing: Zod 4 is read through Standard JSON Schema, with the input view for requests. Do **not** pass `mapJsonSchema: { zod: z.toJSONSchema }` with Zod 4 — it documents request bodies in the output view (defaults required). Zod 3, Valibot, Effect: add `mapJsonSchema` for the vendor and check the result (`ELYSIA-TYPE-07`). `fromTypes()` only works with `tsc` on `PATH`; prefer declaring `response`. `withHeaders` documents headers, it does not set them.

## Step 5 — Prove it

Fetch the spec through `app.handle` in a test and assert what consumers rely on (pattern 6 in `references/patterns.md`), then lint the JSON:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-openapi/scripts/self-check.sh .
bun -e "import { app } from './src/app'; const r = await app.handle(new Request('http://localhost/openapi/json')); await Bun.write('openapi.json', await r.text())"
node ${CLAUDE_PLUGIN_ROOT}/skills/elysia-openapi/scripts/spec-lint.mjs openapi.json
bun test
```

(Adapt the import to where the app is exported; `http://localhost` — a one-label host answers 404.)

## Step 6 — Report

What the spec now documents, the lint output before and after, the exposure decision per environment, the IDs behind each change written out in full, and what you did not verify — a code generator's own quirks, or statuses produced by middleware the routes do not declare.

---

## Example

"Generate a Python client from our API." The lint finds 14 operations, 3 duplicate generated ids, 9 without a 401/422 in `responses`, and protected routes with no `security`. The modules get constructor `detail` with `tags` and `security`, each route an explicit `operationId` and a `response` map with 401/404/422, `/health` gets `security: []`, the docs get `enabled: env.EXPOSE_DOCS === 'true'` (off unless asked for), and a test asserts unique ids and declared security. Cites `ELYSIA-TYPE-06`, `ELYSIA-TYPE-18`, `ELYSIA-TYPE-19` and `ELYSIA-TYPE-20`.
