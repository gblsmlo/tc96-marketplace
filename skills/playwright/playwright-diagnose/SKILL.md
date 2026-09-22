---
nome: playwright-diagnose
descricao: Diagnose a Playwright test that fails or fails intermittently, reading the trace before touching the code, with executable bisection and `PW-*` IDs — use when the task is investigating a flaky test, a failure that only happens in CI, a failure that only happens in parallel, a screenshot that differs for no reason, or a 30 s timeout with no apparent cause. Do not use to write a new test, which is playwright-build, to audit a whole suite with no concrete failure, which is playwright-review, nor for the suite as a system and its flakiness rate, which is test-diagnose.
tipo: skill
familia: playwright
idioma: en
fonte: "[Playwright - Debug e Trace](../../../knowledge-base/docs/playwright-debug-e-trace.md)"
docs:
  - /microsoft/playwright
tags:
  - skill
  - playwright
  - testing
  - flaky-tests
---

# playwright-diagnose

> **Source of this skill:** [Playwright - Debug e Trace](../../../knowledge-base/docs/playwright-debug-e-trace.md), with § 5.2 of the [Playwright](../../../knowledge-base/docs/playwright.md) hub as the diagnostic tree. The 85 rules of the `PW-*` family live in § 6 of the hub.
> This skill **does not contain** the text of the rules — it says what to obtain, in what order to read and how to eliminate hypotheses.
> **API surface:** resolve it through Context7 — `/microsoft/playwright`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Playwright](../../../knowledge-base/docs/playwright.md) § 7 ("Contrato de skill").

> **Design note.** This skill diagnoses **one test**. For the **suite as a system** — flakiness rate, trust, ability to detect a break — that is `test-diagnose`. The practical difference: here you read a trace; there you read the CI history. Arriving there with one red test, or here with "the suite is flaky", is using the wrong tool.

---

## When to use

One concrete test fails, or fails sometimes.

| Situation | Go to |
| --- | --- |
| writing or rewriting a test | `playwright-build` |
| auditing a suite with no concrete failure | `playwright-review` |
| the **suite** has lost credibility; measuring flakiness | `test-diagnose` |
| a failing test under `bun test` | `bun-test-review` |
| the failure is a real product defect | then **the test worked** — report the defect and stop |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Playwright](../../../knowledge-base/docs/playwright.md) § 0 | the timeout table — which one blew, and which |
| 2 | [Playwright](../../../knowledge-base/docs/playwright.md) § 5.2 | the diagnostic tree |
| 3 | [Playwright - Debug e Trace](../../../knowledge-base/docs/playwright-debug-e-trace.md) § 3 | reading the trace in four steps |
| 4 | `references/mapa-de-ids.md` | before citing — two IDs are aliases |
| 5 | the satellite for the cause | only **after** you have the cause |

References in this skill:

| File | What for |
| --- | --- |
| `references/leitura-do-trace.md` | how to obtain the trace and the four tabs, with the Log message table |
| `references/arvore-de-hipoteses.md` | the eight items of the tree and the bisection |
| `references/falha-so-em-ci.md` | the four CI causes, and the two traps that look like flakiness |
| `references/conserto-x-anestesico.md` | the seven anesthetics, the finding format and the closing |
| `references/mapa-de-ids.md` | the 85 `PW-*` by satellite and section |
| `references/exemplo-diagnostico.md` | a whole diagnosis, from the trace to the finding |
| `scripts/isolar.sh` | runs the bisection battery and prints the hypothesis each run eliminates |

---

## Step 0 — The question that comes before everything

> **Is the failure a real product defect?**

If so, **the test did its job**: report the defect and stop. Confusing "red test" with "bad test" is how a suite loses its ability to give signal.

---

## Step 1 — Obtain the trace

Without a configured trace, every CI failure is guesswork — and if `trace` is `'off'`, **the first finding is the configuration** (`PW-CFG-02`), not the test.

> **Never** use `--debug` to decide whether it is flakiness: it forces `timeout=0` and `workers=1`, so it **always passes** (`PW-DBG-02`).

Commands per situation: `references/leitura-do-trace.md`.

---

## Step 2 — Read the trace in four steps

**Errors** (which action failed) → the **Log** for that action (**at which check** it stalled) → **Snapshot Before** (what was on screen) → **Network**.

Step 2 is what no `console.log` gives, and it is where the cause appears: `element intercepts pointer events` is an overlay; `strict mode violation` is an ambiguous locator; `waiting for element to be visible` is a target that never appeared. Full table in the reference.

---

## Step 3 — Walk the tree, in order

`references/arvore-de-hipoteses.md`, eight items, **without skipping**. **What is never the answer:** raising `retries` (`PW-RUN-03`).

---

## Step 4 — Isolate by bisection

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-diagnose/scripts/isolar.sh e2e/checkout.spec.ts:52 20
```

`--repeat-each` confirms intermittency; `--workers=1` points at shared state; the case alone points at order dependence; the CI container points at environment parity.

> **`--workers=1` diagnoses; it does not fix.**

---

## Step 5 — A failure that only happens in CI

`references/falha-so-em-ci.md`: a slower CI, environment parity, server state, setup that did not run. Plus two traps that look like flakiness — a Service Worker intercepting before the `route` (`PW-NET-03`) and blocked images in a suite with screenshots (`PW-SNAP-06`).

---

## Step 6 — Report

Five parts, with **evidence from the trace and the tab**. "Looks like timing" is not evidence. If the cause is a product defect, the fix is in the product — saying so explicitly is this skill's main value. Format and example: `references/conserto-x-anestesico.md`.

---

## Step 7 — Fix × anesthetic

Seven fixes that make the red disappear without solving anything: `waitForTimeout`, `retries`, `force: true`, `workers: 1`, a global `expect.timeout`, a `skip` without an issue, and **removing the assertion** — the worst, and the one a healer with no declared spec does on its own (`PW-AGT-05`).

---

## Step 8 — Closing

1. **`--repeat-each=20`** confirms the fix. One green run proves nothing on a 1-in-4 flake.
2. **A product defect**: the test does not change — say so.
3. **Environment parity**: the fix is the pipeline.
4. **Turn the diagnosis into a gate** — trace on, flaky not counting as green.
5. **If the same test goes flaky again**, the root cause was not found (`TS-PROC-08`).
6. **Declare what was not verified.**

---

## Example

A click that fails ~25% in CI and passes locally. The **Log** tab gives the cause in one line — `element intercepts pointer events` — and the Snapshot Before shows the toast over the button. `force: true` is explicitly discarded: the defect belongs to the product, because the user cannot click either.

Full diagnosis: `references/exemplo-diagnostico.md`.

---

## Related

- [Playwright - Debug e Trace](../../../knowledge-base/docs/playwright-debug-e-trace.md) — source of this skill
- [Playwright](../../../knowledge-base/docs/playwright.md) § 5.2 — the diagnostic tree
- `playwright-build` · `playwright-review` — the sibling skills
- `test-diagnose` — diagnoses the **suite**; this one diagnoses **one test**
