# Decisions — the tables to choose with

Verified on elysia 1.4.30. The doc is [Elysia - Schema and Validation](../../../docs/elysia/elysia-schema-and-validation.md).

## Does a string become a number?

| Where | `t.Number()` with `"2"` | Notes |
| --- | --- | --- |
| `params`, `query`, `headers`, `cookie` | **coerced** to 2 | `t.Boolean()` coerces `"true"` the same way |
| a `t.Object` nested inside `query` | **not coerced** — 422 | keep query schemas flat |
| JSON `body` | **422** | `ELYSIA-TYPE-04` |
| JSON `body`, `t.Integer()` | **coerced** to 2 | the exception; do not generalise from it |

## `t` or Zod at the boundary?

| | `t` | Zod (Standard Schema) |
| --- | --- | --- |
| query/params coercion | automatic | `z.coerce.number()` by hand |
| upload | `t.File({ type })` checks the bytes | `z.file()` checks the declared type: add `fileType()` (`ELYSIA-TYPE-02`) |
| OpenAPI | no setup | Zod 4: no setup either (Standard JSON Schema); passing `mapJsonSchema: { zod: z.toJSONSchema }` documents bodies in the output view. Zod 3: needs `mapJsonSchema` (`ELYSIA-TYPE-07`) |
| shared with a React form | type travels through Eden | the schema itself is importable on both sides |

Both can live in the same route. Never declare the same shape in both.

## Which schema wins?

| Setup | Result |
| --- | --- |
| flat `.guard({ body: A })`, then a route with `body: B` | **B only** — A is replaced (`ELYSIA-TYPE-05`) |
| flat `.guard({ schema: 'standalone', body: A })`, route `body: B` | A **and** B |
| callback `.guard({ body: A }, (app) => app.post(..., { body: B }))` | A **and** B, always |
| two global guards on the same key | the later one |
| global and local | the local one |

## What a response schema does

| Handler | Declared | Sent |
| --- | --- | --- |
| `return value` | `response: { 201: X }` only | **200**, not validated |
| `return status(201, value)` | `201: X` | 201, validated |
| returns a shape that breaks the 200 schema | `200: X` | **422**, `on: 'response'` |
| returns extra properties | any | dropped (`normalize: true`, the default); with `normalize: false`, 422 "Unexpected property" |

## What the 422 says

| Environment | Body |
| --- | --- |
| development | type, `on`, property path, message, expected schema, `found` |
| `NODE_ENV=production` | trimmed detail — but `found` (the raw input) is still there |
| `allowUnsafeValidationDetails: true` | the full schema shape, in every environment — never in production (`ELYSIA-TYPE-12`) |
| a per-field `error: '...'` and no central handler | **that bare string**, sent as `application/json` but not valid JSON — add patterns.md § 6 |

A mismatch on a declared MIME type is `VALIDATION` 422; `INVALID_FILE_TYPE` 422 comes only from the content check.
