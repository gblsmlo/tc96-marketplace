# Drizzle skills — query, mutation, zod, review

Four skills, one directory each, with their own `references/`, `scripts/` and `evals/`. The family is
**self-contained**: its normative docs live in [`docs/`](docs/drizzle-orm.md), not in the tc96
`knowledge-base/` (the three Portuguese notes were removed on 2026-10-24).

| Skill | The question it answers | Source |
| --- | --- | --- |
| `drizzle-query` | how do I read this — relations, N+1, pagination? | [Drizzle - Reads and Relations](docs/drizzle-reads-and-relations.md) |
| `drizzle-mutation` | how do I write this — upsert, guarded update, transaction? | [Drizzle - Writes and Transactions](docs/drizzle-writes-and-transactions.md) |
| `drizzle-zod` | which Zod schema guards this table at the route boundary? | [Drizzle - Zod](docs/drizzle-zod.md) |
| `drizzle-review` | does this persistence layer have defects? | [Drizzle ORM](docs/drizzle-orm.md) + the ID map |

## Docs

Hub [Drizzle ORM](docs/drizzle-orm.md) plus four satellites, one per context: schema and migrations,
reads, writes, zod. Each satellite carries its own decision tree, rules and antipatterns, so a skill
loads one of them. Behaviour marked *verified* was executed on drizzle-orm 0.45.4, drizzle-kit 0.31.11,
drizzle-zod 0.8.3 and zod 4.6.7 (and 3.25.76) on PGlite.

Rules added on 2026-10-24 from that verification: `DRZ-QUERY-07`, `DRZ-TX-04`, `DRZ-TX-05`,
`DRZ-ZOD-03`–`07`. House convention added on 2026-10-25: `DRZ-CORE-03` — a data-access function takes
`db: Database` first and its input as one typed object (hub § 10). Two claims of the old notes were corrected: `tx.rollback()` rejects the awaited
transaction, and the per-field `extras` callback is v1 syntax.

## Scripts

- `drizzle-review/scripts/drizzle-scan.mjs` — an AST scan (TypeScript compiler API) with groups
  `schema`, `query`, `mutation`, `zod`; findings are `high` or `candidate`. The build skills'
  `self-check.sh` call it as a sibling; the packager copies it into each `.skill`.
- `drizzle-review/scripts/probes.sh` — P0 version, P2 snapshot chain, P3 push, plus the scan.
- `drizzle-review/scripts/generate-id-map.sh` — writes each skill's `references/id-map.md`
  (authoring only).

<!-- tokens:inicio -->
## Context budget

Measured with tiktoken (`cl100k_base`) on 2026-10-25. **`SKILL.md`** is what enters the context when
the skill triggers. **Before step 1** adds what the skill marks as mandatory to load — never more than
one doc.

| Skill | `SKILL.md` | all references | before step 1 | loads |
| --- | ---: | ---: | ---: | --- |
| `drizzle-query` | 1.818 | 4.007 | 8.080 | its satellite (6.262) |
| `drizzle-mutation` | 1.992 | 3.955 | 6.954 | its satellite (4.962) |
| `drizzle-zod` | 2.089 | 3.060 | 7.086 | its satellite (4.997) |
| `drizzle-review` | 1.723 | 6.585 | 4.070 | `id-map.md` (2.347), then one satellite per finding |

The old `drizzle-review` cost 1.684 + 5.909 (the whole hub) = **7.593** before step 1, and a query
finding added the 7.432-token Portuguese satellite that held reads, writes and Zod together: ~15k.
The new review reaches the same finding with ~8.4k (SKILL.md + ID map + the 4–6k satellite).
The five docs total 25.826 tokens (the three Portuguese notes were 17.224): the growth is the Zod
note, the decision trees and the verified behaviour, not duplication.
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) · `PostgreSQL` · `elysia-schema` · `http-contract`
