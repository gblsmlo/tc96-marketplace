# The instance and the handler

> Steps 0 to 2. The text of the rules lives in [Elysia](../../../../knowledge-base/elysia.md) § 6 and [Elysia - Roteamento e Handler](../../../../knowledge-base/elysia-roteamento-e-handler.md).

---

## Two things that date the code

**1. `error` no longer exists.** The current name is **`status`**, and `error` was removed in 1.4
(`ELYSIA-APP-02`). Examples using `error` still circulate in the official docs — new code uses `status`.

**2. Two npm scopes coexist.** `@elysia/*` is the current one; `@elysiajs/*` is legacy. And
`@elysiajs/swagger` is **discontinued** — use `@elysia/openapi` (`ELYSIA-APP-07`).

---

## The instance

```ts
// ✓ continuous method chaining — ELYSIA-APP-01
const app = new Elysia
.use(auth)
.get('/invoices', => list)
.post('/invoices', ({ body }) => create(body));

export type App = typeof app; // exported as a TYPE — ELYSIA-APP-05
```

| Rule | What it requires |
| --- | --- |
| `ELYSIA-APP-01` | **continuous** method chaining — assigning and calling in a separate statement loses the accumulated type |
| `ELYSIA-APP-05` | the instance for Eden is exported **as a type**, from the module where the chain ends |
| `ELYSIA-APP-04` | `strict: true` and TypeScript ≥ 5.0 on the server **and** in every Eden client |

**`ELYSIA-APP-01` produces the most confusing bug:** the chain is what builds the type.
Breaking it into statements makes the type stop accumulating, and the client's Eden **loses the routes**
— with no error on the server.

`ELYSIA-APP-09`: application code **never** reads `process.env` directly — use the `env` export
from `elysia`. And a secret is never a literal (`ELYSIA-APP-08`).

---

## The handler

```ts
// ✓ destructures what it uses — ELYSIA-CORE-02
.post('/invoices', ({ body, status, cookie, set }) => { /* … */ })

// ✗ takes the whole Context, or is an annotated external function
.post('/invoices', createInvoice) // ELYSIA-CORE-02 (alias: ELYSIA-APP-03)
```

This is not style: Elysia's context is built **by type** from what the route declares,
and an external function annotated with a generic `Context` erases the inference the schema produced.

`ELYSIA-APP-06`: code using `context.server`, `Bun.*` or an inline value in a route declares Bun
as the target runtime — none of the three is portable.

---

## Related

- [Elysia - Roteamento e Handler](../../../../knowledge-base/elysia-roteamento-e-handler.md) — the source
- `erro-cookie-e-teste.md` — the next step
- `mapa-de-ids.md` — where each `ELYSIA-*` has its body
