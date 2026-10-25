---
name: elysia-build
description: Write Elysia routes, handlers and feature modules — the instance chain, destructured context, `return status(...)` for expected errors, `.error()` codes and a narrow `onError`, signed `httpOnly` session cookies, SSE, auth plugins with a declared scope, and tests through `app.handle` — citing `ELYSIA-APP-*`, `ELYSIA-CORE-*` and `ELYSIA-LIFE-*` IDs, with an AST self-check. Use when the task is creating or changing an Elysia endpoint or module, returning an error the client must see typed, adding a session or an auth guard, streaming, or testing a route without a server. Do not use for request/response schemas and coercion (elysia-schema), the typed client (elysia-eden), the API documentation (elysia-openapi), a hook that does not run (elysia-diagnose), nor for which status or header the protocol requires (http-contract).
fonte: "[Elysia - Routing and Handler](../../docs/elysia/elysia-routing-and-handler.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-build

> **Source of this skill:** [Elysia - Routing and Handler](../../docs/elysia/elysia-routing-and-handler.md) — § 0 is the error tree, and every `ELYSIA-CORE-*` rule has its body there. Plugins and auth: [Elysia - Lifecycle and Plugins](../../docs/elysia/elysia-lifecycle-and-plugins.md).
> **API surface:** resolve it through Context7 — `/websites/elysiajs`, topics `route`, `handler`, `error handling`, `cookie`, `plugin`, `unit test`. Signatures come from there; the rule and the ID come from the family docs.

Elysia's type is built by the chain itself: every `.get()`, `.use()` and `.error()` returns a new type, and that type is what the handler, the schema and the Eden client see. Most Elysia bugs are therefore silent — a hook registered one line too late, an error thrown instead of returned, a chain split into statements — and the code still compiles and runs. This skill writes the shape that keeps the type and the behaviour honest, then proves it with a test.

---

## When to use

| Situation | Go to |
| --- | --- |
| `body`/`query`/`params` schemas, coercion, `response` map, `guard`, models | `elysia-schema` |
| the frontend client: `treaty`, TanStack Query, typed errors on the client | `elysia-eden` |
| `/openapi`, tags, security schemes, Zod in the spec | `elysia-openapi` |
| a hook or plugin that does not run for a route | `elysia-diagnose` |
| which status, `Location`, idempotency, error body | `http-contract` |
| the persistence the handler calls | `drizzle-query` · `drizzle-mutation` |
| the test runner itself (`bunfig.toml`, mocks) | `bun-test-build` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia - Routing and Handler](../../docs/elysia/elysia-routing-and-handler.md) | the error tree (§ 0), context, responses, errors, cookies, SSE, tests — the one doc this skill needs |
| 2 | [Elysia - Lifecycle and Plugins](../../docs/elysia/elysia-lifecycle-and-plugins.md) § 0, § 3, § 5, § 6 | only when the task writes a plugin, a hook, `derive`/`resolve`, a macro or auth |
| 3 | [Elysia](../../docs/elysia/elysia.md) § 3, § 6 | only when you need the import map, the runtime limits, or an `ELYSIA-APP-*` rule's text |

**Never load the schema, Eden or OpenAPI docs to write a route.**

| File | What for |
| --- | --- |
| `references/patterns.md` | five shapes that passed a test: feature module, app-level `onError`, signed session, SSE, lazy module — plus the scoped auth plugin |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | every `ELYSIA-*` ID and where its body lives |
| `scripts/self-check.sh` | the AST scan, groups `route` and `lifecycle` |

---

## Step 0 — Two things that date the code

1. **`error` is gone; it is `status`** (`ELYSIA-APP-02`), as an export and on the context. Examples with `error(...)` still circulate.
2. **`@elysia/*` is the current npm scope**; `@elysiajs/*` is the legacy one, and `@elysiajs/swagger` is discontinued (`ELYSIA-APP-07`).

Check the installed line before writing: `grep -E '"(elysia|@elysia/[a-z-]+)"' package.json`.

---

## Step 1 — The chain is the type

