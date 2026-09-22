# The scan order, and severity

The order is by consequence, not by family.

1. **A failure masked as success** — `HTTP-CORE-06`. First because it poisons every client: Hono's `hc` and Eden Treaty **do not throw** on an error status, so a `200 {ok:false}` leaves the query in `success` with the error inside `data`.
2. **A write without concurrency protection** — `HTTP-CACHE-08`, `HTTP-CACHE-09`. Silent data loss.
3. **A method with the wrong semantics** — `HTTP-METH-01` (destructive behind safe), `HTTP-METH-03` (partial `PUT`), `HTTP-METH-04` (broken idempotency), `HTTP-METH-02`.
4. **Unsafe retry** — `HTTP-METH-08`, `HTTP-METH-09`. Frequently client configuration, not server code.
5. **A status that loses information** — `HTTP-STATUS-02` (4xx × 5xx), `HTTP-STATUS-11` (`422`), `HTTP-STATUS-12` (`502`), `HTTP-STATUS-10` (`401` × `403`), `HTTP-NEG-07` (`415`).
6. **The obligations that come with a status** — `HTTP-STATUS-03` (`Location`), `HTTP-STATUS-04` (`204` with no body), `HTTP-STATUS-05`, `HTTP-STATUS-09` (`Retry-After`), `HTTP-METH-07` (`Allow`).
7. **Redirects** — `HTTP-STATUS-06`, `HTTP-STATUS-07`, `HTTP-STATUS-08`.
8. **CORS designed or improvised** — `HTTP-CORS-01`, `HTTP-CORS-02`, `HTTP-CORS-08`, `HTTP-CORS-10`. And `HTTP-CORS-08` is conceptual: CORS treated as authorization is a security finding.
9. **Cache and `Vary`** — `HTTP-CACHE-01`, `HTTP-CACHE-02`, `HTTP-CACHE-10`, `HTTP-CACHE-11`, `HTTP-CORS-03`.
10. **Negotiation and charset** — `HTTP-CORE-03`, `HTTP-NEG-02`, `HTTP-NEG-04`, `HTTP-NEG-09` to `HTTP-NEG-11`.
11. **Request hygiene** — `HTTP-CORE-05`, `HTTP-CORE-07`, `HTTP-CORE-08`.
12. **Spec citations** — `HTTP-SPEC-*`. Last, and only where an ADR, a PR comment or a doc asserts a norm.

If a step produces a finding that invalidates the next one — the API signals failure as `2xx`, so debating which `4xx` is academic — **stop auditing the interior** and report the change of contract.

---

## Step 3 — Classify severity

| Severity | What goes in |
| --- | --- |
| **Blocking** | a failure as `2xx` (`HTTP-CORE-06`); a concurrent write without `If-Match` (`HTTP-CACHE-08`); destructive behind a safe method (`HTTP-METH-01`); sensitive data in the query string (`HTTP-CORE-07`); CORS used as authorization (`HTTP-CORS-08`); `Allow-Origin: *` with credentials (`HTTP-CORS-02`) |
| **High** | partial `PUT` (`HTTP-METH-03`); broken idempotency (`HTTP-METH-04`); retry without a key (`HTTP-METH-08`/`09`); `5xx` where it was `4xx` and vice versa (`HTTP-STATUS-02`); `500` where it was `502` (`HTTP-STATUS-12`); an authenticated response marked `public` (`HTTP-CACHE-02`); missing `Vary` (`HTTP-CACHE-10`, `HTTP-CORS-03`) |
| **Medium** | `201` without `Location`; `204` with a body; `405` without `Allow`; `429` without `Retry-After`; `400` where it was `422` or `415`; absent `HEAD`; an `ETag` without handling `If-None-Match`; a missing `charset`; two error formats |
| **Low** | an outdated spec citation (`HTTP-SPEC-02`), a header name outside the registry (`HTTP-SPEC-07`) |

The criterion between Blocking and High: **does the defect make the client believe something false, or lose data?** A failure as `2xx` and last-write-wins do both — they are a different category from "imprecise status".

**And the criterion that separates a finding from context:** if the framework does not do it on its own (§ 8 of the hub), the finding stands, but the fix changes — it is mounting the built-in, not writing the header by hand.
