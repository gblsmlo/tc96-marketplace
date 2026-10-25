# The probes — before reading the code

> In persistence, the worst defects are **invisible to reading**: the schema looks complete, the query
> looks right, the test passes — and even so the relational API is switched off, the migration
> generator is diffing from a stale snapshot, or a body schema lets the caller set their own role.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-review/scripts/probes.sh .
```

| Probe | How | What it reveals |
| --- | --- | --- |
| **P0. Version line** | `drizzle-orm`, `drizzle-kit`, `drizzle-zod`, `zod` in `package.json` | which relations API and which Zod import apply — 0.x is what the docs describe |
| **P1. Client registration** | AST: the exported `relations()` × the object passed to `drizzle({ schema })` | `DRZ-REL-05` — without the relations, `with` throws at runtime and `db.query.x` may be `undefined` |
| **P2. Snapshot chain** | journal entries × `*_snapshot.json` × `.sql` files, and each journal tag × its file | a hand-written or hand-edited migration: the next `generate` diffs from a stale state and may propose destructive SQL |
| **P3. push outside local** | `drizzle-kit push` in `package.json`, workflows, Dockerfiles, shell scripts | `DRZ-MIG-02`, and `DRZ-MIG-04` when push and generate/migrate are both scripted |
| **P4. Schema** | AST | `DRZ-CORE-02` table not exported · `DRZ-SCHEMA-02` self-reference without `AnyPgColumn` · `DRZ-SCHEMA-04` `.default(new Date())`-style frozen values · an index that is a strict prefix of another |
| **P5. Reads** | AST | `DRZ-RQB-01` a read inside a loop · `DRZ-RQB-02`/`03`/`04` · `DRZ-QUERY-02` `sql.raw` with a variable · `DRZ-QUERY-03` `sql` as a filter · listings without `limit` · offset without a unique tiebreaker |
| **P6. Writes** | AST | `DRZ-QUERY-04` no `where`, or a filter that can collapse · `DRZ-QUERY-05`/`06`/`07` · `DRZ-TX-01`/`03`/`04`/`05` |
| **P7. Zod boundary** | AST | `DRZ-ZOD-01` hand-written duplicate · `02` `.extend()` over a column · `03` un-narrowed body or a response with a secret · `04` date without coercion · `05` replacement dropping `null` · `06` PATCH accepting `{}` · `07` untyped `jsonb` · zod 3.25 with the classic import |
| **P8. Live integration tests** | run the suite with whatever unlocks the database tests | a test that never runs is not coverage — needs a database; if it did not run, say so |

Each AST finding is marked `high` (the shape is the defect) or `candidate` (suspicious; confirm by reading). The scan needs `node` or `bun` and the project's `typescript` package; when either is missing it says `SKIPPED` — then those probes are "not verified", never "no findings".

**If P1 fires, stop and report it first.** With the relational API switched off, every hand-built read is a **consequence, not a cause**, and criticizing each one is noise.

**P2 needs one more step to be conclusive:** on a clean tree, `drizzle-kit generate` should propose nothing. If it writes a migration, the chain is stale.

## What the scan does not see

- A race between two connections — `DRZ-TX-05` is flagged by shape (a read of a table, then an update of it), and confirmed by reading the condition.
- Whether a missing `limit` is a defect — a lookup table is bounded by design; a feed is not. That needs the product's answer.
- Query plans. "This could get slow" with no `EXPLAIN` and no row count is an opinion.
- Authorization beyond the row's owner — who may act on whose data is a product decision.

## Related

- `scan-and-severity.md` — what to do with what the probes pointed at
- `id-map.md` — where each `DRZ-*` has its body
