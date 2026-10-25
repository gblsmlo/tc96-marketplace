---
name: react-structure
description: Decides where React code lives and who may import whom in a feature-based architecture, citing `REACT-ARCH-*` IDs, with eight executable import probes, a scan in the order that fails most and a staged migration. Use when creating a feature, placing a new file, reviewing a PR's imports, layers or barrels, extracting code into the shared layer, or configuring and migrating a repository's folder structure, aliases and Biome boundary rules. In a PR it runs before react-review, because moving a file can erase an interior finding. Not for the inside of a component: writing is react-developer, reviewing is react-review, and a whole-codebase health audit is react-audit.
source: "[Feature-Based Architecture](../../docs/react/feature-based-architecture.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
  - architecture
---

# react-structure

> **Source:** [Feature-Based Architecture](../../docs/react/feature-based-architecture.md) (structure, rules, enforcement; § 10 is the skill contract), with [Architecture in React](../../docs/react/architecture-in-react.md) routing the other decision axes. This skill holds neither rule text nor Biome configuration; what the note says wins.
> **API surface:** Context7 `/reactjs/react.dev`. The rule and its ID come from the family's docs.

## Scope

| The question is… | Go to |
| --- | --- |
| where does this file live? who may import it? | **this skill** |
| how do I write this component or Hook? | `react-developer` |
| is this existing component correct? | `react-review` |
| a form | `react-hook-form` |
| how do I define this route or load its data? | `tanstack-router` |

The skills compose in pairs: **creating a feature** — this one decides the structure, `react-developer` writes inside it; **extracting to shared** — this one picks the destination (`REACT-ARCH-08`), `react-developer` writes the module; **reviewing a PR** — this one covers the boundary, `react-review` the interior, and the structural finding comes first.

Before imposing the structure, check § 9 ("When not to use it"): a single-domain app does not need vertical slices.

## Load

```
ALWAYS                  § 2 (layers, dependency direction) · § 4 (REACT-ARCH-* and severity)
CREATING A FEATURE      § 3 (anatomy) + § 5 (examples in this stack)
MOVING CODE             § 8 (migration) + REACT-ARCH-08
REVIEWING AN IMPORT     § 6 (antipatterns) + § 7 (what the lint covers)
CONFIGURING A REPO      § 7 (biome.json, aliases) + § 8
ON DEMAND               Architecture in React § 2, for a decision that is not physical structure
NEVER                   invent a layer without recording it in the source note
```

References: `placement-tree.md` (five questions, the tree, import × duplicate × extract), `import-scan.md` (scan order, blind spots, format), `id-map.md` (ID → severity → **who enforces it** → section), `example-structure-review.md`.

## Routing by task

| Task | Steps |
| --- | --- |
| create a feature | 1 → 2 → 5 |
| place a new file · extract shared code | 2 → 5 |
| review structure and imports (PR, folder, repo) | 3 → 4 |
| configure a repo from scratch, or migrate | 6 |

A placement finding comes from the Step 3 scan; Step 2 decides where new things go, it does not audit what is placed.

## Step 1 — Five questions before creating a feature

In writing, one sentence each, before the first `mkdir` (§ 10): is it a domain? does it exist already? is the data remote? is this public? who will import it? Stalled answers and the "capability born shared" exception: `references/placement-tree.md`.

If question 1 has no clear answer, **stop**: the capability is undefined, and structuring now draws the wrong boundary (§ 9).

## Step 2 — The placement tree

Walk `references/placement-tree.md`. Two questions decide it: **does it know product vocabulary?** and, if so, **how many capabilities consume it?** `REACT-ARCH-08` answers *when to create a shared module*, not *whether I may import*; importing, duplicating and extracting are three moves, and § 4 breaks the tie.

## Step 3 — Scan imports, in the order that fails most

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-structure/scripts/import-probes.sh <target>
```

**Probe 0 is enforcement and runs first.** Without `biome.json` and the § 7 rules every finding below returns next PR, so the missing gate is the **first** finding.

Then: inverted direction (`REACT-ARCH-06`, `-07`) → deep import (`-05`) → own alias (`-04`) → barrel (`-02`, `-03`) → bloated route (`-09`) → placement (`-01`, `-08`) → convention (`-11`, `-12`). False positives and blind spots: `references/import-scan.md`. If the layer is wrong, do not review its imports.

## Step 4 — Report

Severity comes from `references/id-map.md`, the normative § 4 column. **Do not reclassify.** Dependency direction beats aesthetics (§ 10, invariant 2).

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See Feature-Based Architecture § <section>.
```

An ID in § 4 → finding. An antipattern in § 6 without ID → cite the section. Neither → "Suggestions (no rule)". **Never invent** a `REACT-ARCH-*`. Close by naming the IDs the lint would already catch if switched on: the *Enforced by* column shows which depend on human review and will return.

## Step 5 — Self-check before delivering

Run the § 10 checklist: barrel, dependency direction, `queryKey` invalidation, co-located test, naming. It does **not** check aliases; if you touched `paths`, check all three config files by hand. Then:

1. Did a new feature come from a **screen** instead of a **capability**?
2. Was anything moved to shared with fewer than three consumers?
3. Is a reported rule lint-verifiable but switched off? Then the real finding is the missing configuration.

`biome check src` passes, or the work is not done. Without `biome.json` or installed dependencies, say it is not runnable and report the missing configuration first. Unverifiable is reported as unverified, never as approved.

## Step 6 — Configure or migrate a repository

One PR per step, app green at each (§ 8): aliases → extract the genuinely generic → migrate one whole feature → barrels → `noImportCycles` → `noRestrictedImports` per layer → `features/core/` only when `REACT-ARCH-08` fires.

Where migrations break (§ 2, § 7):

- aliases must exist in **all three** of `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`, or it "works in the build, breaks in the test" (probe 0 measures it);
- a layer addressed through its barrel needs a `paths` entry **without** a wildcard;
- Biome `overrides` is **first-match-wins**: a top-level rule is replaced inside an override, not merged.

A Biome rule missing from the § 7 table is unverified: check `biomejs.dev` and update the source note, not this skill.

## Neighbors

| Layer | Skill |
| --- | --- |
| component interior: write · review | `react-developer` · `react-review` |
| routing · remote data and `queryKey` | `tanstack-router` · `tanstack-query` |
| workspace, monorepo aliases, lockfile | `bun-workspace` |

The `api/` file's **placement** is this skill's; its freshness policy is `tanstack-query`'s.

## Example

`references/example-structure-review.md`: a PR that extracts formatting into `libs/` and creates a "billing" feature. The reading shows the feature came from a screen (`REACT-ARCH-01`), which erases two interior findings; one file carries both `REACT-ARCH-06` and `REACT-ARCH-08`; the missing `biome.json` closes the report as the highest-return item.
