# Antipatterns — routes and handlers

> Check the ID in `id-map.md` before citing. Two aliases are partial: `ELYSIA-APP-03` only for the destructuring clause (canonical `ELYSIA-CORE-02`), `ELYSIA-TYPE-11` only for `strict` (canonical `ELYSIA-APP-04`).

| Antipattern | What happens | ID | Doc |
| --- | --- | --- | --- |
| `const app = new Elysia(); app.get(...)` | runs, but `typeof app` and Eden never see the route | `ELYSIA-APP-01` | [Elysia](../../docs/elysia.md) § 6 |
| `error(...)` from the context or from `elysia` | removed in 1.4; it is `status` | `ELYSIA-APP-02` | [Elysia](../../docs/elysia.md) § 3 |
| exporting the instance without `export type App = typeof app` | Eden has nothing to import | `ELYSIA-APP-05` | [Elysia](../../docs/elysia.md) § 6 |
| `@elysiajs/swagger` in new code | discontinued | `ELYSIA-APP-07` | [Elysia](../../docs/elysia.md) § 3 |
| literal `secret`/`secrets`; raw `process.env` | secret in the repo; code tied to `process` | `ELYSIA-APP-08`, `-09` | [Elysia](../../docs/elysia.md) § 6 |
| `onError`, a hook or `.use()` after the routes | does not apply to the routes above it | `ELYSIA-CORE-01` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 2 |
| a handler that takes the whole `Context` | erases the inference the schema produced | `ELYSIA-CORE-02` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 1 |
| `throw status(404)` for an error the client must see typed | leaves the route's type; reaches `onError` as `code === 404` | `ELYSIA-CORE-03` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 5 |
| `set.status = 422` with a `response` schema; `return x` with only `201` declared | not checked against the schema; the raw return goes out as 200 | `ELYSIA-CORE-04` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 4 |
| a session cookie without `sign` or without `httpOnly` | forgeable, or readable by scripts | `ELYSIA-CORE-05` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 4 |
| `set.headers` after the first `yield` | silently ignored | `ELYSIA-CORE-06` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 4 |
| no `onError`, or one that returns `error.message` | the raw message (paths, hosts, SQL) is the 500 body, also in production | `ELYSIA-CORE-07` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 5 |
| a catch-all `onError` first in the app that answers every code | swallows the codes the modules registered | `ELYSIA-CORE-07`, `-08` | `patterns.md` § 2 |
| matching `error.message` in `onError` instead of a registered code | no narrowing, breaks on a reworded message | `ELYSIA-CORE-08` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 5 |
| `listen()` + `fetch()` in a test; `http://x/...` as the test URL | slow and flaky; a one-label host answers 404 | `ELYSIA-CORE-09` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 6 |
| asserting before `await app.modules` with a lazy or async plugin | the route is missing — for an async function plugin, for good | `ELYSIA-CORE-10` | [Routing and Handler](../../docs/elysia-routing-and-handler.md) § 6 |
| an auth hook in a plugin with no `as` | the consumer's routes are open | `ELYSIA-LIFE-01` | [Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) § 5 |
| `as: 'scoped'` expected to cross two `.use()` levels | stops at the first parent | `ELYSIA-LIFE-01`, `-09` | [Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) § 5 |
| `derive` to read the session; `throw` in a macro to deny | runs before validation; a 500 instead of 401/403 | `ELYSIA-LIFE-02`, `-10` | [Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) § 3, § 6 |
