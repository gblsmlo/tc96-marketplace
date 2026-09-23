# The scope proof — the test ELYSIA-LIFE-08 requires

```bash
# does the route pass through the hook? instrument temporarily and count
# (and prefer a named function, so the span does not become anonymous)
```

```ts
// scope proof — the test ELYSIA-LIFE-08 requires
import { describe, test, expect } from 'bun:test';
import { Elysia } from 'elysia';
import { authPlugin } from './auth';

test('plugin protects a route of the CONSUMING instance', async => {
 const consumer = new Elysia.use(authPlugin).get('/private', => 'ok');
 await consumer.modules; // ELYSIA-CORE-10
 const res = await consumer.handle(new Request('http://x/private'));
 expect(res.status).toBe(401); // if it returns 200, the scope is local
});
```

This test is the most valuable probe in this skill: it tells `local` from `scoped` in a single assertion, and it is the only way to prove `ELYSIA-LIFE-01` without reading the plugin's code.

---


---

## Why this test, and not reading the plugin

`local` and `scoped` **produce the same code** inside the plugin: the difference only appears in the
instance that consumes it. A test written **inside** the plugin passes in both cases — and it is
exactly the test most projects have.

| Where the test runs | `local` scope | `scoped` scope |
| --- | --- | --- |
| inside the plugin | rejects ✓ | rejects ✓ |
| **on the consuming instance** | **passes (200)** ✗ | rejects (401) ✓ |

The bottom row is the only one that tells the two apart — and it is the one `ELYSIA-LIFE-08` requires.

## The cut: what is not lifecycle
| Symptom | It is not lifecycle — it is |
| --- | --- |
| an error reaching Eden as `unknown` | `response` without a map by status — `elysia-schema` (`ELYSIA-TYPE-06`) |
| Eden's `data` is `null` | status ≥ 300 — `ELYSIA-TYPE-08` |
| Eden's type lost routes | broken method chaining — `ELYSIA-APP-01` |
| a required header "never arrives" | a capitalized name in the schema — `ELYSIA-TYPE-03` |
| a numeric body fails validation | `body` does not coerce — `ELYSIA-TYPE-04` |
| a flaky test with an async plugin | missing `await app.modules` — `ELYSIA-CORE-10` |
| SSE drops on its own | `Bun.serve`'s `idleTimeout` — [Bun - HTTP e Servidor](../../../../knowledge-base/bun-http-e-servidor.md) |

**And the most common of all:** the hook does not run because it was registered **after** the route (`ELYSIA-CORE-01`). Before investigating scope, check the order.
