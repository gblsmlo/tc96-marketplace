---
name: react-developer
description: Write new React code — a component, custom Hook or feature — by answering three structural questions before any JSX, choosing each API through the decision trees instead of habit, avoiding the reflexes that produce violations, and running an executable self-check before delivering, citing `REACT-*` IDs. Use when creating a component or Hook from scratch, rewriting one until its structure is back on the table, deciding who owns a piece of state, choosing between neighboring Hooks, extracting a custom Hook, placing Error Boundaries and Suspense, or composing instead of configuring. Not for reviewing existing code (react-review), file placement (react-structure), forms with validation (react-hook-form) or a component confirmed slow (react-component-performance).
source: "[React - Patterns](../../docs/react/react-patterns.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
---

# react-developer

> **Source:** [React - Patterns](../../docs/react/react-patterns.md) for structural decisions, [React - Rules of React](../../docs/react/react-rules-of-react.md) as the normative base, [React.js](../../docs/react/react-js.md) as the API router (§ 7 is the skill contract). This skill orders the decisions and says what to open; rule text lives only in the docs.
> **API surface:** Context7 `/reactjs/react.dev`. The rule and its ID come from the family's docs.

## Scope

New code, or a rewrite deep enough that the structure is being decided again.

| The question is… | Go to |
| --- | --- |
| is existing code correct? | `react-review` |
| where the file lives, who imports whom | `react-structure` (decide it **before** writing the first file of a feature) |
| a form with validation, conditionals, field arrays | `react-hook-form` |
| a component **confirmed slow** | `react-component-performance` |
| data from a server that someone else can change | `tanstack-query` |
| state that belongs to the URL: filter, tab, page | `tanstack-router` |

## Load

```
ALWAYS        React.js § 2 (mental model), § 5 (decision trees), § 6 + § 6.1 (rules)
              React - Rules of React, kept loaded while writing
BEFORE CODE   React - Patterns § 1 to § 3
ON DEMAND     the one satellite for the API touched, found through React.js § 4
NEVER         every satellite at once
```

References, each opened only by the step that names it: `decision-trees.md`, `ai-habits.md`, `self-check.md`, `id-map.md`, and three worked examples.

## Step 0 — Two checks that change the code

Run them before the first line, because they change what you write ([`self-check.md`](references/self-check.md) § *Before the first line*):

- **React Compiler active?** If yes, do not hand-write `memo`/`useMemo`/`useCallback` (`REACT-PERF-02`).
- **Lint net present?** `eslint-plugin-react-hooks`, or Biome with `linter.domains.react` on. Without it, say so in the delivery.

## Step 1 — Three structural questions, in writing

From [React - Patterns](../../docs/react/react-patterns.md) § 1. Order matters: choosing composition before data ownership produces prop drilling.

1. **Whose data is this?** → state placement (§ 2).
2. **Who supplies the variable content?** → composition (§ 3).
3. **Where should a failure or a wait stop?** → Error Boundary, `<Suspense>`, `'use client'`, the server (§ 6).
   A boundary only catches what throws **below** it. When a route loader fetches the data, its failure surfaces at the route's `errorComponent`, never at an Error Boundary inside the component; put the retry UI where the throw lands (`tanstack-router`).

One sentence each, before any JSX. If 1 has no answer, the data's origin is undefined, and that is the problem to raise, not to code around.

## Step 2 — Choose the API through the trees

Walk the tree in [React.js](../../docs/react/react-js.md) § 5; path mistakes and short exits are in `references/decision-trees.md`.

| Symptom | Tree |
| --- | --- |
| "I need to store a value" | *Where do I keep a value?* — first where the data comes from, then which component |
| "I need a side effect" | *Where does a side effect run?* — first: does it respond to an interaction? |
| "the UI freezes" | *The UI freezes during an update* — the order is normative and does **not** start with memoization |
| "something async" | *I need to handle something asynchronous* |

Then confirm the API's package ([React.js](../../docs/react/react-js.md) § 3) and open only its satellite (§ 4). Before reaching for a raw primitive, check § 8: remote data, cache, URL state, boundary validation and hot global state already have an owner in this stack.

## Step 3 — Write

Three anchors decide nearly everything ([React.js](../../docs/react/react-js.md) § 2): a component is a pure function of its inputs; state is a snapshot, not a variable; an Effect synchronizes with an external system, it is not "code that runs afterwards". Write TypeScript by default.

Avoid the reflexes in `references/ai-habits.md` (seven sections). The five in almost all generated code:

| Habit | Instead | Rule |
| --- | --- | --- |
| `fetch` inside `useEffect` | a data-fetching library (§ 8) | `REACT-EFFECT-06` |
| `useState` + `useEffect` for a computable value | compute in render, in the owner | `REACT-PAT-01` |
| `useState` for filter, tab, page | the router's typed search params | `REACT-PAT-10` |
| memoization "just in case" | measure first; check the Compiler | `REACT-PERF-01`, `REACT-PERF-02` |
| one Error Boundary at the root | a boundary per feature, beside each data `<Suspense>` | `REACT-PAT-06`, `REACT-ASYNC-08` |

Cite only canonical IDs; `references/id-map.md` lists the aliases that must not leave the docs.

## Step 4 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-developer/scripts/self-check.sh <dir-you-wrote>
```

Any non-trivial derivation (a filter, a total, a status rule) lives in a pure function in the feature and gets a unit test, in the project's runner (`bun-test-build`). It is the cheapest proof the render logic is right, and it needs no DOM.

Then the three passes in `references/self-check.md`: the normative checklist ([React - Rules of React](../../docs/react/react-rules-of-react.md) § 5), the habits table, and three questions — does every `useState` survive the state tree, does every `useEffect` sync with a **nameable** external system, does every memoization have a measurement? A "no" is fixed before delivery, never shipped with a caveat.

Deliver with: the three Step 1 answers, the code, the self-check output pasted verbatim in a code block (a summary like "all clean" is not evidence), the test result, and anything left unverified.

## When the feature leaves React

| Layer | Skill |
| --- | --- |
| remote data, cache, invalidation, optimistic update | `tanstack-query` |
| routing, search params, loader, code splitting | `tanstack-router` |
| story · interaction test | `storybook-story` · `storybook-test` |
| which level the test belongs to · writing it | `test-design` · `bun-test-build` / `playwright-build` |
| API route and schema · HTTP contract | `elysia-build` · `http-contract` |

**Optimism has one owner.** Data in Query's cache → the mutation, with snapshot and rollback. `useOptimistic` only for what has no cache. Stacking both violates `REACT-FORM-07`.

## Examples

- `references/example-invoice-dashboard.md` — three owners (server, URL, panel), a derivable total: one `useState`, no `useEffect`, against four and two in the intuitive version.
- `references/example-server-boundary.md` — writes, a Server Function, validation and boundaries.
- `references/example-antipattern-fixed.md` — the same component before and after, defect by ID.
