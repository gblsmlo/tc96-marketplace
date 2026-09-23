---
nome: http-diagnose
descricao: Diagnose a request blocked by the browser or a format disagreement between client and server — the CORS failure model, preflight, readable headers, `415` × `406`, charset — citing `HTTP-CORS-*` and `HTTP-NEG-*` IDs, with five executable `curl` probes — use when the task is investigating a CORS error in the console, a failing preflight, a header that arrives `undefined` in JavaScript, a request that works in curl and fails in the browser, broken accents, or a body in the wrong format. Do not use to design method and status, which is http-contract, for freshness policy, which is http-cache, nor to audit the whole API, which is http-review.
tipo: skill
familia: http
idioma: en
fonte: "[HTTP - CORS](../../../knowledge-base/http-cors.md)"
tags:
  - skill
  - http
  - backend
---

# http-diagnose

> **Source of this skill:** [HTTP - CORS](../../../knowledge-base/http-cors.md) and [HTTP - Negociação de Conteúdo e Range](../../../knowledge-base/http-negociacao-de-conteudo-e-range.md), with the [HTTP](../../../knowledge-base/http.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to probe, in what order to eliminate hypotheses, and what is **not** CORS.

Contract this skill implements: [HTTP](../../../knowledge-base/http.md) § 7 ("Contrato de skill").

---

## When to use

A request does not arrive, or arrives and the format is wrong.

| Situation | Go to |
| --- | --- |
| designing method and status | `http-contract` |
| freshness policy, `ETag`, conditionals | `http-cache` |
| auditing the whole API | `http-review` |
| Elysia's `cors` plugin with a permissive default | `elysia-diagnose` (`ELYSIA-LIFE-12`) — the same finding by another path |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [HTTP](../../../knowledge-base/http.md) § 5.4 and § 5.5 | this skill's two trees |
| 2 | [HTTP](../../../knowledge-base/http.md) § 6 + § 6.2 | rules and canonical IDs |
| 3 | [HTTP - CORS](../../../knowledge-base/http-cors.md) | the source |
| 4 | [HTTP - Negociação de Conteúdo e Range](../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) | when the symptom is format, not blocking |

References in this skill:

| File | What for |
| --- | --- |
| `references/modelo-de-falha.md` | "is it really CORS?" and the failure model, branch by branch |
| `references/formato-e-encoding.md` | `415` × `406`, language, charset |
| `references/sondas.md` | the five probes, and how to read each result |
| `references/relatorio-e-corte.md` | finding format, and what is **not** CORS |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 74 `HTTP-*` by satellite and section |
| `scripts/sondas-cors.sh` | runs all five and prints the reading of each |

---

## Step 0 — Two things that save the whole session

1. **CORS is a server decision.** Changing the client is never the fix.
2. **`curl` does not do CORS** — and that is exactly why it helps: it shows what the server answers, **without the browser in the way**.

---

## Step 1 — Is it really CORS?

`references/modelo-de-falha.md`. Half of all "CORS errors" are the server not responding: the browser's message is the same.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-diagnose/scripts/sondas-cors.sh https://api.local/invoices http://localhost:5173
```

**Probe 2 pays most:** if the preflight returns `401`, `404` or `405`, the problem is the **preflight**, not the real call — and the handler is correct.

---

## Step 2 — The failure model, branch by branch

Origin not allowed · preflight not handled · request header not listed · response header not exposed · credentials with `origin: '*'` · missing `Vary: Origin`.

**`origin: '*'` with `credentials: true` is invalid** and the browser refuses (`HTTP-CORS-02`) — the same finding as `ELYSIA-LIFE-12` from the framework side.

**Probe 4 is the one almost nobody runs:** with the origin **refused**, is `Vary: Origin` still there? Without it, the cache serves one origin's response to another (`HTTP-CORS-03`).

---

## Step 3 — Format, language, encoding

`references/formato-e-encoding.md`. `415` is about what **comes in**; `406` about what **goes out** — swapping the two is the most common mistake. And `text/*` without `charset` is a broken accent waiting to happen (`HTTP-CORE-03`).

---

## Step 4 — Report

```
`RULE-ID` — <where>
Symptom: <the browser's message, and what the user sees>
Evidence: <the probe's output, with the header>
Cause: <one sentence>
Fix: <on the server>
See the corresponding satellite.
```

**Evidence is the `curl` output**, with the header pasted in. "Looks like CORS" is not evidence.

---

## Step 5 — The cut: what is not CORS

An error that `curl` also reproduces, a legitimate `401`, a header the server never sent, mixed content, and a cookie that does not travel because of `SameSite` — **none of these is CORS**, and treating them as such leads to loosening the policy without solving anything. Table in `references/relatorio-e-corte.md`.

---

## Step 6 — Closing

1. **The fix is on the server.** If the proposal touches the client, it is wrong.
2. **If the origin is echoed without a list**, the finding is about **security** (`HTTP-CORS-01`), not configuration.
3. **If the preflight is the cause**, also check its cache (`Access-Control-Max-Age`).
4. **Declare what you did not verify.**

---

## Related

- [HTTP - CORS](../../../knowledge-base/http-cors.md) — source of this skill
- [HTTP - Negociação de Conteúdo e Range](../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) — the second source
- `http-contract` · `http-cache` · `http-review` — the sibling skills
- `elysia-diagnose` — the same finding from the plugin side
