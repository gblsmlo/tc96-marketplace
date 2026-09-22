# Method and status

> Steps 1 and 2. The full trees are § 5.1 and § 5.2 of [HTTP](../../../../knowledge-base/docs/http.md).

The full tree is § 5.1 of the hub. The invariants it protects:

| Property | Means | Rule |
| --- | --- | --- |
| **safe** | does not change domain state — `GET`, `HEAD`, `OPTIONS` | `HTTP-CORE-02`, `HTTP-METH-01` |
| **idempotent** | repeating produces the same final state — `PUT`, `DELETE` | `HTTP-METH-04` |
| **cacheable** | the response can be reused | `HTTP-METH-10` |

Three decisions the tree settles and that get made wrong out of habit:

- **`PUT` replaces the whole representation.** An endpoint that accepts `PUT` and ignores absent fields is not `PUT` — it is a badly named `PATCH` (`HTTP-METH-03`).
- **No body in `GET`, `HEAD` or `DELETE`** — neither from the client, nor defined by the server (`HTTP-METH-02`).
- **Every route that answers `GET` answers `HEAD`** on the same URL, with the same headers and no body (`HTTP-METH-06`).

And the one that is not about style: **a destructive action never sits behind a safe method** (`HTTP-METH-01`). A `GET /orders/42/cancel` is fired by browser prefetch, by crawlers and by any cache.

---

## Step 2 — Which status

The full tree is § 5.2 of the hub. The obligations that come with each choice:

| Status | Obligation | Rule |
| --- | --- | --- |
| `201` | `Location` pointing at the created resource | `HTTP-STATUS-03`, `HTTP-METH-05` |
| `204` | **no body** | `HTTP-STATUS-04` |
| `202` | in the body, the tracking identifier or URL | `HTTP-STATUS-05` |
| `401` | `WWW-Authenticate` | `HTTP-STATUS-10` |
| `405` | `Allow` with the supported methods | `HTTP-METH-07` |
| `415` | when the **request's** `Content-Type` is refused — not `400` | `HTTP-NEG-07` |
| `422` | a valid body rejected by a business rule | `HTTP-STATUS-11` |
| `429` / `503` | `Retry-After` | `HTTP-STATUS-09` |
| `502` | when the service is a gateway and the upstream failed | `HTTP-STATUS-12` |

**The rule that dominates the step:** a failure is never `2xx` with an error in the body. The status carries the result (`HTTP-CORE-06` — canonical; `HTTP-STATUS-01` is an alias and must not be cited).

> **The bridge that avoids the stack's most common bug:** neither Hono's `hc` nor Elysia's Eden Treaty **throws** on an error status. A naive `queryFn` stays in `success` with the error inside `data` — see `Docs/Hono - Validação e RPC.md` and `Docs/Elysia - Schema e Eden.md`. In other words: honoring `HTTP-CORE-06` on the server **is not enough** if the typed client does not check `res.ok`.

### 2.1 Redirects

| I need to… | Use | Rule |
| --- | --- | --- |
| preserve method and body | `307` (temporary) or `308` (permanent) | `HTTP-STATUS-07` |
| send a `POST` to a result page | **`303`** | `HTTP-STATUS-08` |
| permanently move a `GET` URL | `301` | — |

And every redirect `3xx` carries `Location` (`HTTP-STATUS-06`).

> **`301` and `302` allow the method to change by the spec itself** — this is not tolerance of a browser bug. That is why "temporary" is not the criterion: the criterion is whether the method has to survive.
