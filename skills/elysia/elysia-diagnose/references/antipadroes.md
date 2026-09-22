# Antipatterns, with IDs

> Check `mapa-de-ids.md`. `ELYSIA-LIFE-10` is the application of `ELYSIA-CORE-03` inside a `macro` — cite the canonical one when talking about the principle, and `LIFE-10` when talking about the macro.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Hook, plugin or `onError` registered after the routes | `ELYSIA-CORE-01` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Plugin hook without a declared scope | `ELYSIA-LIFE-01` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| `derive` for an auth or authorization decision | `ELYSIA-LIFE-02` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| Plugin without a `name` applied by more than one instance | `ELYSIA-LIFE-03` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| `onRequest` reading `body`/`query`/`params`/`cookie` | `ELYSIA-LIFE-04` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| Mutating a `decorate` value | `ELYSIA-LIFE-05` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| `store` primitive destructured in the parameter | `ELYSIA-LIFE-06` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| Plugin as an `(app) => app` callback | `ELYSIA-LIFE-07` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| Testing auth only inside the plugin | `ELYSIA-LIFE-08` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| A chain of `scoped` where `global` would fit | `ELYSIA-LIFE-09` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| `throw` inside a macro | `ELYSIA-LIFE-10` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| Hook as an anonymous arrow under OpenTelemetry | `ELYSIA-LIFE-11` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| `cors` with the default `origin` in an authenticated API | `ELYSIA-LIFE-12` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) |
| Assertion before `await app.modules` | `ELYSIA-CORE-10` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |

