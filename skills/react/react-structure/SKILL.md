---
nome: react-structure
descricao: Decide where React code lives and who may import whom in a feature-based architecture, citing `REACT-ARCH-*` IDs, with eight executable import probes, a scan in the order that fails most and staged migration — use when the task is creating a feature, placing a new file, reviewing a PR's imports, extracting code into the shared layer, or configuring and migrating a repository's structure. Do not use for the inside of a component — writing is react-developer, reviewing is react-review — and in a PR the structural finding comes first, because moving a file can erase the interior finding.
tipo: skill
familia: react
idioma: en
fonte: "[Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
  - architecture
---

# react-structure

> **Source of this skill:** [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) (structure, rules and enforcement), with [Architecture in React](../../../knowledge-base/pages/architecture-in-react.md) as the router for the other decision axes.
> This skill **contains** neither the text of the rules nor the Biome configuration — it says what to load, in what order to decide and how to report. A rule rewritten here would become an outdated copy.
>
> **Resolving the links:** the source note is `Pages/Feature-Based Architecture.md`. Do not confuse it with `Weblink/Feature-Based Architecture in React.md`, which is the external article it came from and is **not** normative here.
> **API surface:** resolve it through Context7 — `/reactjs/react.dev`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10, which in turn implements [React.js](../../../knowledge-base/docs/react-js.md) § 7.

---

## When to use

When the question is **where the code lives or who imports whom**: creating a feature, placing a new file, reviewing a PR's imports, extracting shared code, configuring or migrating a repository's structure.

| The question is… | Go to |
| --- | --- |
| where does this file live? who may import this? | **this skill** |
| how do I write this component or Hook? | `react-developer` |
| is this existing React code correct? | `react-review` |
| a form with validation, conditional fields, arrays | `react-hook-form` |
| how do I define this route, navigate, load data? | `tanstack-router` |

The skills compose, almost always in pairs:

- **creating a feature** — this one decides the structure, `react-developer` writes each component inside it;
- **extracting into the shared layer** — this one decides the destination (`REACT-ARCH-08`), `react-developer` writes the module in `features/core/`;
- **reviewing a PR** — this one covers the boundary (imports, layers, barrel), `react-review` covers the interior. A complete report runs both, and **the structural finding comes first**: moving a file can erase the interior finding.

---

## Minimum loading

