# React skills — developer, review, structure, hook-form, component-performance

Five skills, one directory each, with their own `references/` and `scripts/`. The common
anatomy described in [Skills index](../README.md) holds; the supporting material lives in its
own files instead of bloating the `SKILL.md`.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `react-developer` | writing a **new** component, Hook or feature | [React - Patterns](docs/react-patterns.md) | 4 references + 3 examples + 1 script |
| `react-review` | is this code that **already exists** correct? | [React - Rules of React](docs/react-rules-of-react.md) | 4 references + 1 report + 2 scripts |
| `react-structure` | **where** the file lives, who imports whom | [Feature-Based Architecture](docs/feature-based-architecture.md) | 3 references + 1 report + 2 scripts |
| `react-hook-form` | forms: capture, validation, submission | [React Hook Form](docs/react-hook-form.md) | 4 references + 1 example + 2 scripts |
| `react-component-performance` | a component **confirmed slow**: measure, fix, prove | [React - Performance Measurement](docs/react-performance-measurement.md) | 5 references + 1 harness + 1 example + 2 scripts |

Two axes separate the first four. Between `react-developer` and `react-review`, **new × already
exists** — and it is in the first words of each `description`. Between them and the other
two, **interior × boundary**: `react-structure` handles where the code lives and who may
import whom; `react-hook-form` handles a whole capability (form capture) that has a rule
family of its own, `RHF-*`. `react-component-performance` is a third axis, **measured ×
assumed**: it starts only when a slowness is confirmed, and its output is a before/after
comparison, not a review finding.

**In a PR, the order is `react-structure` → `react-review`.** Moving a file can erase the
interior finding, so reviewing the interior first is wasted work.

## The docs travel with the family

The normative notes — the `React.js` hub with its thirteen satellites, `React Hook Form` with its
three, `Feature-Based Architecture` and `Architecture in React`, 207 IDs in all — live in
[`docs/`](docs/react-js.md), not in the tc96 `knowledge-base/`. That is what lets each skill
work in a project that has nothing else from tc96:

| Layout | Where the docs are |
| --- | --- |
| this repository | `skills/react/docs/` — the skills link to `../docs/`, the references to `../../docs/` |
| the built plugin (`tc96-frontend`) | `docs/react/` at the plugin root — the build rewrites the links |
| a single `.skill` package | `docs/` inside the skill — only the notes it cites, and the notes those cite |
| `AGENTS.md` target | `skills/react/docs/`, nested as here |

The docs and the skills cite tc96 notes outside the family (`TanStack Query`,
`Storybook - Testes e Interações`, `Playwright`…) **by name in a code span**, never by link:
context when tc96 is installed, never a dependency.

`bash build/skill-packages.sh` produces one `dist/skills/<skill>.skill` per skill, each with its
docs closure and the sibling scripts it calls. `bash build/verificar.sh` then opens every package
in isolation and fails on any link, script or path that reaches outside it.

## What each package contains

```
react-developer/
├── SKILL.md
├── references/
│   ├── decision-trees.md             which tree to walk, 4 path mistakes, short exits
│   ├── ai-habits.md                  7 sections of reflexes that produce violations, with IDs
│   ├── self-check.md                 3 passes + 10 rg probes before delivering
│   ├── id-map.md                     generated: ID → satellite → section
│   ├── example-invoice-dashboard.md  the happy path
│   ├── example-server-boundary.md    the robust variant: Server Function, validation, boundaries
│   └── example-antipattern-fixed.md  before and after, defect by ID
└── scripts/
    └── self-check.sh                 runs the 10 Step 5 probes over the code just written

react-review/
├── SKILL.md
├── references/
│   ├── probes.md                     15 probes, false positives, and what they do not catch
│   ├── scan-grid.md                  5 levels in the order that fails most, with an ID per antipattern
│   ├── severity-and-report.md        classification, finding format, the finding × opinion cut
│   ├── id-map.md                     generated: ID → satellite → section
│   └── example-pr-report.md          a whole report, from the probes to the closing
└── scripts/
    ├── probes.sh                     runs the 15 probes and prints the ID to cite
    └── generate-id-map.sh            regenerates id-map.md for developer and review

react-structure/
├── SKILL.md
├── references/
│   ├── placement-tree.md             5 questions, the tree, import × duplicate × extract
│   ├── import-scan.md                scan order, what the probe does not catch, format
│   ├── id-map.md                     generated: ID → severity → who enforces it → section
│   └── example-structure-review.md   a whole PR review
└── scripts/
    ├── import-probes.sh              8 boundary probes, starting with enforcement
    └── generate-id-map.sh            regenerates from docs/feature-based-architecture.md

react-hook-form/
├── SKILL.md
├── references/
│   ├── tasks.md                      the 5 tasks, the order of decisions, what to check
│   ├── submission-owner.md           isSubmitting × isPending — pick one and declare it
│   ├── diagnosis.md                  symptom → likely cause → satellite
│   ├── id-map.md                     generated: 81 RHF-* IDs + the cross-doc citation rule
│   └── example-invoice-entry.md      from Step 0 to the submit
└── scripts/
    ├── probes.sh                     12 probes for an existing form
    └── generate-id-map.sh            regenerates from docs/react-hook-form*

react-component-performance/
├── SKILL.md
├── references/
│   ├── scenario-catalog.md           scenarios per view type, how to drive them, expected render counts
│   ├── noise-and-stats.md            iterations, the noise band, what a delta may claim
│   ├── memo-correctness.md           four ways memo goes stale, a test for each, the checklist
│   ├── readme-bench-section.md       the README ## Benchmark template, with a filled example
│   └── id-map.md                     generated: REACT-PERF-* and the IDs the skill cites
└── scripts/
    ├── probes.sh                     11 re-render hazard probes
    ├── bench-harness.ts              copyable JSDOM benchmark harness (bench-harness v1)
    ├── bench-compare.ts              compares two results files; --gate fails on render regressions
    ├── bench-result.schema.json      JSON Schema of the results file (bench-result/v1)
    └── example/bench-example.ts      runnable adapter against a tiny list
```

