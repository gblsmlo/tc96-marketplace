# The freshness tree, ETag and the 304

The full tree is § 5.3 of the hub. The operational summary:

| The resource is… | `Cache-Control` |
| --- | --- |
| sensitive data that must not touch disk | `no-store` |
| specific to the authenticated user | `private, max-age=<n>` |
| public with a versioned URL (hash in the name) | `public, max-age=31536000, immutable` |
| public, changes now and then, serving stale is acceptable | `s-maxage=<short>, stale-while-revalidate=<n>` |
| public, changes on every write | `max-age=0, must-revalidate` + `ETag` |

**The entry rule:** every `GET` response declares `Cache-Control` explicitly (`HTTP-CACHE-01`). Omitting it **does not switch caching off** — **heuristic freshness** kicks in, roughly 10% of the interval since `Last-Modified` (RFC 9111 § 4.2.2). It is reason #1 for "it cached and I never asked for that".

### 1.1 The three directive confusions

| You want | The right directive | The common mistake |
| --- | --- | --- |
| "do not store it anywhere" | `no-store` | `no-cache` — which **does store** |
| "store it, but ask before reusing" | `no-cache` | `no-store`, which throws it away and loses the `304` |
| "only their browser, never the CDN" | `private` | `public` with session data |

**`no-cache` stores the response** — it prevents reuse **without revalidation**. Whoever writes `no-store` meaning "always revalidate" loses the whole `304` saving (`HTTP-CACHE-03`, `HTTP-CACHE-12`).

**A per-user personalized response is `private` at minimum** (`HTTP-CACHE-02`). `public` on a body derived from a session cookie is how a shared cache serves one person's data to another.

**`max-age` above 24 h requires a versioned URL** (`HTTP-CACHE-04`) — without a hash in the name, there is no way to correct it before the deadline.

---

## Step 2 — `ETag` and the `304`

```
GET /invoices/42 → 200 + ETag: "v7" + Cache-Control
GET /invoices/42 → If-None-Match: "v7"
 → 304, no body, repeating ETag/Cache-Control/Date/Vary
```

| Check | Rule |
| --- | --- |
| a revalidatable `200` response includes `ETag`; `Last-Modified` is the fallback | `HTTP-CACHE-05` |
| the route **handles** `If-None-Match` and answers `304` when it matches | `HTTP-CACHE-07` |
| `304` **with no body**, repeating `ETag`, `Cache-Control`, `Date` and `Vary` | `HTTP-CACHE-06` |

**Emitting an `ETag` without handling `If-None-Match` is the most common antipattern here**: it costs the header and delivers no saving at all — the client asks and receives the whole body back.

**What the stack does on its own:** `Bun.serve` answers `304` to `If-None-Match` when serving `Bun.file` — but **only for files**. For a dynamic response, the `ETag` is yours ([Bun - HTTP e Servidor](../../../../knowledge-base/docs/bun-http-e-servidor.md)). In Hono there is `hono/etag`, with `weak: false` by default — resolve the option through Context7, `/websites/hono_dev`.
