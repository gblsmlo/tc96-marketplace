---
name: elysia-diagnose
description: Diagnose why an Elysia hook, plugin, guard or onError does not affect a route, or why state behaves strangely — registration order, `local`/`scoped`/`global` scope and `as()`, plugin `name` and dedup, `derive` × `resolve`, `onRequest`'s PreContext, `store` and `decorate`, macros, async plugins, tracing span names, `cors` defaults — citing `ELYSIA-LIFE-*` and `ELYSIA-CORE-01` IDs, with an AST probe and a scope test that proves the cause. Use when an auth plugin does not protect the app's routes, a hook runs for some routes and not others, a hook runs twice, `onRequest` reads undefined, a route is 404 only in tests, a store value looks frozen, or spans are named anonymous. Do not use to write new routes or plugins (elysia-build), for schema or typed-client problems (elysia-schema, elysia-eden), nor for a request the browser blocks (http-diagnose).
fonte: "[Elysia - Lifecycle and Plugins](../../docs/elysia/elysia-lifecycle-and-plugins.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-diagnose

> **Source of this skill:** [Elysia - Lifecycle and Plugins](../../docs/elysia/elysia-lifecycle-and-plugins.md) — § 0.3 is the "why does my plugin not affect this route" tree, and every `ELYSIA-LIFE-*` rule has its body there.
> **API surface:** resolve it through Context7 — `/websites/elysiajs`, topics `lifecycle`, `plugin`, `scope`, `macro`. Signatures come from there; the rule and the ID come from the family docs.

Elysia's lifecycle fails in the quietest possible way: nothing throws, nothing warns, the route simply does not pass through the hook. Reading the plugin rarely settles it, because `local` and `scoped` produce identical code inside the plugin — the difference only exists in the instance that consumes it. This skill eliminates hypotheses in the order they fail, and closes each one with evidence: a probe that points, then a test that proves.

---

## When to use

| Situation | Go to |
| --- | --- |
| writing a route, a plugin or auth from scratch | `elysia-build` |
| a validation error, a field that disappears, a header "never sent" | `elysia-schema` |
| the client gets `unknown`, `null` data, `any`, or a query that never errors | `elysia-eden` |
| a route missing from `/openapi/json` | `elysia-openapi` |
| the browser blocks a request (preflight, CORS) | `http-diagnose` |
| a flaky test in general | `bun-test-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | `references/id-map.md` | which doc and section holds each rule the probe names |
| 2 | [Elysia - Lifecycle and Plugins](../../docs/elysia/elysia-lifecycle-and-plugins.md) § 0, § 2, § 5 | only when the probe points at scope, order or a hook phase |
| 3 | [Elysia - Routing and Handler](../../docs/elysia/elysia-routing-and-handler.md) § 5, § 6 | only when the symptom is `onError`, a 404 in tests, or `app.modules` |

| File | What for |
| --- | --- |
| `references/probes-and-proof.md` | what each probe means, the scope test that proves `local` × `scoped`, and the symptoms that are not lifecycle |
| `references/example.md` | a whole diagnosis, from the probe to the finding |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `scripts/probes.sh` | version line, then the AST scan (groups `lifecycle` and `route`) |
| `scripts/elysia-scan.mjs` | the AST scan itself, shared by the whole family |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-diagnose/scripts/probes.sh .
```

It prints findings with `file:line` and a confidence. `high` is the shape of the defect; `candidate` needs reading. It never proves absence.

## Step 2 — Eliminate in this order

1. **Order** (`ELYSIA-CORE-01`) — a hook, `.use()` or `onError` reaches only routes registered after it. `onRequest` is the only global one.
2. **Scope** (`ELYSIA-LIFE-01`) — a plugin's hooks are `local` by default and do not reach the instance that `.use()`s it. `scoped` climbs **one** level: through an intermediate plugin, that plugin also needs `.as('scoped')`, or the hook is `global` (`ELYSIA-LIFE-09`).
3. **Dedup** (`ELYSIA-LIFE-03`) — an unnamed plugin used by two instances runs its global hooks **twice** per request; with `name` they run once.
4. **Phase** — `onRequest` has no `body`, `query`, `params`, `cookie` **or `headers`** (`ELYSIA-LIFE-04`); `derive` runs before validation, so it must not decide access (`ELYSIA-LIFE-02`).
5. **Error routing** — a module's `onError` runs **after** the parent's handlers registered before `.use()`: a catch-all in the app that answers every code swallows the module's codes. A thrown `status(404)` reaches `onError` as `code === 404`.
6. **Async registration** (`ELYSIA-CORE-10`) — a lazy `import()` plugin exists only after `await app.modules`; an async plugin *function* still pending when the first request arrived keeps its route 404 **for good**.
7. **State** — `decorate` is shared and immutable by contract (`ELYSIA-LIFE-05`); a `store` primitive destructured in the parameter is a snapshot taken at that moment, stale against writes later in the same call (`ELYSIA-LIFE-06`).

The tree with every branch is § 0.3 of the doc.

## Step 3 — Prove it

The probe points; a test proves. For scope, the only assertion that separates `local` from `scoped` hits a route of the **consuming** instance (`ELYSIA-LIFE-08`) — the template is in `references/probes-and-proof.md`. Use `http://localhost/...` in `app.handle`: a one-label host such as `http://x/` answers 404 for every route and fakes a "the route does not exist" symptom.

## Step 4 — Report

```
`RULE-ID` — file:line
Symptom: <what does not happen>
Evidence: <the test and its output, or the registration order>
Cause: <one sentence>
Fix: <the concrete change>
```

Evidence is a test result or the registration order, not an impression. Write every rule ID in full (`ELYSIA-LIFE-01`, never `-01`). Say what you did not verify.

---

## Example

"Our auth plugin works in its own tests, but `PATCH /profile/rename` on the server answers without a token." The probe shows `.onBeforeHandle(verify)` in `packages/auth` with no scope (`ELYSIA-LIFE-01`, high) and no order problem. A test on the consuming app hits `PATCH /profile/rename` without a token: **200**. With `.resolve({ as: 'scoped' }, …)` returning `status(401, …)`: 401 — and the hook's `throw new Error` (a 500) became a typed 401 (`ELYSIA-LIFE-10`). Full trace: `references/example.md`.
