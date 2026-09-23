---
nome: http-review
descricao: Audit an existing API's HTTP contract against the normative rules in the knowledge base, citing `HTTP-*` IDs, with eight executable `curl` probes for what reading code does not show — use when the task is reviewing a service's routes or a PR's, checking whether statuses and headers are right, finding a write without concurrency protection, verifying whether CORS was designed or improvised, or checking RFC citations in an ADR or documentation. Do not use to design a new route, which is http-contract, for freshness policy, which is http-cache, nor for one concrete failure under investigation, which is http-diagnose.
tipo: skill
familia: http
idioma: en
fonte: "[HTTP](../../../knowledge-base/http.md)"
tags:
  - skill
  - http
  - backend
  - code-review
---

# http-review

> **Source of this skill:** [HTTP](../../../knowledge-base/http.md) — the normative § 6 (74 rules, continuous numbering), § 6.1 with the 25 that travel with the minimum path, and § 6.2 with the canonical IDs.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan, how to classify and how to report.

Contract this skill implements: [HTTP](../../../knowledge-base/http.md) § 7 ("Contrato de skill").

---

## When to use

Auditing the contract of an API that **already exists** — the whole service, or the routes in a PR.

| Situation | Go to |
| --- | --- |
| designing a new route | `http-contract` |
| freshness and conditional policy | `http-cache` |
| one concrete failure under investigation | `http-diagnose` |
| the handler in the framework | `elysia-build` |
| the suite that should cover this | `test-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [HTTP](../../../knowledge-base/http.md) § 2 | the mental model |
| 2 | [HTTP](../../../knowledge-base/http.md) § 6 + § 6.1 | the rules and the critical ones |
| 3 | `references/mapa-de-ids.md` | **required before citing** |
| 4 | the satellite for the finding | via § 4 of the hub |

References in this skill:

| File | What for |
| --- | --- |
| `references/sondas.md` | the eight probes, and what each one reveals |
| `references/varredura-e-severidade.md` | the order by consequence, and the classification |
| `references/relatorio-e-corte.md` | finding format, and what is **not** a finding |
| `references/antipadroes.md` | the full grid, with IDs |
| `references/fechamento.md` | turning a probe into a test, and declaring the unverified |
| `references/mapa-de-ids.md` | the 74 `HTTP-*` by satellite and section |
| `scripts/sondas.sh` | runs all eight against the running service |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map across the four HTTP skills |

---

## Step 1 — Probe before reading

An HTTP contract is **invisible in the code**: the handler looks right, the test passes, and the missing header only breaks behind a CDN or in another browser.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-review/scripts/sondas.sh https://api.local /invoices/42 /invoices/42
```

**Two mandatory stops:**

| Probe | If it shows… | Why |
| --- | --- | --- |
| S5 | the write with a stale `If-Match` was **applied** | silent data loss under concurrency — not a style finding |
| S8 | two error formats in the same API | an inconsistent public contract, and every new route widens it |

**S3 is the one that lights up most in this stack:** in Hono, without the `methodNotAllowed` middleware, an unsupported method returns `404` instead of `405`.

---

## Step 2 — Scan in order

`references/varredura-e-severidade.md`, by **consequence**: what corrupts data → what lies about the result → what breaks clients → what degrades caching → convention.

---

## Step 3 — Classify and report

Blocking is what **corrupts data or lies** (a write without `If-Match`, a failure as `2xx`, a blindly reflected origin); High is what breaks clients today; Medium is debt.

For a probe, **the evidence is the `curl` output** — paste it, with the status and the headers.

**Three things are not findings:** the absence of a header the stack already emits, a **consistent** error format that is not your preferred one, and URL verbosity. Detail in `references/relatorio-e-corte.md`.

---

## Step 4 — Closing

1. **Turn a probe into a test.** S3, S4, S5 and S6 are verifiable in an API test — a finding that only exists in the report comes back in six months.
2. **Order by severity**, not by route.
3. **If the service does not start**, declare which probes did not run. **"Not verified" is not "no findings"**.

---

## Example

An invoices API: the probes show a `PUT` with a stale `If-Match` being **applied** (silent loss), a `PATCH` returning `404` instead of `405`, and the origin `malicious.example` being echoed without `Vary`. All three are from different categories — corruption, broken client and security — and the report separates them.

The format and the cut are in `references/relatorio-e-corte.md`.

---

## Related

- [HTTP](../../../knowledge-base/http.md) — source of this skill: § 6, § 6.1, § 6.2, § 7
- `http-contract` · `http-cache` · `http-diagnose` — the sibling skills
- `elysia-build` — where the fix is usually made
- `test-review` — the suite that should protect the contract
