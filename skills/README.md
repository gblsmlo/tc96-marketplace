# Skills

Skills are **procedures**: they say what to load, in what order, which step to follow and how to
report. They do **not** repeat the rule's text — they route to `knowledge-base/` and cite
by ID. Each skill declares its source note in the frontmatter (`fonte:`), so that an
update to the rule propagates without rewriting the skill.

Each skill is a **package**: a directory with `SKILL.md`, `references/` and, almost always,
`scripts/`. What enters the context before the skill decides what to open is only the `SKILL.md`.

Two sources, separated by the question: **API surface** (signature, option,
per-version behavior) comes from Context7, through the library ID the skill declares in `docs:`;
**the rule and the citation ID** come from `knowledge-base/`. A skill with no `docs:` has no upstream
library — testing is a concept, HTTP is RFCs.

```
skills/<family>/
├── README.md          the family's index and its decisions
└── <skill>/
    ├── SKILL.md       neutral frontmatter + the procedure
    ├── references/    supporting material, one file per decision
    └── scripts/       the probes, and the ID-map generator
```

## The thirteen families

| Family | Skills | Index |
| --- | --- | --- |
| **react** | `react-developer` · `react-review` · `react-audit` · `react-structure` · `react-hook-form` · `react-component-performance` — self-contained, with its own `docs/` | [react/](react/README.md) |
| **tanstack** | `tanstack-query` · `tanstack-router` · `tanstack-review` | [tanstack/](tanstack/README.md) |
| **storybook** | `storybook-setup` · `storybook-story` · `storybook-test` | [storybook/](storybook/README.md) |
| **tailwind** | `tailwind-setup` · `tailwind-migrate` · `tailwind-build` · `tailwind-split-variants` · `tailwind-review` — self-contained, docs inside each skill | [tailwind/](tailwind/README.md) |
| **test** | `test-design` · `test-review` · `test-diagnose` | [test/](test/README.md) |
| **playwright** | `playwright-build` · `playwright-review` · `playwright-diagnose` | [playwright/](playwright/README.md) |
| **bun** | `bun-runtime` · `bun-workspace` · `bun-migrate` · `bun-test-build` · `bun-test-review` — self-contained, with its own `docs/` | [bun/](bun/README.md) |
| **elysia** | `elysia-build` · `elysia-schema` · `elysia-eden` · `elysia-openapi` · `elysia-diagnose` — self-contained, with its own `docs/` | [elysia/](elysia/README.md) |
| **http** | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | [http/](http/README.md) |
| **drizzle** | `drizzle-query` · `drizzle-mutation` · `drizzle-zod` · `drizzle-review` — self-contained, with its own `docs/` | [drizzle/](drizzle/README.md) |
| **kb** | `kb-coverage` | [kb/](kb/README.md) |
| **design-docs** | `doc-prd` · `doc-adr` · `doc-epic` · `doc-feature` · `doc-story` · `doc-tasks` · `doc-bug` · `doc-spec` · `doc-pr` — writing-only document skills, each with its template; self-contained, with its own `docs/` | [design-docs/](design-docs/README.md) |
| **sdd** | `sdd-spec-writer` · `sdd-orchestrator` · `sdd-contract-review` — the Spec Driven Development delivery flow | [sdd/](sdd/README.md) |

All 54 are in the neutral source, in English, with `idioma: en` in the frontmatter.

The importer (`build/importar-do-plugin.py`) stays as a provenance record: it skips a skill
with `idioma: en`, because the hermes build it came from is Portuguese-only.