Adapted from [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10 — the `ON DEMAND` line is this skill's addition:

```
ALWAYS: § 2 (layers and dependency direction)
 § 4 (REACT-ARCH-* rules and severity)

WHEN CREATING A FEATURE: § 3 (anatomy) + § 5 (examples in this stack)
WHEN MOVING CODE: § 8 (migration) + REACT-ARCH-08
WHEN REVIEWING AN IMPORT: § 6 (antipatterns) + § 7 (what the lint covers)
WHEN CONFIGURING A REPO: § 7 (biome.json, aliases) + § 8

ON DEMAND: Architecture in React § 2, when the decision is not
 about physical structure and needs another axis

NEVER: invent a new layer without recording it in the source note
```

References in this skill — open only the one the step asks for:

| File | What for |
| --- | --- |
| `references/arvore-de-colocacao.md` | the five questions, the tree, and import × duplicate × extract |
| `references/varredura-de-imports.md` | the scan order, what the probe does not catch, format and the cut |
| `references/mapa-de-ids.md` | ID → severity → **who enforces it** (lint or review) → section |
| `references/exemplo-revisao-de-estrutura.md` | a whole PR review, from the probes to the closing |
| `scripts/sondas-imports.sh` | eight boundary probes, in the order that fails most |
| `scripts/gerar-mapa-de-ids.sh` | regenerates `mapa-de-ids.md` from the source note |

Before deciding something is overkill, check § 9 ("Quando não usar"). A single-domain app does not need this structure, and imposing the vertical slice on it is this skill's antipattern.

---

## Routing by task

| Task | Steps |
| --- | --- |
| Creating a new feature | 1 → 2 → 5 |
| Placing a new file | 2 → 5 |
| Reviewing structure and imports (PR, folder, repo) | 3 → 4 |
| Extracting shared code | 2 → 5 |
| Configuring a repo from scratch, or migrating | 6 |

A **placement** finding ("this should not be here") comes out of the Step 3 scan — you do not need to run Step 2 to audit. Step 2 decides where to put things; it does not audit what is already placed.

---

## Step 1 — The five questions before creating a feature

A normative order ([Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10). Answer them **in writing**, one sentence each, before the first `mkdir`: is it a domain? does the domain already exist? is the data remote? is this public? who is going to import this?

The full table, with what to do when each answer stalls, and the "capability born shared" exception: `references/arvore-de-colocacao.md`.

If question 1 has no clear answer, **stop**: the problem is not structural, it is that the capability has not been defined yet. Structuring before that produces the wrong boundary (§ 9).

---

## Step 2 — The placement tree

Walk `references/arvore-de-colocacao.md`. Two questions decide everything: **does it know product vocabulary?** and, if so, **how many capabilities consume it?**

The most common mistake is not about the tree, it is about vocabulary: `REACT-ARCH-08` answers *when to create a shared module*, **not** *whether I may import*. Importing, duplicating and extracting are three different moves, and the table in § 4 breaks the tie.

---

## Step 3 — Scan imports, in the order that fails most

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-structure/scripts/sondas-imports.sh src
```

**Probe 0 is about enforcement and runs first**: without `biome.json` and without the rules in § 7, every finding below repeats in the next PR — and that is the **first finding of the report**, not a footnote.

Then, in order: inverted direction (`REACT-ARCH-06`, `-07`) → deep import (`-05`) → own alias (`-04`) → barrel (`-02`, `-03`) → bloated route (`-09`) → placement (`-01`, `-08`) → convention (`-11`, `-12`). Detail, false positives and what the probe does **not** catch: `references/varredura-de-imports.md`.

Stop detailing a file when a finding invalidates the next one: if the layer is wrong, do not review its imports.

---

## Step 4 — Report

Severity comes from `references/mapa-de-ids.md` — the normative column of § 4, **do not reclassify**. Dependency direction beats aesthetics, always (§ 10, invariant 2).

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See Feature-Based Architecture § <section>.
```

**A finding without an ID is an opinion.** There is an ID in § 4 → a finding. It is an antipattern in § 6 with no ID → cite the section. Neither → "Suggestions (no rule)", separately. **Never invent** a `REACT-ARCH-*`.

When closing, **declare what the lint would already cover**. The *Enforced by* column of the map says which IDs depend on human review: those are the ones that come back in the next PR.

---

## Step 5 — Self-check before delivering

Run the checklist in [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10 in full: barrel, dependency direction, `queryKey` invalidation, co-located test, naming convention. **It does not verify aliases** — that is Step 6; if you touched `paths`, check the three files by hand.

Three closing questions:

1. Did any new feature come out of a **screen** instead of a **capability**?
2. Was anything extracted into the shared layer with fewer than three consumers?
3. Is any rule I reported verifiable by the lint and simply was not switched on?

If 3 is "yes", the real finding is the missing configuration, not the individual violation.

`pnpm biome check src` passes or the work is not done. **If the project has no `biome.json` or no installed dependencies**, the command is not runnable — declare that, and treat the missing configuration as the first finding. An item that cannot be verified is reported as not verified, never as approved.

---

## Step 6 — Configuring or migrating a repository

Do not reorganize everything in one PR. The order in § 8 keeps the app green at each step: aliases → extract the genuinely generic → migrate a whole feature → barrels → `noImportCycles` → `noRestrictedImports` per layer → `features/core/` only when `REACT-ARCH-08` fires.

Three points where migrations usually break (§ 2 and § 7):

- the aliases have to exist in **all three** files — `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`. Divergence shows up as "works in the build, breaks in the test" (probe 0 measures that);
- a layer addressed through the barrel needs the entry **without** a wildcard in `paths`, otherwise the bare import does not resolve;
- Biome's `overrides` is **first-match-wins**: a top-level rule does not add to an override — it is replaced.

One PR per step. If a Biome rule is not in the § 7 table, it has not been verified: consult `biomejs.dev` and update the **source note**, not this skill (§ 10, invariants 4 and 5).

---

## Neighbors — when the decision leaves structure

| The layer is… | Skill |
| --- | --- |
| the component's interior: writing · reviewing | `react-developer` · `react-review` |
| a form | `react-hook-form` |
| routing, navigation, search params, loader | `tanstack-router` |
| remote data, `queryKey`, invalidation | `tanstack-query` |
| a story and a component test | `storybook-story` · `storybook-test` |
| the test's **level** (unit × integration × e2e) | `test-design` |
| unit and integration in `bun test` · e2e | `bun-test-build` · `playwright-build` |
| an API route and schema · persistence · the HTTP contract | `elysia-build` · `drizzle-review` · `http-contract` |
| workspace, monorepo aliases, lockfile | `bun-workspace` |

Where the `queryKey` lives and how it is invalidated is a boundary shared with `tanstack-query`: the **placement** of the `api/` file is this skill's; the **freshness policy** is theirs.

---

## Example

A PR that extracts formatting into `libs/` and creates a "billing" feature. The probes point at six candidates; the **reading** shows that the feature came out of a screen, not a capability (`REACT-ARCH-01`) — and that erases two interior findings that would have been wasted work. The same file comes out with `REACT-ARCH-06` **and** `REACT-ARCH-08`, which are different defects. The absence of `biome.json` closes the report as the highest-return item.

Full report: `references/exemplo-revisao-de-estrutura.md`.

---

## Related

- [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) — source of this skill: structure, `REACT-ARCH-*` rules, enforcement
- [Architecture in React](../../../knowledge-base/pages/architecture-in-react.md) — router for the other architectural decision axes
- `react-developer` — write the component that lives in the structure decided here
- `react-review` — review the interior; this skill reviews the boundary
- [React.js](../../../knowledge-base/docs/react-js.md) § 7 — the original skill contract
