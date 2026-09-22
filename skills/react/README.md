# React skills — a grouped family

Four skills, one directory each, with their own `references/` and `scripts/`. It is the first
group in the vault organized as a **package** rather than as loose files: the common anatomy
described in [Skills index](../README.md) still holds, and the only change is that the
supporting material got its own files instead of bloating the `SKILL.md`.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `react-developer` | writing a **new** component, Hook or feature | [React - Patterns](../../knowledge-base/docs/react-patterns.md) | 4 references + 3 examples + 1 script |
| `react-review` | is this code that **already exists** correct? | [React - Rules of React](../../knowledge-base/docs/react-rules-of-react.md) | 4 references + 1 report + 2 scripts |
| `react-structure` | **where** the file lives, who imports whom | [Feature-Based Architecture](../../knowledge-base/pages/feature-based-architecture.md) | 3 references + 1 report + 2 scripts |
| `react-hook-form` | forms: capture, validation, submission | [React Hook Form](../../knowledge-base/docs/react-hook-form.md) | 4 references + 1 example + 2 scripts |

Two axes separate the four. Between `react-developer` and `react-review`, **new × already
exists** — and it is in the first words of each `description`. Between them and the other
two, **interior × boundary**: `react-structure` handles where the code lives and who
may import whom; `react-hook-form` handles a whole capability (form capture) that has a
rule family of its own, `RHF-*`.

**In a PR, the order is `react-structure` → `react-review`.** Moving a file can erase the
interior finding, so reviewing the interior first is wasted work.

## What each package contains

```
react-developer/
├── SKILL.md
└── references/
 ├── arvores-de-decisao.md which tree to walk, 4 path mistakes, short exits
 ├── habitos-de-ia.md 7 sections of reflexes that produce violations, with IDs
 ├── autoverificacao.md 3 passes + 10 rg probes before delivering
 ├── mapa-de-ids.md generated: ID → satellite → section
 ├── exemplo-painel-de-faturas.md the happy path
│ ├── exemplo-fronteira-de-servidor.md the robust variant: Server Function, validation, boundaries
│ └── exemplo-antipadrao-corrigido.md before and after, defect by ID
└── scripts/
 └── autoverificar.sh runs the 10 Step 5 probes over the code just written

react-review/
├── SKILL.md
├── references/
│ ├── sondas.md 15 probes, false positives, and what they do not catch
│ ├── grade-de-varredura.md 5 levels in the order that fails most, with an ID per antipattern
│ ├── severidade-e-relatorio.md classification, finding format, the finding × opinion cut
│ ├── mapa-de-ids.md generated: ID → satellite → section
│ └── exemplo-relatorio-de-pr.md a whole report, from the probes to the closing
└── scripts/
 ├── sondas.sh runs the 15 probes and prints the ID to cite
 └── gerar-mapa-de-ids.sh regenerates mapa-de-ids.md for developer and review

react-structure/
├── SKILL.md
├── references/
│ ├── arvore-de-colocacao.md 5 questions, the tree, import × duplicate × extract
│ ├── varredura-de-imports.md scan order, what the probe does not catch, format
│ ├── mapa-de-ids.md generated: ID → severity → who enforces it → section
│ └── exemplo-revisao-de-estrutura.md a whole PR review
└── scripts/
 ├── sondas-imports.sh 8 boundary probes, starting with enforcement
 └── gerar-mapa-de-ids.sh regenerates from Pages/Feature-Based Architecture.md

react-hook-form/
├── SKILL.md
├── references/
│ ├── tarefas.md the 5 tasks, the order of decisions, what to check
│ ├── dono-da-submissao.md isSubmitting × isPending — pick one and declare it
│ ├── diagnostico.md symptom → likely cause → satellite
│ ├── mapa-de-ids.md generated: 81 RHF-* IDs + the cross-doc citation rule
│ └── exemplo-lancamento-de-fatura.md from Step 0 to the submit
└── scripts/
 ├── sondas.sh 12 probes for an existing form
 └── gerar-mapa-de-ids.sh regenerates from Docs/React Hook Form*
```

**`mapa-de-ids.md` is generated, not written** — in all four. It indexes the IDs by satellite and
section, and never carries the rule's **text**: a rule copied inside a skill becomes an outdated
replica. Three generators, one per family, because the sources and the columns differ:

| Generator | Family | Source | Columns |
| --- | --- | --- | --- |
| `react-review/scripts/gerar-mapa-de-ids.sh` | 105 `REACT-*` | `Docs/React*` | satellite · section · aliases |
| `react-structure/scripts/gerar-mapa-de-ids.sh` | 12 `REACT-ARCH-*` | `Pages/Feature-Based Architecture.md` | **severity** · **who enforces it** · section |
| `react-hook-form/scripts/gerar-mapa-de-ids.sh` | 81 `RHF-*` | `Docs/React Hook Form*` | satellite · section · cross-doc citation |

