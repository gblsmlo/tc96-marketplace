---
nome: elysia-build
descricao: Write routes and handlers in Elysia — method chaining, destructured context, `status`, signed cookies, streaming, error taxonomy and testing through `app.handle` — citing `ELYSIA-CORE-*` and `ELYSIA-APP-*` IDs, with an executable self-check — use when the task is creating a new route, returning an expected error in a typed way, signing a session cookie, registering a domain error with its own `code`, handling `onError`, or testing a route without starting a server. Do not use for schemas and the Eden client, which is elysia-schema, for a plugin or hook that does not affect the route, which is elysia-diagnose, nor for the HTTP contract itself, which is http-contract.
tipo: skill
familia: elysia
idioma: en
fonte: "[Elysia - Roteamento e Handler](../../../knowledge-base/elysia-roteamento-e-handler.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-build

> **Source of this skill:** [Elysia - Roteamento e Handler](../../../knowledge-base/elysia-roteamento-e-handler.md), with the [Elysia](../../../knowledge-base/elysia.md) hub as the router. The 44 rules of the `ELYSIA-*` family are declared in § 6 of the hub; the body of `CORE`, `LIFE` and `TYPE` lives in the owning satellite.
> This skill **does not contain** the text of the rules — it says what to load, in what order to decide, and what to check before delivering.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Elysia](../../../knowledge-base/elysia.md) § 7 ("Contrato de skill").

---

## When to use

Writing or editing a **route and handler**.

| Situation | Go to |
| --- | --- |
| validation schema, `response` per status, Eden client | `elysia-schema` |
| a hook or plugin that **does not affect** the route | `elysia-diagnose` |
| which status, `Location`, idempotency, error body | `http-contract` — Elysia is the mechanism, not the criterion |
| cache policy and `ETag` | `http-cache` |
| the persistence the handler calls | `drizzle-review` |
| the test itself, under `bun test` | `bun-test-build` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia](../../../knowledge-base/elysia.md) § 2 | **one schema declaration produces four effects** — that is the mental model |
| 2 | [Elysia](../../../knowledge-base/elysia.md) § 3 | import boundaries, and the **two npm scopes** that coexist |
| 3 | [Elysia](../../../knowledge-base/elysia.md) § 6 + § 6.1 + § 6.2 | rules, critical ones and canonical IDs |
| 4 | [Elysia - Roteamento e Handler](../../../knowledge-base/elysia-roteamento-e-handler.md) | the source |
| 5 | [Elysia](../../../knowledge-base/elysia.md) § 5 ("Como devolvo um erro?") | the error tree |

**Never load all the satellites.**

References in this skill:

| File | What for |
| --- | --- |
| `references/instancia-e-handler.md` | the two things that date the code, the chaining, the destructured context |
| `references/erro-cookie-e-teste.md` | the error tree, signed cookies, streaming, and testing through `app.handle` |
| `references/autoverificacao.md` | the 15 items, and which ones the script does **not** decide |
| `references/antipadroes.md` | 17 antipatterns with IDs |
| `references/mapa-de-ids.md` | the 44 `ELYSIA-*`: declaration, **satellite of the body** and section |
| `references/exemplo-rota-de-faturas.md` | worked case, from the instance to the test |
| `scripts/autoverificar.sh` | runs the mechanical items and lists the ones that require reading |

**Check § 6.2 before citing:** this family has **partial aliases** — `ELYSIA-APP-03` is an alias of `ELYSIA-CORE-02` **only** in the destructuring clause, and `ELYSIA-TYPE-11` is an alias of `ELYSIA-APP-04` **only** in the `strict` one. Outside those clauses, both are citable for what is theirs alone.

---

## Step 0 — Two things that date the code

1. **`error` no longer exists** — it is `status` since 1.4 (`ELYSIA-APP-02`). Examples using `error` still circulate.
2. **`@elysiajs/*` is legacy**, and `@elysiajs/swagger` is discontinued — use `@elysia/openapi` (`ELYSIA-APP-07`).

---

## Step 1 — The instance

**Continuous** method chaining (`ELYSIA-APP-01`), `export type App = typeof app` at the end (`ELYSIA-APP-05`), `strict: true` on both sides (`ELYSIA-APP-04`). Breaking the chaining into statements makes Eden **lose the routes with no error on the server**.

---

## Step 2 — The handler

Destructure the context **inline** (`ELYSIA-CORE-02`). An external function annotated with a generic `Context` erases the inference the schema produced — this is not a style preference.

---

## Step 3 — Errors

**Expected → `return status(code, body)`** (`ELYSIA-CORE-03`); unexpected → `throw`, which lands in `onError`. A `throw` leaves through a path **outside the route's type**, so Eden does not know that status exists.

`onError` **never** returns `error.message` from an `UNKNOWN` error (`ELYSIA-CORE-07`) — that is a security finding: it leaks file paths, queries and table names.

---

## Step 4 — Cookies and streaming

A session cookie is **signed and `httpOnly`** (`ELYSIA-CORE-05`); the semantics of `SameSite` and prefixes come from [RFC 6265 - Cookies HTTP](../../../knowledge-base/rfc-6265-cookies-http.md). In a stream, `set.headers` after the first `yield` is **silently ignored** (`ELYSIA-CORE-06`) — and `Bun.serve`'s `idleTimeout` drops SSE on its own.

---

## Step 5 — Testing

`app.handle`, never over the network (`ELYSIA-CORE-09`), and **`await app.modules`** before the assertions (`ELYSIA-CORE-10`) — without it the test runs before the plugin registers the route, and turns flaky.

---

## Step 6 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-build/scripts/autoverificar.sh src
tsc --noEmit # Bun transpiles without type-checking — BUN-CORE-02
```

The 15 items are in `references/autoverificacao.md`, marked by which ones the script decides and which require reading.

---

## Step 7 — Closing

1. **`tsc --noEmit`** and the test through `app.handle`.
2. **A route with more than one status** needs `response` as a map — that is `elysia-schema` (`ELYSIA-TYPE-06`); without it Eden sees `unknown`.
3. **A hook that does not affect the route** is scope or order — `elysia-diagnose`.
4. **A protocol decision** (status, `Location`, `Retry-After`) is `http-contract`.
5. **Streaming**: check `Bun.serve`'s `idleTimeout` — the framework does not work around it.
6. **Declare what you did not verify.** The `onError` path for a genuinely unexpected error is rarely exercised.

---

## Example

An invoice approval route with a limit error and a signed session: the expected error leaves through `return status(422, …)` and reaches Eden **typed**; `onError` answers generically and logs the detail; the cookie is signed and `httpOnly`; the test runs through `app.handle` after `await app.modules`.

Full case: `references/exemplo-rota-de-faturas.md`.

---

## Related

- [Elysia - Roteamento e Handler](../../../knowledge-base/elysia-roteamento-e-handler.md) — source of this skill
- [Elysia](../../../knowledge-base/elysia.md) § 2, § 5, § 6, § 7 — mental model, trees, rules, contract
- `elysia-schema` · `elysia-diagnose` — the sibling skills
- `http-contract` · `http-cache` — the protocol, which Elysia only implements
- `bun-test-build` — the test itself
