# Worked example

Task: *"the invoice listing is slow, and two people editing the same invoice overwrite each other"*.

These are two problems and two parts of the tree.

**Part 1 — the listing's freshness.** It is an authenticated user's data, it changes on every write, and serving stale is not acceptable (money on screen):

```http
GET /invoices
200 OK
Cache-Control: private, max-age=0, must-revalidate
ETag: "list-v41"
Vary: Accept, Accept-Encoding
Content-Type: application/json; charset=utf-8
```

And the route starts handling `If-None-Match`, returning `304` when `"list-v41"` matches (`HTTP-CACHE-07`). The saving comes from the `304`, not from `max-age` — the client always asks, and the answer is small.

**Part 2 — the concurrent write:**

```http
PUT /invoices/42
If-Match: "v7"

→ 412 Precondition Failed (the current ETag is "v9")
```

**What these decisions prevented:**

| Decision | Common alternative | Rule |
| --- | --- | --- |
| `private` | `public`, and the CDN serves one person's invoice to another | `HTTP-CACHE-02` |
| `max-age=0, must-revalidate` + `ETag` | `no-store`, which loses the `304` and keeps the slowness | `HTTP-CACHE-03` |
| handling `If-None-Match` | only emitting `ETag`, and the client receiving the body every time | `HTTP-CACHE-07` |
| `Vary: Accept, Accept-Encoding` | no `Vary`, and the cache serving gzip to a client that does not accept it | `HTTP-CACHE-10`, `HTTP-NEG-01` |
| `If-Match` + `412` | last-write-wins, silent data loss | `HTTP-CACHE-08` |
| a strong `ETag` | `W/"v7"`, which does not decide identity | `HTTP-CACHE-09` |
| explicit `charset=utf-8` | broken accents | `HTTP-CORE-03` |

And what was deliberately **not** done: no `staleTime` as an answer to the slowness problem. It would save a client request and would resolve neither the second visit nor another device — a different layer (§ 5).
