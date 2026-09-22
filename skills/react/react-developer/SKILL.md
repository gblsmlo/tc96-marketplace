---
nome: react-developer
descricao: Write a new React component, custom Hook or feature — three structural questions before any code, API choice through the decision trees, a table of habits that produce violations, and an executable self-check before delivering, citing `REACT-*` IDs — use when the task is creating a component or Hook from scratch, deciding who owns the state, choosing between neighboring Hooks, extracting logic into a custom Hook, designing error and waiting boundaries, or composing instead of configuring. Do not use to review existing code, which is react-review, to decide where the file lives, which is react-structure, for a form with validation and conditional fields, which is react-hook-form, nor to diagnose a component already confirmed slow, which is react-component-performance.
tipo: skill
familia: react
idioma: en
fonte: "[React - Patterns](../../../knowledge-base/docs/react-patterns.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
---

# react-developer

> **Source of this skill:** [React - Patterns](../../../knowledge-base/docs/react-patterns.md) (structural decisions), with [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md) as the normative base and [React.js](../../../knowledge-base/docs/react-js.md) as the API router.
> This skill **does not repeat** the rules or the API surface — it defines the order of decisions and points at what to open at each point. The text of the rules lives in the source notes; an update there propagates here.
>
> Successor to `react-developer`, with the same procedure and the internal references that were missing.
> **API surface:** resolve it through Context7 — `/reactjs/react.dev`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [React.js](../../../knowledge-base/docs/react-js.md) § 7 ("Contrato de skill").

---

## When to use

Writing a **new** React component, custom Hook or feature — or rewriting a passage to the point where the structural decisions come back to the table.

| If the question is… | Go to |
| --- | --- |
| is this code that **already exists** correct? | `react-review` |
| where does this file live, who imports whom | `react-structure` |
| a form with validation, conditional fields, field arrays | `react-hook-form` |
| a component **already confirmed slow**, needing a measured fix | *(vague route — see `memory/STACK.md`)* |
| the data comes from a server and someone else can change it | `tanstack-query` |
| the state belongs to the URL (filter, tab, page) | `tanstack-router` |

---

## Minimum loading

Per [React.js](../../../knowledge-base/docs/react-js.md) § 7:

```
ALWAYS: React.js § 2 (mental model)
 React.js § 5 (decision trees)
 React.js § 6 + § 6.1 (normative and critical rules)
 React - Rules of React ← required when writing/editing components

BEFORE WRITING: React - Patterns § 1 to § 3

ON DEMAND: the satellite for the domain touched, discovered through React.js § 4

NEVER: all satellites at once
```

References in this skill — open only the one the step asks for:

| File | What for |
| --- | --- |
| `references/arvores-de-decisao.md` | which tree to walk, the four path mistakes, the short exits |
| `references/habitos-de-ia.md` | the reflex that produces each violation, and what to do instead |
| `references/autoverificacao.md` | the three passes and the ten `rg` probes before delivering |
| `references/mapa-de-ids.md` | where each `REACT-*` is declared, and the list of aliases |
| `references/exemplo-painel-de-faturas.md` | a worked case of the happy path |
| `references/exemplo-fronteira-de-servidor.md` | the robust variant: Server Function, validation, boundaries |
| `references/exemplo-antipadrao-corrigido.md` | the same component before and after, defect by ID |
| `scripts/autoverificar.sh` | runs the ten Step 5 probes over what you just wrote |

---

## Step 1 — The three structural questions, before any code

From [React - Patterns](../../../knowledge-base/docs/react-patterns.md) § 1. The order matters: composition chosen before data ownership almost always produces prop drilling.

1. **Whose data is this?** → state placement. Detail in [React - Patterns](../../../knowledge-base/docs/react-patterns.md) § 2.
2. **Who supplies the variable content?** → composition. Detail in [React - Patterns](../../../knowledge-base/docs/react-patterns.md) § 3.
3. **Where should a failure or a wait stop?** → boundaries (Error Boundary, `<Suspense>`, `'use client'`, the server). Detail in [React - Patterns](../../../knowledge-base/docs/react-patterns.md) § 6.

Answer all three **in writing**, one sentence each, before the first line of JSX. If you cannot answer 1, the problem is not the code: the data's origin has not been defined.

---

## Step 2 — Choose the API through the decision trees

Do not choose the Hook out of habit. Walk the corresponding tree in [React.js](../../../knowledge-base/docs/react-js.md) § 5 — the route, the path mistakes and the four short exits are in `references/arvores-de-decisao.md`.

| The task's symptom | Tree to walk |
| --- | --- |
| "I need to store a value" | *Preciso guardar um valor. Onde?* — first **where the data comes from**, then **in which component** |
| "I need to run a side effect" | *Preciso rodar um efeito colateral. Onde?* — the first question is whether it responds to an interaction |
| "the UI freezes" | *A UI trava durante uma atualização* — the order is normative and **does not start with memoization** |
| "I need to deal with something async" | *Preciso lidar com algo assíncrono* |

After choosing the API, confirm its source package in [React.js](../../../knowledge-base/docs/react-js.md) § 3 and the satellite in [React.js](../../../knowledge-base/docs/react-js.md) § 4. Open **only that** satellite.

**Before using the raw primitive, check [React.js](../../../knowledge-base/docs/react-js.md) § 8.** Remote data, caching, URL state, boundary validation and frequently written global state already have an answer in this stack — using `useEffect` + `useState` where the stack solves it is a regression, not simplicity.

---

## Step 3 — Writing

Keep [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md) loaded. Three anchors of the mental model ([React.js](../../../knowledge-base/docs/react-js.md) § 2) decide nearly everything:

