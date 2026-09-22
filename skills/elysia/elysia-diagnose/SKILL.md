---
nome: elysia-diagnose
descricao: Diagnose why a plugin or hook does not affect a route in Elysia, and pick the right lifecycle point — registration order, `local`/`scoped`/`global` scope, plugin `name`, `derive` × `resolve`, `state` × `decorate`, macro, tracing — citing `ELYSIA-LIFE-*` IDs, with ten executable probes — use when the task is investigating a hook that does not run, authentication that does not protect the consumer's route, a frozen `store` value, a plugin whose lifecycle runs only once, or an `anonymous` span in OpenTelemetry. Do not use to write routes and handlers, which is elysia-build, nor for schemas and Eden, which is elysia-schema.
tipo: skill
familia: elysia
idioma: en
fonte: "[Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-diagnose

> **Source of this skill:** [Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md), with the [Elysia](../../../knowledge-base/docs/elysia.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to probe, in what order to eliminate hypotheses, and what **proves** each one.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Elysia](../../../knowledge-base/docs/elysia.md) § 7 ("Contrato de skill").

---

## When to use

A hook, plugin, `derive`, `resolve` or `onError` **is not affecting** the route — or state behaves unexpectedly.

| Situation | Go to |
| --- | --- |
| writing routes and handlers | `elysia-build` |
| schema, `response`, Eden client | `elysia-schema` |
| a request blocked by the browser, preflight | `http-diagnose` |
| a flaky test under `bun test` | `bun-test-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Elysia](../../../knowledge-base/docs/elysia.md) § 2 | the mental model of instance and plugin |
| 2 | [Elysia](../../../knowledge-base/docs/elysia.md) § 6 + § 6.1 + § 6.2 | rules, critical ones and canonical IDs |
| 3 | [Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | the source |

References in this skill:

| File | What for |
| --- | --- |
| `references/duas-causas.md` | registration order and undeclared scope — nearly every case is here |
| `references/arvore.md` | the five branches, and `derive` × `resolve` × `state` × `decorate` |
| `references/macro-tracing-e-cors.md` | the three that fail without breaking anything |
| `references/prova-de-escopo.md` | the test that tells `local` from `scoped`, and the cut of what is not lifecycle |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 44 `ELYSIA-*`: declaration, satellite of the body and section |
| `references/exemplo-plugin-sem-escopo.md` | a whole diagnosis, from the probe to the finding |
| `scripts/sondas.sh` | ten lifecycle probes |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map across the three Elysia skills |

---

## Step 1 — Probe

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-diagnose/scripts/sondas.sh src
```

**S1 measures order by line number** — a hook registered after the file's first route. It is the **first hypothesis, always** (`ELYSIA-CORE-01`), and it raises neither error nor warning: the route simply does not pass through the hook.

The other nine: undeclared scope, plugin without a `name`, `derive` deciding auth, `onRequest` reading `body`/`query`, a destructured `store`, a mutated `decorate`, an anonymous hook under tracing, default `cors`, a macro with `throw`, a plugin as a callback.

---

## Step 2 — The two causes

**1. Registered after the route** (`ELYSIA-CORE-01`) — hooks only apply to routes registered **after** them.

**2. Undeclared scope** (`ELYSIA-LIFE-01`) — the default is **`local`**: the hook stays inside the plugin and **does not cross** into the consuming instance. An authentication plugin without a declared scope protects its own routes and **none** of the consumer's.

```
local → only the plugin's own instance
scoped → the direct consumer
global → the whole tree
```

A cross-cutting hook — tracing, logging, CORS — uses `global` (`ELYSIA-LIFE-09`), not a chain of `scoped`.

---

## Step 3 — The tree

`references/arvore.md`, five branches. Two that produce a bewildering bug:

- **`ELYSIA-LIFE-03`** — a plugin without a `name` applied twice has its lifecycle executed **once**; the symptom is the hook running for half the routes.
- **`ELYSIA-LIFE-04`** — `onRequest` receives a `PreContext`, which has **no** `body`, `query`, `params` or `cookie`; it reads `undefined`, and `undefined` often passes as "no filter".

**The security rule:** an auth/authorization decision **never** uses `derive` (`ELYSIA-LIFE-02`) — `derive` runs **before** validation. Use `resolve` or `macro.resolve`.

---

## Step 4 — State

| Symptom | Cause | Rule |
| --- | --- | --- |
| frozen `store` value | a primitive destructured in the parameter — the reference is lost | `ELYSIA-LIFE-06` |
| mutated `decorate`, unpredictable behavior | `decorate` is immutable; mutable is `state` | `ELYSIA-LIFE-05` |

---

## Step 5 — Prove it

**The probe points; it does not prove.** `local` and `scoped` produce the same code inside the plugin: the difference only appears in the instance that consumes it.

`references/prova-de-escopo.md` carries the test `ELYSIA-LIFE-08` requires — a route of the **consuming** instance rejected without credentials. It is the only assertion that tells the two scopes apart.

---

## Step 6 — Report

```
`RULE-ID` — file:line
Symptom: <what does not happen>
Evidence: <the test, the log, or the registration order>
Cause: <one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

**Evidence is a test or the registration order**, not an impression.

---

## Step 7 — The cut: what is not lifecycle

An error arriving as `unknown` in Eden, `null` `data`, a type that lost routes, a header that "never arrives", a numeric body that fails, a flaky test with an async plugin, SSE that drops — **none of these is lifecycle**. The table with the owner of each is in `references/prova-de-escopo.md`.

---

## Example

An auth plugin whose test routes are rejected correctly, while the server's routes pass without credentials. S1 clean, S2 pointing at `.onBeforeHandle(verify)` without a scope — and the test on the consuming instance returning **200 where it should return 401**. The test that existed ran **inside** the plugin, and that is why it never caught it.

Full diagnosis: `references/exemplo-plugin-sem-escopo.md`.

---

## Related

- [Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) — source of this skill
- [Elysia](../../../knowledge-base/docs/elysia.md) § 6, § 7
- `elysia-build` · `elysia-schema` — the sibling skills
- `http-diagnose` — when the symptom is CORS in the browser
