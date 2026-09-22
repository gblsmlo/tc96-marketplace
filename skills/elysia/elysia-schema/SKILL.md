---
nome: elysia-schema
descricao: Declare schemas in Elysia and consume the API through Eden — `t`/TypeBox, coercion by source, `response` per status, standalone `guard`, OpenAPI, and the bridge with TanStack Query — citing `ELYSIA-TYPE-*` IDs, with an executable self-check — use when the task is validating body, query, params, headers or uploads, typing a route's return, assembling an Eden client, paginating a listing, generating OpenAPI documentation, or fixing `data` that comes back `null` on the client. Do not use to write the route and the handler, which is elysia-build, for a plugin that does not affect the route, which is elysia-diagnose, nor for the client cache, which is tanstack-query.
tipo: skill
familia: elysia
idioma: en
fonte: "[Elysia - Schema e Eden](../../../knowledge-base/docs/elysia-schema-e-eden.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-schema

> **Source of this skill:** [Elysia - Schema e Eden](../../../knowledge-base/docs/elysia-schema-e-eden.md), with the [Elysia](../../../knowledge-base/docs/elysia.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and what to check before delivering.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Elysia](../../../knowledge-base/docs/elysia.md) § 7 ("Contrato de skill").

---

## When to use

Declaring a schema, typing a return, or consuming the API through Eden.

| Situation | Go to |
| --- | --- |
| the route and the handler themselves | `elysia-build` |
| a hook or plugin that does not affect the route | `elysia-diagnose` |
| freshness policy of the client cache | `tanstack-query` |
| **HTTP** cache policy (`ETag`, `Cache-Control`) | `http-cache` |
| which status to return, and the standard error body | `http-contract` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia](../../../knowledge-base/docs/elysia.md) § 2 | **one schema declaration produces four effects** |
| 2 | [Elysia](../../../knowledge-base/docs/elysia.md) § 6 + § 6.1 + § 6.2 | rules, critical ones and canonical IDs |
| 3 | [Elysia - Schema e Eden](../../../knowledge-base/docs/elysia-schema-e-eden.md) | the source |
| 4 | [Elysia](../../../knowledge-base/docs/elysia.md) § 5 | the trees, when in doubt |

References in this skill:

| File | What for |
| --- | --- |
| `references/coercao-response-e-guard.md` | coercion by source, `response` per status, `guard`, uploads, OpenAPI |
| `references/eden.md` | Eden's three traps, and why all three compile |
| `references/autoverificacao.md` | the 14 items, and the test that proves `ELYSIA-TYPE-09` |
| `references/antipadroes.md` | 16 antipatterns with IDs |
| `references/mapa-de-ids.md` | the 44 `ELYSIA-*`: declaration, satellite of the body and section |
| `references/exemplo-listagem-paginada.md` | worked case, from the schema to the `queryFn` |
| `scripts/autoverificar.sh` | runs the mechanical items and lists the ones that require reading |

---

## Step 0 — The mental model

> **One schema declaration produces four effects:** runtime validation, a TypeScript type, an OpenAPI document, and the Eden client's type.

That changes the economics: a badly declared schema does not get one thing wrong — **it gets four wrong**. And that is why `ELYSIA-TYPE-01` forbids rewriting the type by hand.

---

## Step 1 — Coercion depends on the source

`params`, `query`, `headers` and `cookie` **coerce**; **`body` does not** (`ELYSIA-TYPE-04`). A `t.Number` in the body receiving `"100"` fails validation, and the developer concludes the schema is wrong.

And `ELYSIA-TYPE-03`: header names in **lowercase** — a capitalized name **never matches**, and the symptom is a required header that "is never sent".

---

## Step 2 — `response` per status

Without the map by status, **the error reaches Eden as `unknown`** (`ELYSIA-TYPE-06`) — the client loses exactly the information that justified using a typed client. A paginated listing declares an **envelope**, not a raw array (`ELYSIA-TYPE-13`).

---

## Step 3 — `guard` and composition

The default is **`override`**: the guard's schema **replaces** the route's. To add to it, `schema: 'standalone'` (`ELYSIA-TYPE-05`). Symptom of forgetting: the route's body validation **silently disappears**.

---

## Step 4 — Uploads and OpenAPI

Uploads use **`fileType`** (`ELYSIA-TYPE-02`) — a generic validator checks the **declared** `content-type`, which the client controls. That is a security finding.

A route with Zod/Valibot/Effect needs `mapJsonSchema` **or it disappears from the documentation** (`ELYSIA-TYPE-07`) — it fails silently. And `allowUnsafeValidationDetails: true` **never** in production (`ELYSIA-TYPE-12`).

---

## Step 5 — Eden, and the three traps

`references/eden.md`. None of them breaks the build:

1. **`data` is `null` on any status ≥ 300** — check `error` first (`ELYSIA-TYPE-08`).
2. **Eden does not throw.** `queryFn`/`mutationFn` has to throw, or use `throwHttpError: true` (`ELYSIA-TYPE-09`). Without that the query stays in **`success`** with the error inside `data`: `isError` false, no retry, no Error Boundary. **It is the most expensive bug on the bridge.**
3. **`parseDate: true` breaks Query's structural sharing** and re-renders the entire list (`ELYSIA-TYPE-10`).

---

## Step 6 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-schema/scripts/autoverificar.sh src
tsc --noEmit # in BOTH packages — the only contract check Eden has
```

And **force an error**: the query has to end up in `isError`, not in `success`.

---

## Step 7 — Closing

1. **`tsc --noEmit` in both packages.**
2. **If the route disappears from OpenAPI**, it is `mapJsonSchema` (`ELYSIA-TYPE-07`), not a plugin bug.
3. **If there is an unexplained re-render in the list**, it is `parseDate` (`ELYSIA-TYPE-10`).
4. **Three cache layers, three owners:** the client's is `tanstack-query`, the HTTP one is `http-cache`, and this skill only delivers the typed data.
5. **Declare what you did not verify.** A contract under diverging `elysia` versions only shows up when someone upgrades one side (`ELYSIA-TYPE-11`).

---

## Example

A paginated invoice listing consumed by the front end: `response` is a map by status, the listing returns an **envelope** with `items`/`total`/`hasMore`, the Eden client uses `parseDate: false`, and the `queryFn` **throws** when `error` comes back filled — without that the screen renders success with null data.

Full case: `references/exemplo-listagem-paginada.md`.

---

## Related

- [Elysia - Schema e Eden](../../../knowledge-base/docs/elysia-schema-e-eden.md) — source of this skill
- [Elysia](../../../knowledge-base/docs/elysia.md) § 2, § 6, § 7
- `elysia-build` · `elysia-diagnose` — the sibling skills
- `tanstack-query` — the cache on the other side of the bridge
- `Zod - Validação de Ambiente` — when the schema is Zod
