# TanStack skills: query, router, review

Three skills, one directory each. The family is **self-contained**: its normative docs live in
[`docs/`](docs/tanstack-query.md), not in the tc96 `knowledge-base/` (the sixteen Portuguese notes were
removed on 2026-10-25), and every `.skill` package carries them.

| Skill | The question it answers | Source |
| --- | --- | --- |
| `tanstack-query` | how do I read, write, cache or paginate data someone else can change? | [TanStack Query](docs/tanstack-query.md) |
| `tanstack-router` | how do I declare this route, navigate, keep state in the URL, load or guard it? | [TanStack Router](docs/tanstack-router.md) |
| `tanstack-review` | what is wrong with this Query/Router code, or why does it misbehave? | both hubs, § 5.1 and § 6.1 |

## Why three, not two

The old pair mixed writing with reviewing, and neither had a finding format: `code-reviewer` had no TanStack
skill to route a PR to. `tanstack-review` owns the probes, the symptom tables and the report; the two
writing skills run the same probes as a self-check on the files they touched.

## Docs

Two hubs and fourteen satellites, one per old note, with the same rule IDs (55 `TSQ-*`, 102 `TSR-*`) and the
same section numbers, so every "§ N" citation still holds. Translation dropped the "Relacionados" and review
checklist sections (every item mapped to a declared ID) and moved the upstream source lists to
`docs/SOURCES.md`, which no skill links and no build target ships. Every doc over 100 lines has a table of
contents.

Re-checked against the installed packages on 2026-10-25 (`@tanstack/react-query` 5.104.5,
`@tanstack/react-router` 1.170.46, `@tanstack/router-plugin`):

- mutation callbacks are `onError(error, variables, onMutateResult, context)`; the old skill implied the
  rollback reads "the wrong object" in the old form, but the snapshot was the third argument in both. The real
  trap is reading `context.previous` from the new fourth argument;
- `mutationOptions` exists (the old note marked it unverified);
- `codeSplittingOptions.splitBehavior` returns `CodeSplitGroupings` (an array of arrays); the old example
  returned a string.

## Scripts

- `tanstack-review/scripts/probes.sh <dir> [all|query|router]`: 13 Query and 16 Router probes on `rg` and
  `perl`. Block-aware checks replaced the line greps where those missed or over-fired: a key missing a variable
  its `queryFn` interpolates, an invalidation whose key root matches no query, a rollback reading the fourth
  argument, a snapshot in `.current`, `defaultPreloadStaleTime` searched across the project instead of only
  `./router.*`, the Zod v3 probe skipped on Zod 4.
- `tanstack-review/scripts/generate-id-map.sh`: writes `references/id-map.md`, ID to doc and section in about
  2.3k tokens (the two old maps were 7.7k).

## Evals

Two cases per skill under `<skill>/evals/<case>/`, in the layout `claude plugin eval` reads, each with a
type-checking fixture in `files/` and one grader per verifiable statement.

<!-- eval:inicio -->
Results on 2026-10-25, one run per configuration, against the old skills with their knowledge-base notes. Tokens
and time are per run (mean of six cases); pass rate counts graded statements, blind to the configuration.

| Iteration | New skills | Old skills | Tokens per run | Time per run |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 59/59 | 58/59 | 105k vs 127k (-18%) | 173 s vs 235 s (-26%) |
| 2 (after the fixes iteration 1 surfaced) | 59/59 | 58/59 | 101k vs 127k (-20%) | 160 s vs 235 s (-32%) |

Five of six cases tie on pass rate; the old notes were long but mostly right. The one split: the old review flagged
the clean `customersQuery.ts`. Iteration 1 also corrected two graders and fed three facts back into the docs: the
deprecated `ensureQueryData`/`fetchQuery`/`prefetchQuery` (`TSR-LOAD-16` reworded), `maxPages` with
`getPreviousPageParam`, plus five probe false positives, one miss and one wrong line number the runs reported.
Iteration 2 reran only the new skills; its old-skill column is the iteration-1 baseline.
<!-- eval:fim -->

<!-- tokens:inicio -->
## Context budget

Measured with tiktoken (`cl100k_base`) on 2026-10-25. **Before step 1** is what a skill loads before it starts work.

| Skill | description | `SKILL.md` | before step 1 | loads |
| --- | ---: | ---: | ---: | --- |
| `tanstack-query` | 18 | 1.611 | 4.9k-5.9k | one satellite (3.3k-4.3k) |
| `tanstack-router` | 18 | 1.369 | 2.9k-7.1k | one satellite (1.6k-5.8k) |
| `tanstack-review` | 20 | 1.041 | 1.0k | probes first; `id-map.md` (2.3k) and one section per finding |

The old `tanstack-query` loaded its `SKILL.md`, the Portuguese hub and `por-tarefa.md` before step 1: **9.127**, plus a
satellite. The three descriptions cost **56** tokens against **260** for the old two. The sixteen docs total
**59.312** tokens against **89.924** for the Portuguese notes (-34%); `docs/SOURCES.md` (3.1k) ships nowhere.
<!-- tokens:fim -->