After editing any source note, run the corresponding generator and reinstall:

```bash
bash plugins/hermes-frontend/skills/react-review/scripts/gerar-mapa-de-ids.sh
bash plugins/hermes-frontend/skills/react-structure/scripts/gerar-mapa-de-ids.sh
bash plugins/hermes-frontend/skills/react-hook-form/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

The **who enforces it** column only exists in `REACT-ARCH-*`, and it is the most actionable in the group:
it separates what Biome catches from what depends on human review — and it is what decides whether a
finding comes back in the next PR.

## The neighbors — what is **not** these two's

A frontend PR is almost never only React. When the subject belongs to another layer, the
procedure and the IDs belong to that layer's skill:

| Layer | Skill | Source doc |
| --- | --- | --- |
| remote data, cache, invalidation, optimism | `tanstack-query` | [TanStack Query](../../knowledge-base/docs/tanstack-query.md) |
| routing, navigation, search params, loader | `tanstack-router` | [TanStack Router](../../knowledge-base/docs/tanstack-router.md) |
| a component confirmed slow, a measured fix | *(rota vaga — ver `memory/STACK.md`)* | — |
| configuring Storybook, writing a story | `storybook-setup` · `storybook-story` | [Storybook](../../knowledge-base/docs/storybook.md) |
| an interaction test in the story, the **Vitest** runner | `storybook-test` | [Storybook - Testes e Interações](../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4 |
| the test's **level**: unit × integration × e2e | `test-design` | `Docs/Teste de Software - Níveis e Escopo.md` |
| the suite as a system: does it protect? is it trustworthy? | `test-review` · `test-diagnose` | `Docs/Teste de Software.md` |
| **unit and integration** in `bun test` | `bun-test-build` · `bun-test-review` | `Docs/Bun - Testes.md` |
| **e2e** | `playwright-build` · `playwright-review` · `playwright-diagnose` | `Docs/Playwright.md` |
| an API route, schema and lifecycle | `elysia-build` · `elysia-schema` · `elysia-diagnose` | `Docs/Elysia.md` |
| persistence: schema, migration, query | `drizzle-review` | `Docs/Drizzle ORM.md` |
| the HTTP contract: method, status, cache, CORS | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | `Docs/HTTP.md` |
| runtime, dependencies, migrating from Node | `bun-runtime` · `bun-workspace` · `bun-migrate` | `Docs/Bun.md` |

Two boundaries that tend to be crossed in the wrong direction:

- **Testing: concept before tool.** *At which level* is `test-design`; *how to write it*
 is the tool's skill. Skipping the first produces E2E by default.
- **Vitest is not a skill in this vault.** It appears as the runner of `@storybook/addon-vitest`,
 running a story in a real browser through Playwright ([Storybook - Testes e Interações](../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4;
 the cut between Vitest 3 and 4 in § 4.2). A unit test outside Storybook is `bun test`.

## Validation

All four pass `skill-validator check` with **0 errors**. Two warnings remain per skill,
`unrecognized field: "tags"` and `unrecognized field: "fonte"` — they are this vault's convention
(the common anatomy requires `fonte:` in the frontmatter so that a docs update propagates) and
they stay by decision, not by oversight.

```bash
for s in plugins/hermes-frontend/skills/react-*/; do skill-validator check "$s"; done
```

<!-- tokens:inicio -->
## Context budget

Measured by `skill-validator` (tiktoken), on 2026-09-05. **The number that matters is the
`SKILL.md` column**: it is what enters the context before the skill decides what to open.
References load on demand, one at a time.

| Skill | `SKILL.md` | largest `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `react-developer` | 2.804 | `mapa-de-ids.md` (3.539) | 14.791 | 7 |
| `react-hook-form` | 2.223 | `mapa-de-ids.md` (3.424) | 10.308 | 5 |
| `react-review` | 2.531 | `mapa-de-ids.md` (3.539) | 12.304 | 5 |
| `react-structure` | 2.775 | `exemplo-revisao-de-estrutura.md` (1.210) | 6.534 | 4 |

Loading all 4 skills in this group at once would cost **10.333 tokens** in `SKILL.md` alone,
and **43.937** with every reference. That is why each skill declares what it must **never** load.

Regenerate: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) — the general index and the common anatomy
- [React.js](../../knowledge-base/docs/react-js.md) § 7 — the contract both implement
