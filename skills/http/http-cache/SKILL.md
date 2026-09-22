---
nome: http-cache
descricao: Decide a resource's HTTP cache policy and implement conditional requests — `Cache-Control` directive by directive, `ETag`, `304`, `If-Match` for concurrent writes, `Vary` — citing `HTTP-CACHE-*` IDs, with `curl` probes that prove whether the conditional is handled — use when the task is defining a route's freshness, turning on `ETag` and answering `304`, protecting a concurrent write against overwriting, choosing between `no-store` and `no-cache`, versioning an asset, or understanding why a cache served the wrong response. Do not use to design method and status, which is http-contract, for a request blocked by the browser, which is http-diagnose, nor for the TanStack Query cache, which is another layer.
tipo: skill
familia: http
idioma: en
fonte: "[HTTP - Cache e Requisições Condicionais](../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md)"
tags:
  - skill
  - http
  - backend
---

# http-cache

> **Source of this skill:** [HTTP - Cache e Requisições Condicionais](../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md), with the [HTTP](../../../knowledge-base/docs/http.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to decide and what to prove with `curl`.

Contract this skill implements: [HTTP](../../../knowledge-base/docs/http.md) § 7 ("Contrato de skill").

---

## When to use

The question is **for how long**, **who may store it**, or **how to revalidate** — or a concurrent write overwrote someone else's.

| Situation | Go to |
| --- | --- |
| which method, which status, `Location` | `http-contract` |
| a blocked request, CORS, wrong format | `http-diagnose` |
| auditing the whole API | `http-review` |
| the client's `staleTime`/`gcTime` | `tanstack-query` — **another layer**, see Step 5 |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [HTTP](../../../knowledge-base/docs/http.md) § 5.3 | the freshness tree — the core of this skill |
| 2 | [HTTP](../../../knowledge-base/docs/http.md) § 6 + § 6.2 | rules and, **required**, the note about `Vary` and strong `ETag` |
| 3 | [HTTP - Cache e Requisições Condicionais](../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | the source |
| 4 | [HTTP](../../../knowledge-base/docs/http.md) § 8.3 | the boundary with the TanStack Query cache |

References in this skill:

| File | What for |
| --- | --- |
| `references/frescor-e-etag.md` | the freshness tree, `ETag`, and the `304` |
| `references/escrita-e-vary.md` | `If-Match`/`412`, and the obligations of `Vary` |
| `references/fronteira-com-o-query.md` | why the confusion with the client cache is structural |
| `references/autoverificacao.md` | the 12 items, and the probes that prove them |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 74 `HTTP-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/sondas-cache.sh` | proves whether the conditional is handled and whether the concurrent write is barred |

> **The § 6.2 note this skill uses most:** the three `Vary` rules **are not aliases**. `HTTP-CORE-04` is the general statement; `HTTP-CACHE-10` adds the cache consequence; `HTTP-NEG-01` the compression one; `HTTP-CORS-03` the dynamic-origin one.

---

## Step 1 — The freshness tree

`references/frescor-e-etag.md`. Every `GET` response declares `Cache-Control` (`HTTP-CACHE-01`) — without it, the policy belongs to the intermediate cache, not to you. A response for an authenticated user is `private` or `no-store` (`HTTP-CACHE-02`).

**`no-store` is not "always revalidate"** (`HTTP-CACHE-03`) — that is `no-cache`.

---

## Step 2 — `ETag` and the `304`

Emitting an `ETag` is not enough: the route has to **handle** `If-None-Match` and return `304` with no body (`HTTP-CACHE-07`, `HTTP-CACHE-06`). An emitted-and-ignored ETag is decorative — and probe 2 of the script proves it in one command.

---

## Step 3 — Concurrent writes

`If-Match` with a **strong ETag** (`HTTP-CACHE-09`) and `412` when it does not match (`HTTP-CACHE-08`). It is the gravest rule in this skill: without it, **two simultaneous edits erase each other silently**.

---

## Step 4 — `Vary`

List the headers that **change the body** (`HTTP-CACHE-10`), and **never** use `Vary` with `Cookie`/`User-Agent` to protect data (`HTTP-CACHE-11`) — that is not access control.

---

## Step 5 — The boundary with TanStack Query

They are **stacked layers with different owners**: the HTTP cache is decided by the **server**, through headers; Query's, by the **client**, through `staleTime`. A high `staleTime` does not stop the browser from serving a cached response; a `no-store` does not stop Query from returning what it already has. Detail: `references/fronteira-com-o-query.md`.

---

## Step 6 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-cache/scripts/sondas-cache.sh https://api.local/invoices/42
```

The two probes that fail most are the ones that **do not error** when unimplemented: the conditional returns `200` with the whole body, and the concurrent write applies the change.

---

## Step 7 — Closing

1. **Run the probes.** A declared policy and an implemented policy are different things.
2. **If the decision became "which status to return"**, it is `http-contract`.
3. **If the cache served a response from another origin**, the finding is `Vary` — and it may be CORS (`http-diagnose`).
4. **Declare what you did not verify.**

---

## Example

An invoice resource: `private, max-age=0, must-revalidate` with a strong `ETag`, `304` handled, and `If-Match` required on writes. The probe showed that a `PUT` with a stale `If-Match` **applied** the write — silent loss under concurrency, and the review's gravest finding.

Full case: `references/exemplo.md`.

---

## Related

- [HTTP - Cache e Requisições Condicionais](../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) — source of this skill
- [HTTP](../../../knowledge-base/docs/http.md) § 5.3, § 6, § 7, § 8.3
- `http-contract` · `http-diagnose` · `http-review` — the sibling skills
- `tanstack-query` — the other cache layer
