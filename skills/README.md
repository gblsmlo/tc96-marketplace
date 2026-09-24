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

## The eleven families

| Family | Skills | Index |
| --- | --- | --- |
| **react** | `react-developer` · `react-review` · `react-structure` · `react-hook-form` | [react/](react/README.md) |
| **tanstack** | `tanstack-query` · `tanstack-router` | [tanstack/](tanstack/README.md) |
| **storybook** | `storybook-setup` · `storybook-story` · `storybook-test` | [storybook/](storybook/README.md) |
| **test** | `test-design` · `test-review` · `test-diagnose` | [test/](test/README.md) |
| **playwright** | `playwright-build` · `playwright-review` · `playwright-diagnose` | [playwright/](playwright/README.md) |
| **bun** | `bun-runtime` · `bun-workspace` · `bun-migrate` · `bun-test-build` · `bun-test-review` | [bun/](bun/README.md) |
| **elysia** | `elysia-build` · `elysia-schema` · `elysia-diagnose` | [elysia/](elysia/README.md) |
| **http** | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | [http/](http/README.md) |
| **drizzle** | `drizzle-review` | [drizzle/](drizzle/README.md) |
| **kb** | `kb-coverage` | [kb/](kb/README.md) |
| **workflow** | `workflow-research` · `workflow-planning` · `workflow-implementation` · `workflow-validation` | [workflow/](workflow/README.md) |

All 33 are in the neutral source, in English, with `idioma: en` in the frontmatter.

The importer (`build/importar-do-plugin.py`) stays as a provenance record: it skips a skill
with `idioma: en`, because the hermes build it came from is Portuguese-only.
