# Errors, cookies, streaming and testing

> Steps 3 to 5.

---

## Errors — the most consequential decision in the skill

```
Is the error EXPECTED (validation, business 404, limit)?
├── YES → return status(code, body) ELYSIA-CORE-03
│ (the type reaches Eden typed)
└── NO — it is unexpected
 └── throw → lands in onError
 └── and onError NEVER returns error.message from UNKNOWN
 ELYSIA-CORE-07
```

| Rule | What it requires |
| --- | --- |
| `ELYSIA-CORE-03` | an expected error is `return status(...)`, **not `throw`**, when the type has to reach Eden |
| `ELYSIA-CORE-04` | `status(code, value)` instead of `set.status` whenever the route declares a `response` schema |
| `ELYSIA-CORE-07` | `onError` **never** returns `error.message` from an `UNKNOWN` error |
| `ELYSIA-CORE-08` | a recurring domain error is registered in `.error({...})`, so it has its own `code` and narrowing |

**Why `throw` loses the type:** a `throw` leaves through `onError`, which is a path **outside the
route's type** — so Eden does not know that status exists. `return status(...)` goes into
the type. It is the same principle `ELYSIA-LIFE-10` applies inside a `macro`.

**`ELYSIA-CORE-07` is a security finding**, not a style one: `error.message` from an unknown
error leaks file paths, queries and table names.

---

## Cookies and streaming

A session cookie is **signed and `httpOnly`** (`ELYSIA-CORE-05`):

```ts
new Elysia({ cookie: { secrets: env.COOKIE_SECRET, sign: ['session'] } })
.get('/me', ({ cookie: { session } }) => {
 session.value = { id };
 session.httpOnly = true;
 session.secure = true;
 session.sameSite = 'lax';
 });
```

The semantics of `SameSite`, `Domain` and the prefixes come from `Docs/RFC 6265 - Cookies HTTP.md` —
Elysia is the mechanism, not the criterion.

**Streaming:** `ELYSIA-CORE-06` — `set.headers` is **never** changed after the first `yield`
of a generator handler. The change is **silently ignored**.

> **The trap that comes from the runtime, not the framework:** `Bun.serve`'s 10 s `idleTimeout`
> **counts during the response**, not only before it — it is the cause of SSE that drops on its own.
> See [Bun - HTTP e Servidor](../../../../knowledge-base/docs/bun-http-e-servidor.md).

---

## Testing

| Rule | What it requires |
| --- | --- |
| `ELYSIA-CORE-09` | a route test uses `app.fetch`/`app.handle` — **never** start a server and request over the network |
| `ELYSIA-CORE-10` | an app with an async plugin or a lazy `import` **awaits `app.modules`** before the assertions |

```ts
test('creates an invoice', async => {
 await app.modules; // ELYSIA-CORE-10
 const res = await app.handle(new Request('http://localhost/invoices', {
 method: 'POST',
 headers: { 'content-type': 'application/json' },
 body: JSON.stringify({ amount: 100 }),
 }));
 expect(res.status).toBe(201);
});
```

**`ELYSIA-CORE-10` produces a classic flake:** without `await app.modules`, the test runs before
the plugin registers the route, and the result depends on timing. See `bun-test-build`.

---

## Related

- [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) · [Elysia](../../../../knowledge-base/docs/elysia.md) § 5 — the error tree
- `http-contract` — which status to return is a protocol decision, not a framework one
