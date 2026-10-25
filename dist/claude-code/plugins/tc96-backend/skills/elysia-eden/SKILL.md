---
name: elysia-eden
description: Consumes an Elysia API from TypeScript with Eden — exporting and importing the app type, configuring `treaty` (auth headers, `parseDate`, `throwHttpError`, `onResponse`), calling routes, narrowing errors by status (422 and the untyped 503 included), wiring TanStack Query (unwrap and throw, retry only 5xx, typed mutation errors in forms), the paginated envelope, tests with `treaty(app)`, files and SSE, and fixing a client that turned `any` — citing `ELYSIA-TYPE-*` IDs, with an AST self-check and a workspace parity check. Use for a frontend or another service calling an Elysia backend, a `queryFn`/`mutationFn` over Eden, an error the UI must show per status, a query that never reaches `isError`, a list that re-renders on every refetch, or Eden types that degraded to `any`. Not for declaring the server schemas (elysia-schema), documenting the API for non-TypeScript clients (elysia-openapi), or cache policy in general (tanstack-query).
source: "[Elysia - Eden](../../docs/elysia/elysia-eden.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - frontend
  - backend
---

# elysia-eden

> **Source of this skill:** [Elysia - Eden](../../docs/elysia/elysia-eden.md) — § 0 is the decision tree, and every Eden rule (`ELYSIA-TYPE-08`–`11`, `13`–`17`) has its body there.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`, topics `eden treaty`, `eden config`, `eden response`, `eden fetch`, `eden unit test`. Signatures come from there; the rule and the ID come from the family docs.

Eden's promise is that the server's type is the client's type, with no code generation. The promise holds — and its defaults quietly work against a React app: errors resolve instead of throwing, so TanStack Query reports success on a 404; date strings become `Date` at runtime while the type still says `string`, so every refetch re-renders; a thrown error is retried even when it is a 401. This skill wires the client so the type, the runtime and the cache agree, and proves it with a forced error.

---

## When to use

| Situation | Go to |
| --- | --- |
| the server's schemas and `response` maps the client is typed from | `elysia-schema` |
| a status that should appear on the client but is thrown on the server | `elysia-build` (`ELYSIA-CORE-03`) |
| clients that are not TypeScript, or a published contract | `elysia-openapi` |
| `staleTime`, invalidation strategy, optimistic updates | `tanstack-query` |
| the React form around a mutation | `react-hook-form` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia - Eden](../../docs/elysia/elysia-eden.md) | config, the return union, the Query bridge, tests, the `any` table — the one doc this skill needs |
| 2 | [Elysia - Schema and Validation](../../docs/elysia/elysia-schema-and-validation.md) § 5 | only when the server's `response` map must change for the client to see a status |

**Never load the routing, lifecycle or OpenAPI docs for client work.**

| File | What for |
| --- | --- |
| `references/patterns.md` | shapes that passed a test: the client module, `unwrap`, narrowing, `queryOptions` with retry, a typed mutation error, pagination, both test forms |
| `references/any-and-drift.md` | when the client turns `any` or loses a route: causes, commands, the monorepo alias trap |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | every `ELYSIA-*` ID and where its body lives |
| `scripts/self-check.sh` | the AST scan (group `eden`), `strict` in every tsconfig, one `elysia` version across the workspace |

---

## Step 1 — The contract: one type, imported as a type

The server ends its chain with `export type App = typeof app` (`ELYSIA-APP-05`); the client imports it with **`import type`** (`ELYSIA-TYPE-14`). Both sides: `strict: true`, TypeScript >= 5.0, **one** `elysia` version (`ELYSIA-TYPE-11`). In a monorepo, expose the type from the server package's `exports` so the client resolves the **same file** the server compiles.

## Step 2 — One client, configured once

`parseDate: false` when the data feeds TanStack Query (`ELYSIA-TYPE-10`); credentials through `headers: () => …` (or `fetch: { credentials: 'include' }` for cookie sessions), never repeated per call; an `onResponse` that only logs returns `undefined` (`ELYSIA-TYPE-17`). Pick **one** error policy for the whole client: results you check (the default), or `throwHttpError: true`.

## Step 3 — Read the result by status

`data` is `null` for every status >= 300, redirects included (`ELYSIA-TYPE-08`). The error is a union by status with `value` typed per status — and it includes `422` for any route with a schema or a path param. At runtime it is an `EdenFetchError` whose `message` is `"[object Object]"`: narrow on `error.status`, read `error.value`, never `instanceof` or `.message` (`ELYSIA-TYPE-15`). A status missing from the union is a server problem: absent from the `response` map and thrown rather than returned (`ELYSIA-TYPE-06`, `ELYSIA-CORE-03`).

## Step 4 — TanStack Query

Unwrap once — `if (error) throw error; return data` — in every `queryFn`/`mutationFn` (`ELYSIA-TYPE-09`); otherwise a 404 is a `success`. Once thrown, 4xx are retried by default: `retry: (n, e) => e.status >= 500 && n < 3` (`ELYSIA-TYPE-16`). Type a mutation's error with `Treaty.Error<typeof api.orders.post>` so `create.error.status === 409` narrows `value` for the form. Lists answer `{ items, total, hasMore }` (`ELYSIA-TYPE-13`). The `queryKey` is yours, not Eden's.

## Step 5 — Prove it

Force the failure the UI depends on: a 404 must end in `isError` without a retry, a 409 must reach the form with its typed body. Tests use `treaty(app)` (server-side, no network) or the production client with a `fetcher` that calls `app.handle(new Request(input, init))` — origin `http://localhost`, since a one-label host answers 404.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-eden/scripts/self-check.sh .
bunx tsc --noEmit        # in the server AND the client package — the only contract check Eden has
bun test
```

## Step 6 — Report

The client config and why, each error status the UI handles, every rule ID written out in full (`ELYSIA-TYPE-09`, never `-09`), the test that forces a failure and its result, the IDs behind each choice, and what you did not verify — a client package on another `elysia` version shows up only at its next upgrade.

---

## Example

"The order screen shows a blank card when the order does not exist, and the list flickers on every refetch." The `queryFn` returned Eden's result (a 404 was a `success` with `data: null`) and the client kept `parseDate` on. The fix: `parseDate: false`, `queryFn: ({ signal }) => unwrap(api.orders({ id }).get({ fetch: { signal } }))`, `retry: (n, e) => e.status >= 500 && n < 3`, and the component switches on `error.status` (404 → not found, 422 → invalid id). A test asserts the 404 ends in `isError` after one call. Cites `ELYSIA-TYPE-09`, `ELYSIA-TYPE-10`, `ELYSIA-TYPE-15` and `ELYSIA-TYPE-16`.
