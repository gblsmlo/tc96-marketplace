# Antipatterns — lifecycle and plugins

| Antipattern | What happens | ID | Doc section |
| --- | --- | --- | --- |
| a hook, guard or `onError` after the routes | does not apply to them | `ELYSIA-CORE-01` | [Routing and Handler](../../../docs/elysia/elysia-routing-and-handler.md) § 2 |
| an auth hook in a plugin with no scope | the consumer's routes are open | `ELYSIA-LIFE-01` | § 5 |
| `as: 'scoped'` expected to cross two `.use()` levels | stops at the first parent | `ELYSIA-LIFE-01`, `-09` | § 5 |
| `derive` deciding access | runs before validation | `ELYSIA-LIFE-02` | § 3 |
| an unnamed plugin used by several instances | global hooks run once per use | `ELYSIA-LIFE-03` | § 4 |
| `onRequest` reading `body`, `query`, `params`, `cookie` or `headers` | none exist in the PreContext | `ELYSIA-LIFE-04` | § 2 |
| mutating a `decorate` value | shared across requests | `ELYSIA-LIFE-05` | § 3 |
| `({ store: { counter } })` in a handler that also writes it | a snapshot, stale after the write | `ELYSIA-LIFE-06` | § 3 |
| a plugin as an `(app) => app` callback | scope and dedup work on instances | `ELYSIA-LIFE-07` | § 4 |
| testing auth only inside the plugin | passes with the scope defect | `ELYSIA-LIFE-08` | § 5 |
| a chain of `as('scoped')` for tracing or CORS | use `global` | `ELYSIA-LIFE-09` | § 5 |
| `throw` in a macro or hook to deny | 500 instead of 401/403 | `ELYSIA-LIFE-10` | § 6 |
| anonymous hooks with OpenTelemetry | spans named `anonymous` | `ELYSIA-LIFE-11` | § 8 |
| `cors()` with the default origin | any origin, with credentials | `ELYSIA-LIFE-12` | § 8 |
| an app-level catch-all `onError` that answers every code | swallows the codes modules registered | `ELYSIA-CORE-07`, `-08` | [Routing and Handler](../../../docs/elysia/elysia-routing-and-handler.md) § 5 |
| an async plugin function, requests before it resolves | its route stays 404 for good | `ELYSIA-CORE-10` | [Routing and Handler](../../../docs/elysia/elysia-routing-and-handler.md) § 6 |

Sections refer to [Elysia - Lifecycle and Plugins](../../../docs/elysia/elysia-lifecycle-and-plugins.md) unless named.
