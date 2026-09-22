---
nome: storybook-test
descricao: Turn a story into a component test in Storybook — `play`, `storybook/test`, module and network mocking, accessibility — citing `SB-TEST-*` and `SB-MOCK-*` IDs, always after discovering the project's framework path, with an executable self-check — use when the task is writing or reviewing an interaction test in a story, asserting a callback with `fn`, waiting for async data, mocking a module or the network for a story, or turning on the a11y scan. Do not use to configure Storybook from scratch, which is storybook-setup, to interpret coverage and assemble CI, which is the Cobertura e CI satellite, nor for a journey test, which is playwright-build.
tipo: skill
familia: storybook
idioma: en
fonte: "[Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md)"
docs:
  - /storybookjs/storybook
tags:
  - skill
  - storybook
  - testing
---

# storybook-test

> **Source of this skill:** [Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md), with the [Storybook](../../../knowledge-base/docs/storybook.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to discover, what to write and what to check.
> **API surface:** resolve it through Context7 — `/storybookjs/storybook`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Storybook](../../../knowledge-base/docs/storybook.md) § 7.

---

## Step 0 — Discover the framework path

**Before anything else.**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-setup/scripts/descobrir-caminho.sh
```

| `framework` | Path | Family | Note |
| --- | --- | --- | --- |
| `@storybook/tanstack-react` | **A** | `SB-TS-*` | [Storybook - TanStack React](../../../knowledge-base/docs/storybook-tanstack-react.md) |
| `@storybook/react-vite` | **B** | `SB-RV-*` | [Storybook - React Vite](../../../knowledge-base/docs/storybook-react-vite.md) |

This is **not a formality**. It is the only structure in this vault where prescribing the wrong path **fails silently**: under `react-vite`, `parameters.tanstack.*` has no effect at all (`SB-RV-04`); under `tanstack-react`, a decorator with `RouterProvider` creates a **second** router (`SB-TS-03`).

The two families are **mutually exclusive** — citing one against a project on the other path is an **invalid finding**. Detail: `references/caminho-do-framework.md`.

---

## When to use

Writing or reviewing an interaction test inside a story.

| Situation | Go to |
| --- | --- |
| configuring Storybook, an empty sidebar, versions | `storybook-setup` |
| the story itself: `args`, controls, docs | `storybook-story` |
| coverage and the CI job | [Storybook - Cobertura e CI](../../../knowledge-base/docs/storybook-cobertura-e-ci.md) |
| a journey with routing, session and network | `playwright-build` |
| unit and integration outside the browser | `bun-test-build` |
| **at which level** this test should be | `test-design` |

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | the `framework` field (Step 0) |
| 2 | [Storybook](../../../knowledge-base/docs/storybook.md) § 6 and § 6.2 |
| 3 | [Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md) |
| 4 | the note for the **discovered path** |
| 5 | [Storybook - Mocking](../../../knowledge-base/docs/storybook-mocking.md) when there is a module or network to replace |

References in this skill:

| File | What for |
| --- | --- |
| `references/caminho-do-framework.md` | Step 0, and why it differs from every other step in the vault |
| `references/play.md` | the story before the test, and how to write the `play` |
| `references/ambiente-e-a11y.md` | module and network mocking, and the accessibility scan |
| `references/autoverificacao.md` | the 14 items, and the one worth more than all of them |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 75 `SB-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/autoverificar.sh` | runs Step 0 **and** the mechanical items |

---

## Step 1 — The story, before the test

The `play` verifies what the story **already** establishes. If the story is not a state named by `args` (`SB-CSF-04`), the test will carry setup that belonged to the story — and it is `storybook-story` that resolves that.

---

## Step 2 — Writing the `play`

Every `expect` **awaited** (`SB-TEST-01`); the first query of an async story is **`findBy…`** (`SB-TEST-10`); a callback is **`fn` in `args`** (`SB-TEST-03`), not a function in `render`; queries by **role/label** (`SB-TEST-06`); no assertion about internal implementation (`SB-TEST-09`).

---

## Step 3 — Replacing the environment

`sb.mock` only in the **preview**; the behavior goes in `beforeEach` (`SB-MOCK-01`, `SB-MOCK-04`). A `beforeEach` that changes the environment **returns the cleanup** (`SB-CTX-08`).

---

## Step 4 — Accessibility

`a11y.test` is `'error'` where CI is expected to **fail** (`SB-TEST-04`) — at `'todo'` the scan exists and protects nothing.

---

## Step 5 — Self-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-test/scripts/autoverificar.sh src
vitest run --project=storybook # without `run` it enters watch mode
```

**The check worth more than the fourteen:** break the component on purpose and confirm the story goes **red**. If nothing breaks, the `play` asserts nothing (`TS-TEC-08`).

---

## Step 6 — Closing

1. **Confirm the path** before citing any `SB-TS-*` or `SB-RV-*`.
2. **If the test needed real routing, session and network**, it is not a component test — it is `playwright-build`.
3. **If the test is about pure logic**, it is cheaper in `bun-test-build`.
4. **Declare what you did not cover.**

---

## Example

A form story with submission: `fn` in `args` for the callback, `findBy…` for the field that appears after loading, a mock of the API module in the preview with the behavior in `beforeEach`, and `a11y.test: 'error'`. What habit would produce: an `expect` without `await` — which always passes — and a `getBy` as the first query, which fails on timing.

Full case: `references/exemplo.md`.

---

## Related

- [Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md) — source of this skill
- [Storybook - Mocking](../../../knowledge-base/docs/storybook-mocking.md) — module and network
- `storybook-setup` · `storybook-story` — the sibling skills
- `test-design` — decides the level, before this one
- `playwright-build` · `bun-test-build` — the other levels
