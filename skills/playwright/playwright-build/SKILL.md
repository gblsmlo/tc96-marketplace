---
nome: playwright-build
descricao: Write a new E2E test with Playwright — locators in priority order, web-first assertions, structure, and an executable 12-item self-check before delivering, citing `PW-*` IDs from the knowledge base — use when the task is writing or editing a `*.spec.ts`, covering a user journey, building a page object or fixture, preparing state through the API, or replacing network, clock and session in a test. Do not use to review an existing suite, which is playwright-review, to diagnose a test that already fails, which is playwright-diagnose, nor to decide whether the test should be E2E — that decision comes earlier, in test-design.
tipo: skill
familia: playwright
idioma: en
fonte: "[Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md)"
docs:
  - /microsoft/playwright
tags:
  - skill
  - playwright
  - testing
  - e2e
---

# playwright-build

> **Source of this skill:** [Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md) and [Playwright - Assertions](../../../knowledge-base/docs/playwright-assertions.md), with the [Playwright](../../../knowledge-base/docs/playwright.md) hub as the router. The 85 rules of the `PW-*` family live in § 6 of the hub, with the full body in the satellite that owns each ID.
> This skill **does not contain** the text of the rules — it says what to load, in what order to decide and what to check before delivering.
> **API surface:** resolve it through Context7 — `/microsoft/playwright`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Playwright](../../../knowledge-base/docs/playwright.md) § 7 ("Contrato de skill").
Structure verified against playwright.dev on **2026-08-20**, over `@playwright/test` 1.62.1.

---

## When to use

Writing or editing a test that **will exist**: a new `*.spec.ts`, one more case, a page object, a fixture, an authentication setup.

| Situation | Go to |
| --- | --- |
| reviewing a suite that already exists | `playwright-review` |
| a test that fails, or fails sometimes | `playwright-diagnose` — **read the trace before editing** |
| deciding **whether** this should be E2E | `test-design` — and the answer is usually "no" |
| a unit or integration test under Bun | `bun-test-build` |
| a component's visual state | `storybook-story` · `storybook-test` |
| wiring test agents into the repository | [Playwright - Agents, CLI e MCP](../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |

**The cut this skill applies before anything:** if what can go wrong is a **business rule**, the test is not E2E (`TS-CORE-02`). E2E covers critical journeys; a rule goes to the cheapest layer.

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Playwright](../../../knowledge-base/docs/playwright.md) § 0 | the Node floor and the timeout table — `actionTimeout` is `0`, not 30 s |
| 2 | [Playwright](../../../knowledge-base/docs/playwright.md) § 2 | a locator is a lazy query; the waiting belongs to the tool |
| 3 | [Playwright](../../../knowledge-base/docs/playwright.md) § 6 and § 6.1 | the inviolable rules and the satellites' critical ones |
| 4 | [Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md) | no test exists without a locator |
| 5 | [Playwright - Assertions](../../../knowledge-base/docs/playwright-assertions.md) | the inseparable pair of step 4 |
| 6 | the satellite for the surface touched | via § 4 of the hub — network, auth, fixtures, snapshots |

**Never load all twelve satellites.** A simple flow test needs 1–5.

References in this skill:

| File | What for |
| --- | --- |
| `references/locator-e-assercao.md` | the priority order, what to do with ambiguity, the assertion table |
| `references/ambiente-e-estrutura.md` | what to replace, page objects, fixtures, the three invariants |
| `references/autoverificacao.md` | the 12 items and the three checks that are worth most |
| `references/antipadroes.md` | 30 antipatterns with ID and satellite |
| `references/mapa-de-ids.md` | the 85 `PW-*` by satellite and section, and the two aliases |
| `references/exemplo-pedido-na-lista.md` | worked case, from the three questions to the self-check |
| `scripts/autoverificar.sh` | runs the 12 items over the file you just wrote |

---

## Step 1 — Three questions before the first line

| Question | If the answer is… |
| --- | --- |
| **What can go wrong here?** | I cannot say → the test should not be written yet |
| **Is this a journey, or a rule?** | a rule → it is not E2E. Go to `bun-test-build` |
| **Does this state already exist, or do I have to create it?** | create → **through the API**, not through the UI (`PW-NET-06`) |

---

## Step 2 — Locator, in priority order

`getByRole` → `getByLabel`/`getByPlaceholder`/`getByAltText`/`getByText` → `getByTestId` (with the debt recorded) → CSS (with justification).

**Ambiguity is not resolved with `.first`** (`PW-LOC-02`): `filter({ hasText })`, a container, `filter({ has })`. If `getByRole` cannot reach it, the finding is usually about the **component**.

Detail: `references/locator-e-assercao.md`.

---

## Step 3 — Assertions

**Assert on the condition, never on a read value** (`PW-EXP-01`). And the twin defect, which passes **always**: a web-first assertion without `await` (`PW-CORE-04`) — the only automatic defense is `no-floating-promises`.

Never assert absence on its own (`PW-EXP-06`). `toPass` without a `timeout` is a finding (`PW-EXP-03`).

---

## Step 4 — Environment: what to replace

> **If the real dependency diverged, should this test break?** Yes → do not replace it.

Third-party network, browser APIs, the clock and the session get replaced; **server state gets created for real** through `request` (`PW-NET-06`). The mock's shape derives from the server's type (`PW-NET-04`). Table: `references/ambiente-e-estrutura.md`.

---

## Step 5 — Structure

A page object for a sequence of actions; a fixture for setup with a lifecycle; a setup project for login. Three invariants that generate rework: a page object **without** business assertions (`PW-STR-02`), a page object returns a `Locator` and not a `Promise<string>`, and `test`/`expect` from a **single** module in the project (`PW-FIX-05`).

---

## Step 6 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-build/scripts/autoverificar.sh e2e/orders.spec.ts
```

Twelve items, plus the three that are worth most: **break the code on purpose** and watch the test go red (`TS-TEC-08`), `--repeat-each=5`, and running the whole suite.

---

## Step 7 — Closing

1. **`--repeat-each=5`** on the new file. Green five times, not once.
2. **The whole suite still passes** — a new test that dirties state breaks its neighbor.
3. **If you needed `getByTestId` or CSS**, record the debt (`PW-LOC-04`).
4. **If it turned out slow or fragile**, the question is about level — `test-design`.
5. **Declare what you did not cover** (`TS-TIPO-02`).

---

## Example

*"The created order appears in the list."* The third question in Step 1 swaps twelve clicks for one `POST`, and the test starts failing for **one** reason. The locator is `getByRole('row').filter({ hasText })` — not `.nth(1)`; the assertion is web-first; the navigation is relative.

Full case: `references/exemplo-pedido-na-lista.md`.

---

## Related

- [Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md) — source of this skill
- [Playwright - Assertions](../../../knowledge-base/docs/playwright-assertions.md) — the second source, inseparable from the first
- [Playwright](../../../knowledge-base/docs/playwright.md) — the hub: § 0, § 2, § 5, § 6, § 7
- `playwright-review` · `playwright-diagnose` — the sibling skills
- `test-design` — decides **whether** the test is E2E, before this skill starts
- `bun-test-build` · `storybook-test` — the other levels
