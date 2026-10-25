---
name: react-audit
description: Audit the health of a whole React codebase or app, not one change — runs every probe set of the React family in one pass (rules, imports and layers, forms, re-render hazards), aggregates hits per rule and per hotspot file, confirms each pattern by sampling, and returns a prioritized backlog that puts missing enforcement first, citing `REACT-*`, `REACT-ARCH-*` and `RHF-*` IDs. Use for "audit our frontend", "how healthy is this React code", "where do we start fixing", "what should the lint enforce", onboarding onto an inherited codebase, or before a large refactor or migration. Not for reviewing a PR or diff (react-review, react-structure), writing code (react-developer), or measuring a slow component (react-component-performance).
fonte: "[React.js](../../docs/react/react-js.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
  - audit
---

# react-audit

> **Source:** the [React.js](../../docs/react/react-js.md) hub (§ 6 and § 6.1 are the rules an audit weighs most), [Feature-Based Architecture](../../docs/react/feature-based-architecture.md) § 4 and § 7 for structure and enforcement, and [React Hook Form](../../docs/react/react-hook-form.md) § 6 for forms. This skill aggregates and prioritizes; the rule text lives only in the docs.
> **API surface:** Context7 `/reactjs/react.dev`.

## Scope

An audit answers **"where is this codebase weakest, and what do we fix first?"** A review answers "is this change correct?" They differ in three ways: the audit's unit is a **pattern** across files, not a line; it **samples** instead of reading everything; its output is a **backlog**, not a block/approve verdict.

| The question is… | Go to |
| --- | --- |
| is this PR or diff correct? | `react-structure` then `react-review` |
| writing or rewriting a component | `react-developer` |
| a component confirmed slow | `react-component-performance` |
| the layers of a monorepo across packages | `monorepo-auditor` agent |

## Load

```
ALWAYS      React.js § 6 + § 6.1 · Feature-Based Architecture § 4 (severity) and § 7 (what the lint covers)
WHEN FORMS  React Hook Form § 6 — only if Step 1 found useForm(
TO CITE     references/id-map.md (generated from the siblings' maps)
NEVER       the satellites up front; open one only to confirm a sampled finding
```

## Step 1 — Run every probe set once

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-audit/scripts/audit.sh <target> <out-dir>
```

`<target>` is the app's source root (`src`, or `apps/<name>/src` in a monorepo; run once per app). `<out-dir>` defaults to `.react-audit`; keep it out of version control. The script runs the probes of `react-review`, `react-structure`, `react-hook-form` (only when `useForm(` exists) and `react-component-performance`, then prints:

1. **Inventory** — source files, components, tests, stories.
2. **Environment and enforcement** — React version, Compiler, lint net, Biome react domain, boundary rules, aliases, `<StrictMode>`.
3. **Hits per probe**, highest first, with the top file of each.
4. **Hotspots** — files hit by the most distinct probes.

Raw output stays in `<out-dir>/<family>.txt` for Step 3. A hit is a **lead**; nothing is a finding yet.

## Step 2 — Read the environment first

The enforcement block changes the meaning of every row:

- **No lint net** (no `eslint-plugin-react-hooks`, Biome without `linter.domains.react`) → every `REACT-HOOK-*` and `REACT-EFFECT-02/03` hit will come back. That gap is backlog item 1.
- **No boundary rules** (`noRestrictedImports`, `noImportCycles`) → the same for `REACT-ARCH-*`.
- **React Compiler active** → drop the memoization rows; manual memo is the wrong lever (`REACT-PERF-02`).
- **No `<StrictMode>`** → impure render goes unnoticed in development (`REACT-DOM-06`).
- **Aliases diverge** between `tsconfig`, `vite.config`, `vitest.config` → "works in build, breaks in test".

## Step 3 — Confirm by sampling

For each row with hits, read up to **three** occurrences, starting with the top file and then different files. Record `confirmed / sampled`. Rules:

- A row with 0 confirmed is a probe false positive: drop it and say so in one line.
- A pattern is **systemic** when it is confirmed in two or more files. Systemic patterns are fixed by a rule or a refactor, not file by file.
- Some IDs no probe catches. Read the **hotspot** files in full once, looking for `REACT-HOOK-01` (Hook after an early return), `REACT-CALL-01/02`, `REACT-PAT-02`, `REACT-PAT-03` and `REACT-PAT-10`.
- Never report a hit count as a finding. Report "`n` hit lines, `k/m` sampled confirmed".

False positives per probe are documented by the owning skill (`references/probes.md`, `import-scan.md`, `diagnosis.md`); this package's `references/false-positives.md` lists the ones that change an audit verdict.

## Step 4 — Prioritize into a backlog

Order, and do not reorder by taste:

| Tier | What | Why first |
| --- | --- | --- |
| 0 | enforcement gaps: lint net, Biome react domain, boundary rules, StrictMode, alias divergence | each one makes every later fix regress |
| 1 | confirmed **Blocking**: `REACT-PURE-*`, `REACT-CALL-*`, `REACT-HOOK-*` | React's contract; wrong behavior, not style |
| 2 | **systemic High**: critical rules of React.js § 6.1, `REACT-ARCH-06/07` direction | one decision fixes many files |
| 3 | isolated High and form rules (`RHF-*`) | file-local fixes |
| 4 | Medium, with the probe that will keep it fixed | — |

For each item give: ID, confirmed count and files, one sampled `file:line`, the concrete fix, the **owning skill** for the fix, and whether a lint rule can enforce it afterwards. Fill `references/audit-report.md`.

## Step 5 — Close honestly

- State the coverage: target, files, which probe sets ran, how many rows sampled, which hotspots read in full.
- State what an audit cannot see: runtime performance (needs `react-component-performance`), behavior without tests, and any API outside [React.js](../../docs/react/react-js.md) § 4.
- Recommend at most **three** next actions, the first one always from tier 0 when it is not empty.

## Neighbors

| Layer | Skill |
| --- | --- |
| fixing an item: interior · structure · forms | `react-developer` · `react-structure` · `react-hook-form` |
| remote data, cache · routing and search params | `tanstack-query` · `tanstack-router` |
| the test suite's shape and trust | `test-review` |
