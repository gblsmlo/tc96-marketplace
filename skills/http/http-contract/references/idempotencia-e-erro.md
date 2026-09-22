# Idempotency, error body and headers

A design decision, not an implementation detail.

```
Can the client resend this request unintentionally?
(automatic retry, a button clicked twice, a network timeout)
├── it is GET/HEAD/PUT/DELETE → already idempotent by semantics (HTTP-METH-04)
└── it is POST or PATCH
 ├── is creating a duplicate acceptable? → nothing to do
 └── creating a duplicate is a defect
 → accept an idempotency key in the request (HTTP-METH-09)
 and the client does NOT configure retry without it (HTTP-METH-08)
```

**`HTTP-METH-08` is about the client and is frequently violated by configuration**, not by code: a global retry in the HTTP client turns every `POST` into a duplicate risk. See.

---

## Step 4 — Error body

**An API has one format, declared in the contract** (`HTTP-SPEC-08`). The citable standard is `application/problem+json` — and it is **RFC 9457**, not 7807, which was obsoleted in 2023 (`HTTP-SPEC-02`).

And what does **not** go in the error: sensitive data never in the query string (`HTTP-CORE-07`), and the status is never `2xx` (`HTTP-CORE-06`).

---

## Step 5 — Before writing a header by hand

§ 8 of the hub exists for this step, and it changes the work:

| Where the handler runs | What **you** have to write |
| --- | --- |
| raw `Bun.serve` | **everything** — CORS, `Cache-Control`, dynamic `ETag`, error-to-status mapping, `405` with `Allow` |
| Hono | there are built-ins for CORS, `etag`, `compress`, `bodyLimit`, and **`methodNotAllowed`** |
| Elysia | `@elysia/cors`, and the schema produces validation + type + OpenAPI + client |

**The Hono trap that is a silent violation of `HTTP-METH-07`:** without the `methodNotAllowed` middleware, an unsupported method on an existing route returns **`404`**, not `405` with `Allow`. See [Hono - Middleware e Ciclo de Vida](../../../../knowledge-base/docs/hono-middleware-e-ciclo-de-vida.md) § 5.