- a component is a pure function of its inputs;
- state is a snapshot, not a variable;
- an Effect is synchronization with an external system, not "code that runs afterwards".

Vault convention: **every example in the docs is TypeScript**. No rule depends on types, but write TS by default.

---

## Step 4 — Do not fall into the automatic habits

`references/habitos-de-ia.md` is the full table, in seven sections: state and data, effects, composition and boundaries, performance, refs and the DOM, forms and the server, custom Hooks. It is not a review list — it is a decision to make **before** writing, because each line comes from a reflex.

The five that appear in almost all generated code:

| Habit | Instead of it | Rule |
| --- | --- | --- |
| a `fetch` inside a `useEffect` | a data-fetching library ([React.js](../../../knowledge-base/docs/react-js.md) § 8) | `REACT-EFFECT-06` |
| `useState` + `useEffect` for a computable value | compute it in the render, in the state's owner | `REACT-PAT-01` |
| `useState` for a filter, a tab, pagination | [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) search params | `REACT-PAT-10` |
| memoization "just in case" | measure first; and check whether the React Compiler is active | `REACT-PERF-01`, `REACT-PERF-02` |
| an Error Boundary only at the root | a boundary at the feature level, next to every data `<Suspense>` | `REACT-PAT-06`, `REACT-ASYNC-08` |

When citing any ID, use the canonical one — `references/mapa-de-ids.md` has the list of aliases that must **not** leave the docs.

---

## Step 5 — Self-check before delivering

`references/autoverificacao.md`, in full: three passes and ten `rg` probes.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-developer/scripts/autoverificar.sh src/features/invoices
```


1. **Normative checklist** — § 5 of [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md), ordered by failure frequency.
2. **Habits table** — for each line, did the code avoid the habit?
3. **Three closing questions** — does every `useState` survive the state tree? does every `useEffect` synchronize with a **nameable** external system? does every memoization have a measurement?

If any answer is "no", fix it before delivering — do not deliver with a caveat.

Two checks that change the code and therefore run **before** the first line: React Compiler active (`REACT-PERF-02`) and `eslint-plugin-react-hooks` configured. Both in `references/autoverificacao.md` § *Antes da primeira linha*.

---

## Neighbors — when the feature leaves React

Before writing the raw primitive, confirm whose layer it is. [React.js](../../../knowledge-base/docs/react-js.md) § 8 lists what the stack already solves; the table below says **which skill** carries the procedure.

| The layer is… | Skill | Source doc |
| --- | --- | --- |
| remote data, cache, invalidation, optimistic update | `tanstack-query` | [TanStack Query](../../../knowledge-base/docs/tanstack-query.md) |
| routing, navigation, search params, loader, code splitting | `tanstack-router` | [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) |
| a form with validation, conditional fields, field arrays | `react-hook-form` | [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) |
| where the file lives and who imports whom | `react-structure` | [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) |
| a story, args, controls, the docs page | `storybook-story` · `storybook-setup` | [Storybook - Stories e Args](../../../knowledge-base/docs/storybook-stories-e-args.md) |
| an interaction test in the story, the **Vitest runner** | `storybook-test` | [Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4 |
| **at which level** this test goes (unit × integration × e2e) | `test-design` | `Docs/Teste de Software - Níveis e Escopo.md` |
| **unit and integration** under `bun test` | `bun-test-build` · `bun-test-review` | `Docs/Bun - Testes.md` |
| **e2e** — writing, auditing, diagnosing | `playwright-build` · `playwright-review` · `playwright-diagnose` | `Docs/Playwright.md` |
| an API route, handler, schema and lifecycle | `elysia-build` · `elysia-schema` · `elysia-diagnose` | `Docs/Elysia.md` |
| schema, migration, query, N+1 | `drizzle-review` | `Docs/Drizzle ORM.md` |
| method, status, cache, CORS, the API contract | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | `Docs/HTTP.md` |

Three boundaries that tend to be crossed in the wrong direction:

- **Testing: concept before tool.** Deciding *the level* is `test-design`; writing is the tool's skill. Skipping the first produces E2E by default — the highest-cost antipattern in this stack.
- **Vitest has no skill of its own in this vault.** It is the *runner* of `@storybook/addon-vitest`, executing a story in a real browser through Playwright ([Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4; the cut between Vitest 3 and 4 is in § 4.2). A unit test outside Storybook is `bun test`.
- **Optimism has two owners.** If the data lives in Query's cache, the optimism belongs to the mutation, with a snapshot and a rollback; `useOptimistic` is for what does not live in a cache. Stacking the two violates `REACT-FORM-07`.

---

## Example

Task: *"an invoice panel with a status filter and the total of what is selected"*.

Step 1 identifies **three owners** — invoices (the server), the filter (the URL), the selection (the panel) — and the total as **derivable**. Step 2 walks the state tree once per owner, and three of the four exits end with no Hook at all. One `useState` remains and no `useEffect`; the intuitive version of the same screen has four and two.

Full case, with code and the scoreboard: `references/exemplo-painel-de-faturas.md`.
The variant with writes and a trust boundary: `references/exemplo-fronteira-de-servidor.md`.
The same component done wrong and then fixed, defect by ID: `references/exemplo-antipadrao-corrigido.md`.

---

## Related

- `react-review` — the sibling skill, for reviewing existing code
- `react-structure` — where the file lives and who imports whom
- [React - Patterns](../../../knowledge-base/docs/react-patterns.md) — source of this skill
- [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md) — the normative base, required when writing
- [React.js](../../../knowledge-base/docs/react-js.md) — the hub, API map, decision trees, bridges with the stack