The harness is **copied** into the consumer project (`bench-harness.ts` and `bench-compare.ts`
together), never imported from the plugin: the project owns its benchmark, and the
`bench-harness v1` line at the top says which version it copied. It needs `bun`, and `react`,
`react-dom` and `jsdom` in the project; this repository has none of them, so the example runs from
a project that does.

## The ID map

**`id-map.md` is generated, not written** — in all five. It indexes the IDs by satellite and
section, and never carries the rule's **text**: a rule copied inside a skill becomes an outdated
replica. Three generators, one per rule family, because the sources and the columns differ:

| Generator | Family | Source | Columns |
| --- | --- | --- | --- |
| `react-review/scripts/generate-id-map.sh` | 114 `REACT-*` | `docs/react*` | satellite · section · aliases; also writes the scoped map of `react-component-performance` |
| `react-structure/scripts/generate-id-map.sh` | 12 `REACT-ARCH-*` | [Feature-Based Architecture](docs/feature-based-architecture.md) | **severity** · **who enforces it** · section |
| `react-hook-form/scripts/generate-id-map.sh` | 81 `RHF-*` | `docs/react-hook-form*` | satellite · section · cross-doc citation |

After editing any note in `docs/`, run the corresponding generator and rebuild:

```bash
bash skills/react/react-review/scripts/generate-id-map.sh
bash skills/react/react-structure/scripts/generate-id-map.sh
bash skills/react/react-hook-form/scripts/generate-id-map.sh
bash build/claude-code.sh
```

The generators are authoring tools: they are not shipped in the `.skill` packages, and the
regeneration block in `react-review` is wrapped in `<!-- authoring -->` markers that the
packager strips.

The **who enforces it** column only exists in `REACT-ARCH-*`, and it is the most actionable in
the group: it separates what Biome catches from what depends on human review — and it is what
decides whether a finding comes back in the next PR.

## The neighbors — what is **not** this family's

A frontend PR is almost never only React. When the subject belongs to another layer, the
procedure and the IDs belong to that layer's skill. The names below are tc96 notes outside this
family, cited by name on purpose:

| Layer | Skill | Source doc |
| --- | --- | --- |
| remote data, cache, invalidation, optimism | `tanstack-query` | `TanStack Query` |
| routing, navigation, search params, loader | `tanstack-router` | `TanStack Router` |
| configuring Storybook, writing a story | `storybook-setup` · `storybook-story` | `Storybook` |
| an interaction test in the story, the **Vitest** runner | `storybook-test` | `Storybook - Testes e Interações` § 4 |
| the test's **level**: unit × integration × e2e | `test-design` | `Teste de Software - Níveis e Escopo` |
| the suite as a system: does it protect? is it trustworthy? | `test-review` · `test-diagnose` | `Teste de Software` |
| **unit and integration** in `bun test` | `bun-test-build` · `bun-test-review` | `Bun - Testes` |
| **e2e** | `playwright-build` · `playwright-review` · `playwright-diagnose` | `Playwright` |
| an API route, schema and lifecycle | `elysia-build` · `elysia-schema` · `elysia-diagnose` | `Elysia` |
| persistence: schema, migration, query | `drizzle-review` | `Drizzle ORM` |
| the HTTP contract: method, status, cache, CORS | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | `HTTP` |
| runtime, dependencies, migrating from Node | `bun-runtime` · `bun-workspace` · `bun-migrate` | `Bun` |

Two boundaries that tend to be crossed in the wrong direction:

- **Testing: concept before tool.** *At which level* is `test-design`; *how to write it*
  is the tool's skill. Skipping the first produces E2E by default.
- **Vitest is not a skill here.** It appears as the runner of `@storybook/addon-vitest`,
  running a story in a real browser through Playwright (`Storybook - Testes e Interações` § 4;
  the cut between Vitest 3 and 4 in § 4.2). A unit test outside Storybook is `bun test`.

## Related

- [Skills index](../README.md) — the general index and the common anatomy
- [React.js](docs/react-js.md) § 7 — the contract the four implement
- `tailwind` — the other self-contained family, same layout
