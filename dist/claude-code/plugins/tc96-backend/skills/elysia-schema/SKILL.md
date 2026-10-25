---
name: elysia-schema
description: Declare and fix Elysia request and response schemas — `t` (TypeBox) or Zod/Valibot through Standard Schema, coercion by source, `response` as a map by status, a standalone `guard`, reference models, `normalize`, upload validation with `fileType`, and the 422 validation error — citing `ELYSIA-TYPE-*` IDs, with an AST self-check. Use when the task is validating a body, query string, params, headers, cookie or upload, typing what a route returns per status, sharing a schema between routes, a field that "is never sent" or a number that fails validation, or a field that silently disappears from a response. Do not use for the route and handler themselves (elysia-build), the Eden client (elysia-eden), the documentation output (elysia-openapi), nor a Drizzle table's schema (drizzle-zod).
fonte: "[Elysia - Schema and Validation](../../docs/elysia/elysia-schema-and-validation.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-schema

> **Source of this skill:** [Elysia - Schema and Validation](../../docs/elysia/elysia-schema-and-validation.md) — every `ELYSIA-TYPE-01`–`06` and `-12` rule has its body there.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`, topics `validation`, `typebox`, `standard schema`, `reference model`. Signatures come from there; the rule and the ID come from the family docs.

One schema declaration in Elysia does four jobs at once: it validates at runtime, types the handler, documents the route in OpenAPI and types the Eden client. A wrong declaration is therefore wrong four times, and most of the ways it goes wrong pass the build: a capitalised header that never matches, a guard silently replaced by the route's schema, a status the client cannot see. This skill decides each declaration on purpose and proves the edge cases with a request.

---

## When to use

| Situation | Go to |
| --- | --- |
| the route, the handler, errors, cookies, tests | `elysia-build` |
| the client: `treaty`, TanStack Query, typed errors on the frontend | `elysia-eden` |
| `/openapi`, tags, security, Zod in the spec | `elysia-openapi` |
| a schema generated from a Drizzle table | `drizzle-zod` |
| which status code the protocol calls for | `http-contract` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia - Schema and Validation](../../docs/elysia/elysia-schema-and-validation.md) | coercion, guard, models, response map, validation error — the one doc this skill needs |
| 2 | [Elysia](../../docs/elysia/elysia.md) § 4 (`t` table) | only when you need a type Elysia adds to TypeBox (`t.Numeric`, `t.File`, `t.Cookie`, `t.UnionEnum`…) |

**Never load the routing, lifecycle, Eden or OpenAPI docs to write a schema.**

| File | What for |
| --- | --- |
| `references/patterns.md` | six shapes that passed a test: derived type, coercing query, models + envelope, standalone guard, Zod upload with `fileType`, a central validation handler |
| `references/decisions.md` | coercion by source, `t` × Zod, guard precedence, what 422 contains — the tables to decide with |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | every `ELYSIA-*` ID and where its body lives |
| `scripts/self-check.sh` | the AST scan, group `schema` |

---

## Step 1 — Where each value comes from decides its type

- `params`, `query`, `headers`, `cookie` arrive as strings and **coerce**: `t.Number()` there accepts `"2"`. A JSON `body` does **not** coerce `t.Number()` (`ELYSIA-TYPE-04`) — but `t.Integer()` does, so do not use one as evidence for the other. A `t.Number` nested inside a query `t.Object` does not coerce either.
- Header names are **lowercase** in the schema (`ELYSIA-TYPE-03`); `Authorization` never matches.
- The handler's type comes from the schema; any type you need elsewhere is `typeof Schema.static`, never a hand-written interface (`ELYSIA-TYPE-01`).
- `t` at the HTTP edge (coercion, `t.File`, `t.Cookie`, OpenAPI without setup); Zod where the schema is shared with the frontend — and then `fileType()` for uploads (`ELYSIA-TYPE-02`) and `mapJsonSchema` for the spec (`elysia-openapi`).

## Step 2 — Declare every status the route can answer

A route that can answer more than one status declares `response` **as a map by status** (`ELYSIA-TYPE-06`); otherwise the client sees its errors as `unknown`. Each declared status must really be emitted with `status(code, value)`: a plain `return` goes out as 200 and is validated only against a declared 200. A paginated listing answers an envelope `{ items, total, hasMore }` (`ELYSIA-TYPE-13`).

`normalize` is on by default: properties not in the schema are **dropped** from input and output — the reason a field "disappears" from a response, and the reason mass assignment does not pass. With `normalize: false` they become 422.

## Step 3 — Compose without losing a schema

- A flat `.guard({ body })` followed by a route with its own `body` is **replaced** by the route's. Add `schema: 'standalone'` when both must hold (`ELYSIA-TYPE-05`). The callback form `.guard({ ... }, (app) => ...)` already enforces both.
- Shared shapes go into `.model({ 'orders.order': ... })` and are referenced by name — one `$ref` in the spec instead of a copy per route. Prefix names by module; a duplicate name throws.

## Step 4 — The validation error

422 is the default, with no `onError`. A per-field `error: '...'` in the schema replaces the whole 422 body with that bare string — sent as JSON, not valid JSON — so pair field messages with a central `VALIDATION` handler that answers JSON and keeps the input out (`references/patterns.md` pattern 6). With an async Zod refine, `error.all` is empty. In production the detail is trimmed but the body still echoes the raw input in `found`; `allowUnsafeValidationDetails: true` publishes the whole schema shape and is never on in production (`ELYSIA-TYPE-12`). A required `body` on a GET is silently skipped.

## Step 5 — Prove it

Send the requests that the schema is supposed to stop, through `app.handle(new Request('http://localhost/...'))`: the string number in the body, the missing lowercase header, the extra field, the forged upload.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-schema/scripts/self-check.sh .
bunx tsc --noEmit
bun test
```

## Step 6 — Report

Each schema you declared, the requests you sent with their status, the IDs behind each choice written out in full, and what you did not verify — for instance a client package on a different `elysia` version, which only shows up in Eden (`elysia-eden`).

---

## Example

"`GET /orders?page=2` always returns page 1, and `POST /orders` accepts `quantity: "3"` from one client but not another." The query declares `page: t.Number({ minimum: 1, default: 1 })` (it coerces); the body keeps `t.Number()` and the client that sends a string is the bug (`ELYSIA-TYPE-04`); the route gets `response: { 200: 'orders.page', 422: ... }` with an envelope, and a test sends `quantity: "3"` expecting 422. Cites `ELYSIA-TYPE-04`, `ELYSIA-TYPE-06` and `ELYSIA-TYPE-13`.
