---
name: react-review
description: Review React code that already exists — a PR, diff, file, component or custom Hook — against the `REACT-*` rules, with fifteen executable probes run before reading, a five-level scan in the order that fails most, fixed severity and a fixed finding format that cites the canonical ID and file:line. Use for "review this", "what is wrong here", "approve or block", or when hunting a Rules of Hooks violation, a fetch or derived state in an Effect, remote data in useState, prop mutation, Suspense without an Error Boundary, an unvalidated Server Function or memoization without measurement. Not for writing new code (react-developer), file placement and imports (react-structure), forms (react-hook-form), a whole-codebase health audit (react-audit) or a component confirmed slow (react-component-performance).
source: "[React - Rules of React](../../docs/react/react-rules-of-react.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
---

# react-review

> **Source:** [React - Rules of React](../../docs/react/react-rules-of-react.md), routed by the [React.js](../../docs/react/react-js.md) hub (§ 7 is the skill contract). This skill says what to run, load, scan and report; the rule text lives only in the docs, so it never goes stale here.
> **API surface:** Context7 `/reactjs/react.dev`. The rule and its ID come from the family's docs.

## Scope

Code that **already exists**, bounded by a diff or a file list. A defect in a file outside that bound goes to "Open items", never into a severity section, even when you infer it is related: the author can only fix what the PR touches. For anything else:

| The question is… | Go to |
| --- | --- |
| writing a **new** component or Hook | `react-developer` |
| where this file lives, who imports whom (runs **before** this skill in a PR) | `react-structure` |
| a form with validation, conditionals, field arrays | `react-hook-form` |
| the health of a whole codebase, not one change | `react-audit` |
| a component **confirmed slow** that needs a measured fix | `react-component-performance` |

## Load, in order, and stop when you have enough

| # | Load | Why |
| --- | --- | --- |
| 1 | [React - Rules of React](../../docs/react/react-rules-of-react.md), focus § 5 | normative base and scan checklist |
| 2 | [React.js](../../docs/react/react-js.md) § 6 and § 6.1 | inviolable and critical rules |
| 3 | `references/id-map.md` | canonical IDs and aliases, required before citing |
| 4 | [React.js](../../docs/react/react-js.md) § 4 | which satellite owns the API the code touches |
| 5 | that one satellite | only when a finding needs its full text |
| 6 | [React - Patterns](../../docs/react/react-patterns.md) | only for a structural finding: ownership, composition, boundaries |

Never load every satellite. Each reference file is opened only by the step that names it.

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/probes.sh <target>
```

`<target>` is the changed directory, or `src` (`.` if there is none). Pass the narrowest target the diff allows: probe noise grows with scope.

**Probe 0 changes the verdict of the others.** It reports the React version, React Compiler, the lint net (ESLint `react-hooks`, or Biome with `linter.domains.react` on) and `<StrictMode>`. "Memoization is missing" under an active Compiler is an invalid finding that discredits the whole report.

A probe points; it is **not a finding**. A finding needs the passage read and a `file:line`. Probes 9, 11, 12 and 13 need the parent file, the topology or the SSR config read first. False positives and blind spots: `references/probes.md`.

## Step 2 — Scan in the order that fails most

`references/scan-grid.md` has an ID per antipattern. Five levels:

1. **React's contract** — Hooks off the top level, side effects in render, mutation, a component called as a function. Blocking.
2. **Critical rules** ([React.js](../../docs/react/react-js.md) § 6.1) — fetch in an Effect, derived state, remote data in `useState`, Suspense without a boundary, unmeasured memoization, a high `'use client'`, an unvalidated Server Function.
3. **Structure** — state placement, composition, boundaries, `key`.
4. **The domain's satellite** — only what the code touches.
5. **Style** — last, always subordinate.

When a level invalidates the code below it (the whole Effect should not exist), stop reviewing that interior and report the removal.

No probe catches these, so read for them every time: `REACT-HOOK-01`, `REACT-CALL-01`, `REACT-CALL-02`, `REACT-PAT-02`, `REACT-PAT-03`, `REACT-PAT-10`, `REACT-ASYNC-09`.

## Step 3 — Classify and report

Full rules and the report skeleton: `references/severity-and-report.md`.

| Severity | Contains |
| --- | --- |
| **Blocking** | `REACT-PURE-*`, `REACT-CALL-*`, `REACT-HOOK-*` |
| **High** | the critical rules of [React.js](../../docs/react/react-js.md) § 6.1 |
| **Medium** | other `REACT-*` from a satellite |
| **Low** | preference without an ID, which is **not a finding** |

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change, not generic advice>
See <satellite> § <section>.
```

An ID exists → cite the canonical one. No ID, but a documented antipattern → cite the section ([React - Patterns](../../docs/react/react-patterns.md) § 8). Neither → "Suggestions (no rule)", apart, or left out. **Never invent an ID.**

## Step 4 — Close

1. **Missing automation is the first finding.** No lint net and no `<StrictMode>` leaves half of Level 1 unprotected. Biome's `recommended` preset does **not** enable the Hooks rules; only `linter.domains.react` does.
2. **Prefer what the stack already solves** over the raw primitive ([React.js](../../docs/react/react-js.md) § 8).
3. **Order by severity**, not by file.
4. **Declare what was not verified.** An API outside [React.js](../../docs/react/react-js.md) § 4, or a file not read, is named as unverified. Silence reads as approval.

<!-- authoring:start -->
After editing the `react*` notes in `docs/`, regenerate the maps and rebuild (source repository only):

```bash
bash skills/react/react-review/scripts/generate-id-map.sh   # id-map.md of react-developer, react-review, react-component-performance
bash build/claude-code.sh
```
<!-- authoring:end -->

## When the finding leaves React

Cite the owning skill and its IDs; never force a `REACT-*` onto another layer.

| Layer | Skill |
| --- | --- |
| remote data, cache, invalidation, optimistic update | `tanstack-query` |
| routing, navigation, search params, loader | `tanstack-router` |
| story · interaction test in a story (the Vitest runner) | `storybook-story` · `storybook-test` |
| which level a test belongs to · does the suite protect | `test-design` · `test-review` |
| `bun test` unit and integration · e2e | `bun-test-review` · `playwright-review` |
| API route and schema · persistence · HTTP contract | `elysia-build` · `drizzle-review` · `http-review` |

Vitest appears only as the runner of `@storybook/addon-vitest`; a unit test outside Storybook is `bun test`.

## Example

`references/example-pr-report.md`: a three-file customer search PR. Probes flag six candidates; the **reading** finds the blocking `useState` after an early return (`REACT-HOOK-01`) that no probe sees. A measured `useMemo` is not a finding, file size goes to suggestions, and an API outside § 4 becomes a declared limitation.
