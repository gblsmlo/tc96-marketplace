# Antipatterns, with IDs

> Check the ID in `mapa-de-ids.md` before citing. Two aliases are **partial**:
> `ELYSIA-APP-03` only in the destructuring clause, `ELYSIA-TYPE-11` only in the `strict` one.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Breaking the method chaining into statements | `ELYSIA-APP-01` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Using `error` from the context (removed in 1.4) | `ELYSIA-APP-02` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Handler as an external function annotated with `Context` | `ELYSIA-CORE-02` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `strict: false` or TS < 5.0 on either side of Eden | `ELYSIA-APP-04` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Exporting the instance as a value, not as a type | `ELYSIA-APP-05` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| `@elysiajs/swagger` in new code | `ELYSIA-APP-07` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Literal secret in `jwt.secret`/`cookie.secrets` | `ELYSIA-APP-08` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| `process.env` read directly in the application | `ELYSIA-APP-09` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Hook, plugin or `onError` registered after the routes | `ELYSIA-CORE-01` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `throw` for an expected error that must arrive typed | `ELYSIA-CORE-03` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `set.status` where there is a `response` schema | `ELYSIA-CORE-04` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Session cookie without a signature or without `httpOnly` | `ELYSIA-CORE-05` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Changing `set.headers` after the first `yield` | `ELYSIA-CORE-06` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `onError` returning `error.message` from `UNKNOWN` | `ELYSIA-CORE-07` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Domain error without `.error({...})` | `ELYSIA-CORE-08` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Test starting a server and requesting over the network | `ELYSIA-CORE-09` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Assertion before `await app.modules` | `ELYSIA-CORE-10` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |

