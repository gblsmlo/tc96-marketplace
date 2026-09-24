---
nome: react-review
descricao: Review existing React code against the normative rules in the knowledge base, citing `REACT-*` IDs — fifteen executable probes before reading code, a five-level scan in the order that fails most, severity classification and a fixed finding format — use when the task is reviewing a PR, file, component or custom Hook that is already written, or hunting for a Rules of Hooks violation, a fetch in an Effect, state derived through an Effect, remote data in useState, prop mutation, Suspense without an Error Boundary, a Server Function without validation and memoization without measurement. Do not use to write new code, which is react-developer, to decide where the file lives, which is react-structure, for a form with validation and conditional fields, which is react-hook-form, nor to diagnose a component already confirmed slow, which is react-component-performance.
tipo: skill
familia: react
idioma: en
fonte: "[React - Rules of React](../../../knowledge-base/react-rules-of-react.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
---

# react-review

> **Source of this skill:** [React - Rules of React](../../../knowledge-base/react-rules-of-react.md), with the [React.js](../../../knowledge-base/react-js.md) hub as the router.
> This skill **does not contain** the content of the rules — it says what to run, what to load, in what order to scan and how to report. For a rule's text, open the source note: a docs update propagates here on its own, and any rule rewritten here would become an outdated copy.
> **API surface:** resolve it through Context7 — `/reactjs/react.dev`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [React.js](../../../knowledge-base/react-js.md) § 7 ("Contrato de skill").

---

## When to use

Reviewing React code that **already exists**: a PR, a file, a component, a custom Hook.

| If the question is… | Go to |
| --- | --- |
| writing a **new** component or Hook | `react-developer` |
| where this file lives, who imports whom | `react-structure` |
| a form with validation, conditional fields, field arrays | `react-hook-form` |
| a component **already confirmed slow**, needing a measured fix | *(vague route — see `memory/STACK.md`)* |

---

## Minimum loading

In this order, stopping when you have enough ([React.js](../../../knowledge-base/react-js.md) § 1 and § 7):

| Order | Load | Why |
| --- | --- | --- |
| 1 | [React - Rules of React](../../../knowledge-base/react-rules-of-react.md) (in full, focusing on § 5) | the normative base and the scan checklist |
| 2 | [React.js](../../../knowledge-base/react-js.md) § 6 and § 6.1 | the inviolable rules and the satellites' critical ones |
| 3 | `references/mapa-de-ids.md` | canonicals and aliases — required before citing |
| 4 | [React.js](../../../knowledge-base/react-js.md) § 4 | find out **which** satellite corresponds to the API touched |
| 5 | that domain's satellite | only when the finding requires the family's full text |
| 6 | [React - Patterns](../../../knowledge-base/react-patterns.md) | when the finding is structural (state ownership, composition, boundaries) |

**Never load all the satellites.** The hub's context-economy rule.

References in this skill — open only the one the step asks for:

| File | What for |
| --- | --- |
| `references/sondas.md` | the fifteen probes, what each one does **not** catch, and the false positives |
| `references/grade-de-varredura.md` | the five levels, in the order that fails most, with an ID per antipattern |
| `references/severidade-e-relatorio.md` | classification, finding format, the finding × opinion cut, the report's structure |
| `references/mapa-de-ids.md` | where each `REACT-*` is declared, and the list of aliases |
| `references/exemplo-relatorio-de-pr.md` | a whole report, from the probes to the closing |
| `scripts/sondas.sh` | runs the fifteen probes and prints the ID to cite in each block |
| `scripts/gerar-mapa-de-ids.sh` | regenerates `mapa-de-ids.md` from `knowledge-base/react*` |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/sondas.sh src
```

(in the vault, `bash ${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/sondas.sh src`; the default target is `src`, or `.` if there is none.)

**Probe 0 runs first and changes the verdict of the others**: React version, React Compiler active, the **lint net** (ESLint with the plugin, or Biome with the `react` domain switched on), `<StrictMode>` present. Reporting "memoization is missing" in a project with React Compiler active is an invalid finding, and it discredits the whole report.

A probe **is not a finding**: it says where to look. A finding requires reading the passage and a `file:line`. The four context probes (9, 11, 12, 13) need a reading of the parent file, of the topology or of the SSR config before becoming a finding. Detail and false positives in `references/sondas.md`.

---

## Step 2 — Scan in the order that fails most

`references/grade-de-varredura.md`, five levels:

1. **React's contract** — Hooks outside the top level, side effects in the render, mutation, a component called as a function. Blocking.
2. **Critical rules** in [React.js](../../../knowledge-base/react-js.md) § 6.1 — a fetch in an Effect, derived state, remote data in `useState`, Suspense without a boundary, memoization without measurement, a high `'use client'`, a Server Function without validation.
3. **Structure** — state placement, composition, boundaries, `key`, and the satellites' families.
4. **The domain's satellite** — only now, and only what the code touches (via [React.js](../../../knowledge-base/react-js.md) § 4).
5. **Style** — last, always subordinate to the previous ones.

If one level produces a finding that invalidates the next level's code — the whole Effect should not exist — **stop reviewing its interior** and report the removal, not a detail fix.

What the probes never catch, and therefore requires reading: `REACT-HOOK-01`, `REACT-CALL-01`, `REACT-CALL-02`, `REACT-PAT-02`, `REACT-PAT-03`, `REACT-PAT-10`, `REACT-ASYNC-09`.

---

## Step 3 — Classify and report

`references/severidade-e-relatorio.md`. Summary:

| Severity | What goes in |
| --- | --- |
| **Blocking** | `REACT-PURE-*`, `REACT-CALL-*`, `REACT-HOOK-*` |
| **High** | the critical rules in [React.js](../../../knowledge-base/react-js.md) § 6.1 |
| **Medium** | the other `REACT-*` from the satellite |
| **Low** | preference without an ID — **not a finding** |

A fixed four-part format:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change, not generic advice>
See the corresponding satellite.
```

**A finding without a rule ID is an opinion.** There is an ID → cite the canonical one. There is no ID but it is a documented antipattern → cite the **section** ([React - Patterns](../../../knowledge-base/react-patterns.md) § 8). Neither ID nor section → it goes to "Suggestions (no rule)", separately, or stays out. **Never invent an ID.**

---

## Step 4 — Closing the review

1. **Automate what you can.** Without a lint net and without `<StrictMode>`, half of Level 1 has no protection — and that is the **report's first finding**. In a Biome project, the net only exists with `linter.domains.react` switched on: `preset: recommended` does **not** enable the Hooks rules.
2. **Check whether the stack already solves it** before suggesting the raw primitive ([React.js](../../../knowledge-base/react-js.md) § 8).
3. **Order by severity**, not by file order.
4. **Declare what was not verified.** An API outside [React.js](../../../knowledge-base/react-js.md) § 4 has not been verified in this doc; silence about an unread file is read as approval.

If the `react*` notes changed since the last review, regenerate the map before citing:

```bash
bash plugins/tc96-frontend/skills/react-review/scripts/gerar-mapa-de-ids.sh # rewrites both skills' map
bash scripts/instalar.sh # and reinstalls the plugin
```

---

## Neighbors — when the review leaves React

A frontend PR is almost never only React. When the finding belongs to another layer, it belongs to that layer's skill, with that family's IDs — do not force a `REACT-*` on top of it.

| The layer touched is… | Skill | Source doc |
| --- | --- | --- |
| remote data, cache, invalidation, optimistic update | `tanstack-query` | [TanStack Query](../../../knowledge-base/tanstack-query.md) |
| routing, navigation, search params, loader | `tanstack-router` | [TanStack Router](../../../knowledge-base/tanstack-router.md) |
| a form with validation, conditionals, field arrays | `react-hook-form` | [React Hook Form](../../../knowledge-base/react-hook-form.md) |
| a story, controls, component docs | `storybook-story` · `storybook-setup` | [Storybook - Stories e Args](../../../knowledge-base/storybook-stories-e-args.md) |
| an interaction test inside the story, the **Vitest runner** | `storybook-test` | [Storybook - Testes e Interações](../../../knowledge-base/storybook-testes-e-interacoes.md) § 4 |
| **at which level** this test should be (unit × integration × e2e) | `test-design` | [Teste de Software - Níveis e Escopo](../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| does the suite protect anything? · nobody trusts it | `test-review` · `test-diagnose` | [Teste de Software](../../../knowledge-base/teste-de-software.md) |
| **unit and integration tests** under `bun test` | `bun-test-build` · `bun-test-review` | [Bun - Testes](../../../knowledge-base/bun-testes.md) |
| **e2e tests** — writing, auditing, diagnosing | `playwright-build` · `playwright-review` · `playwright-diagnose` | [Playwright](../../../knowledge-base/playwright.md) |
| an API route, handler, schema and lifecycle | `elysia-build` · `elysia-schema` · `elysia-diagnose` | [Elysia](../../../knowledge-base/elysia.md) |
| schema, migration, query, N+1 | `drizzle-review` | [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) |
| method, status, cache, CORS, the API contract | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | [HTTP](../../../knowledge-base/http.md) |

Two observations that prevent a wrong finding:

- **Vitest has no skill of its own in this vault.** It appears as the *runner* of `@storybook/addon-vitest`, running a story in a real browser through Playwright — [Storybook - Testes e Interações](../../../knowledge-base/storybook-testes-e-interacoes.md) § 4, and the cut between Vitest 3 and 4 is in § 4.2. A unit test outside Storybook is `bun test`, not Vitest.
- **The concept layer comes before the tool layer.** "Should this test exist, and at this level?" is `test-design`; "is this test right?" is the tool's skill. Skipping the first produces E2E by default, which is the highest-cost antipattern in this stack.

---

## Example

A customer search PR, three files. The probes point at six candidates in five minutes; the **reading** finds the blocking finding no probe sees (a `useState` after an early return, `REACT-HOOK-01`), and it reorders the whole report. A `useMemo` flagged by probe 6 does **not** become a finding, because it had documented measurement; the file's size goes to "Suggestions (no rule)"; a framework API outside [React.js](../../../knowledge-base/react-js.md) § 4 becomes a declaration of limitation, not an opinion.

Full report, from the probes to the closing: `references/exemplo-relatorio-de-pr.md`.

---

## Related

- `react-developer` — the sibling skill, for writing new code
- `react-structure` — where the file lives and who imports whom
- [React - Rules of React](../../../knowledge-base/react-rules-of-react.md) — source of this skill
- [React - Patterns](../../../knowledge-base/react-patterns.md) — structural decisions and the antipattern table
- [React.js](../../../knowledge-base/react-js.md) — the hub, API map, decision trees, skill contract