- **One unbroken chain per instance** (`ELYSIA-APP-01`). `const app = new Elysia(); app.get(...)` runs, but `typeof app` never sees the route — and neither does Eden.
- **A feature is an instance with a prefix**, composed with `.use()`; the root ends with `export type App = typeof app` (`ELYSIA-APP-05`).
- **Order is application order** (`ELYSIA-CORE-01`): a hook, `.use()` or `onError` reaches only the routes registered after it. Put them first. `onRequest` is the exception — it is global.
- **Destructure the context inline** (`ELYSIA-CORE-02`); pass values, not the context, to a service.

## Step 2 — Errors: decide with § 0 of the doc

- **Expected and part of the contract → `return status(code, body)`** (`ELYSIA-CORE-03`), declared in the route's `response` map, so the client sees that status typed. A thrown status skips the type.
- **A recurring domain failure → a class registered with `.error({ CODE: Class })`** (`ELYSIA-CORE-08`); `status = 409` on the class is its default, `onError` narrows by `code`.
- **Unexpected → let it throw.** The app-level `onError` logs and answers generically, never `error.message` (`ELYSIA-CORE-07`). Registered first, it runs first for every module below it, so it must answer only `UNKNOWN`/`INTERNAL_SERVER_ERROR` and return nothing for codes a module owns — otherwise it swallows them (verified, `references/patterns.md` pattern 2).
- Validation failures are **422** by default, with no `onError` at all.

## Step 3 — Cookies, streaming, secrets

- A session cookie is **signed** (`cookie: { secrets, sign: ['session'] }`) **and `httpOnly`** (`ELYSIA-CORE-05`); a tampered one is rejected with 400.
- In a generator handler, every `set.headers` goes **before the first `yield`** (`ELYSIA-CORE-06`).
- Secrets come from `env` (from `elysia`), never literals or raw `process.env` (`ELYSIA-APP-08`, `ELYSIA-APP-09`).

## Step 4 — Auth and plugins (load doc 2)

An auth plugin's hook is **`local` by default and does not reach the routes of the instance that `.use()`s it** (`ELYSIA-LIFE-01`). Use `resolve({ as: 'scoped' }, ...)` returning `status(401, ...)`, or a macro route by route — never `derive` for an access decision (`ELYSIA-LIFE-02`), never `throw` to deny (it becomes 500, `ELYSIA-LIFE-10`). A plugin used by more than one instance has a `name` (`ELYSIA-LIFE-03`). Validation runs before `resolve`, so an anonymous request with a bad body gets 422, not 401 — add a credential-presence check in `onRequest` when 401 must come first.

## Step 5 — Prove it

Test through `app.handle(new Request('http://localhost/...'))`, never a server on a port (`ELYSIA-CORE-09`); `await app.modules` first when a plugin is lazy or async (`ELYSIA-CORE-10`). Use a real host such as `localhost`: a one-label host like `http://x/path` returns 404 in Elysia 1.4.30. For an auth plugin, the test that counts hits a route of the **consuming** instance without credentials and expects 401 (`ELYSIA-LIFE-08`).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-build/scripts/self-check.sh .
bunx tsc --noEmit        # Bun runs TypeScript without type-checking
bun test
```

`high` findings are the defect; `candidate` ones need reading.

## Step 6 — Report

What the route does now, each status it can answer, the IDs behind each decision written out in full (`ELYSIA-CORE-03`, never `-03`), the commands you ran with their output, and what you did not verify — the unexpected-error path is rarely exercised, and protocol choices (which status, `Retry-After`) belong to `http-contract`.

---

## Example

"Add order creation with a stock check and a lookup by id." The module gets `prefix: '/orders'`, registers `.error({ OUT_OF_STOCK })` and its `onError` before the routes, returns `status(404, …)` from the lookup and `status(201, order)` from the creation, declares both in `response` maps, and the app-level `onError` answers only unknown errors. Tests through `app.handle` assert 201, 404, 409 and 422. Cites `ELYSIA-CORE-01`, `ELYSIA-CORE-03`, `ELYSIA-CORE-04`, `ELYSIA-CORE-07` and `ELYSIA-CORE-08`.
