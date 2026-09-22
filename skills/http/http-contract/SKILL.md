---
nome: http-contract
descricao: Design or change the HTTP contract of an endpoint — method, status, `Location`, idempotency, error body — citing `HTTP-*` IDs, with an executable `curl` check before delivering — use when the task is creating a new route, choosing between `PUT` and `PATCH`, deciding which status to return, designing a redirect, making a write safe to retry, or standardizing an API's error body. Do not use for cache policy and conditional requests, which is http-cache, for a request blocked by the browser, which is http-diagnose, nor to audit a whole API, which is http-review.
tipo: skill
familia: http
idioma: en
fonte: "[HTTP - Métodos e Semântica](../../../knowledge-base/docs/http-metodos-e-semantica.md)"
tags:
  - skill
  - http
  - backend
---

# http-contract

> **Source of this skill:** [HTTP - Métodos e Semântica](../../../knowledge-base/docs/http-metodos-e-semantica.md) and [HTTP - Status e Redirecionamento](../../../knowledge-base/docs/http-status-e-redirecionamento.md), with the [HTTP](../../../knowledge-base/docs/http.md) hub as the router. The 74 `HTTP-*` rules are declared in § 6 of the hub.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and what to check with `curl` before delivering.

Contract this skill implements: [HTTP](../../../knowledge-base/docs/http.md) § 7 ("Contrato de skill").

---

## When to use

There is an endpoint to design or change, and the questions are **which method**, **which status**, **what comes back in the body**.

| Situation | Go to |
| --- | --- |
| `Cache-Control`, `ETag`, `304`, `If-Match`, `Vary` | `http-cache` |
| a blocked request, CORS, wrong format | `http-diagnose` |
| auditing the contract of an existing API | `http-review` |
| writing the handler in the framework | `elysia-build` · Hono via Context7, `/websites/hono_dev` |
| validating the body at runtime | `elysia-schema` · Hono via Context7, `/websites/hono_dev` |
| authentication, session, tokens | `OWASP - Sessão e Autorização` · `RFC 9700 - OAuth 2.0 Security BCP` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [HTTP](../../../knowledge-base/docs/http.md) § 2 | the protocol's mental model |
| 2 | [HTTP](../../../knowledge-base/docs/http.md) § 5.1 and § 5.2 | this skill's two trees |
| 3 | [HTTP](../../../knowledge-base/docs/http.md) § 6 + § 6.1 + § 6.2 | rules, critical ones, and the canonical IDs |
| 4 | [HTTP - Métodos e Semântica](../../../knowledge-base/docs/http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](../../../knowledge-base/docs/http-status-e-redirecionamento.md) | the two sources, inseparable |
| 5 | [HTTP](../../../knowledge-base/docs/http.md) § 8 | **before writing a header by hand** — the stack may already do it |

References in this skill:

| File | What for |
| --- | --- |
| `references/metodo-e-status.md` | the two trees, with what each branch decides |
| `references/idempotencia-e-erro.md` | safe retry, idempotency key, error body, hand-written headers |
| `references/autoverificacao.md` | the 15 items, and the three `curl` calls that are worth most |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 74 `HTTP-*` by satellite and section, and the note about `Vary` |
| `references/exemplo.md` | worked case |
| `scripts/conferir.sh` | runs the Step 6 `curl` calls and lists what requires reading |

**The § 6.2 note that matters most here:** the three `Vary` rules **are not aliases** — each adds a concrete obligation. Cite the specific one when the context is specific.

---

## Step 1 — Which method

`references/metodo-e-status.md`. The cut that decides nearly everything: **a safe method does not write state** (`HTTP-CORE-02`, `HTTP-METH-01`), and `PUT` replaces the **whole** representation (`HTTP-METH-03`).

---

## Step 2 — Which status

A failure is **never** `2xx` (`HTTP-CORE-06`). `201` carries `Location`; `204` has no body; `405` carries `Allow`; `401` carries `WWW-Authenticate`; `429`/`503` carry `Retry-After`.

---

## Step 3 — Idempotency and retry

A `POST`/`PATCH` that can be retried accepts an **idempotency key** (`HTTP-METH-09`). Without it, the client's retry creates the second order — and the client has no way to know.

---

## Step 4 — Error body

**One format across the whole API** (`HTTP-SPEC-08`). Two formats is an inconsistent public contract, and every new route widens the problem.

---

## Step 5 — Before writing a header by hand

Check [HTTP](../../../knowledge-base/docs/http.md) § 8: the stack may already do it. A hand-written header where the framework already emits one is a source of silent divergence.

---

## Step 6 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-contract/scripts/conferir.sh https://api.local /orders/42 /orders
```

Fifteen items in `references/autoverificacao.md`. **What is worth most:** `curl -i` on the route and reading the headers for real — especially a `PATCH` on a route that only accepts `PUT`, which catches `HTTP-METH-07` (`404` instead of `405` with `Allow`).

---

## Step 7 — Closing

1. **Run the `curl`.** The contract is what the server answers, not what the handler appears to do.
2. **If the question became "how long can this be stored"**, it is `http-cache`.
3. **If the browser blocked it**, it is `http-diagnose` — and the cause is the server's, not the client's.
4. **Declare what you did not verify.**

---

## Example

An order creation endpoint: `POST` with an idempotency key, `201` with `Location`, a validation error as `422` in the API's single format, and `405` with `Allow` for an unsupported method. `curl -i` showed the route returned `404` on `PATCH` — the missing middleware, not the handler.

Full case: `references/exemplo.md`.

---

## Related

- [HTTP - Métodos e Semântica](../../../knowledge-base/docs/http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](../../../knowledge-base/docs/http-status-e-redirecionamento.md) — the sources
- [HTTP](../../../knowledge-base/docs/http.md) § 2, § 5, § 6, § 7, § 8
- `http-cache` · `http-diagnose` · `http-review` — the sibling skills
- `elysia-build` — the mechanism that implements this contract
