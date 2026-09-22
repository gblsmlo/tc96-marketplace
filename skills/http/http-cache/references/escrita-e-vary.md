# Concurrent writes and Vary

This step is the least known and the one that prevents silent data loss.

```
Can more than one client edit this resource?
├── NO → nothing to do
└── YES → the write route MUST accept If-Match and answer 412
 when the ETag does not match (HTTP-CACHE-08)
```

```
PUT /invoices/42 If-Match: "v7"
├── current ETag is "v7" → 200, applies
└── current ETag is "v9" → 412 Precondition Failed
 (someone else edited; the client re-reads and decides)
```

Without it, the default is **last-write-wins**: whoever saved later erases the change of whoever saved earlier, and nobody is told.

**The `ETag` used in `If-Match` has to be strong** — without the `W/` prefix (`HTTP-CACHE-09`). A weak `ETag` declares semantic equivalence, not byte identity, and does not serve to decide whether there was a concurrent write.

> **Bridge with the client:** the `412` is an **expected error**, not an exception — it is UI state ("someone edited; reload?"), not a case for an Error Boundary. See `REACT-ASYNC-09` in [React - Suspense e Assincronia](../../../../knowledge-base/docs/react-suspense-e-assincronia.md) and the optimistic update in [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md), which needs a rollback when the `412` arrives.

---

## Step 4 — `Vary`

**A response whose body depends on a request header declares that header in `Vary`** (`HTTP-CACHE-10`). Without it, the shared cache serves the wrong representation to another client — and the symptom is "works for me, breaks for my colleague".

The cases that show up in this stack:

| The body varies by… | `Vary` | Specific rule |
| --- | --- | --- |
| `Accept` | `Vary: Accept` | `HTTP-CORE-04` |
| `Accept-Encoding` (compressed response) | `Vary: Accept-Encoding` | `HTTP-NEG-01` |
| `Accept-Language` | `Vary: Accept-Language` | `HTTP-CORE-04` |
| `Origin` (CORS with a dynamic origin) | `Vary: Origin` — **including when the origin is refused** | `HTTP-CORS-03` |

**And what `Vary` does not solve:** `Vary: Cookie` or `Vary: User-Agent` to protect personalized content **does not work** — the cardinality is too high and the cache ends up useless or leaking. The correct mechanism is `private` (`HTTP-CACHE-11`).
