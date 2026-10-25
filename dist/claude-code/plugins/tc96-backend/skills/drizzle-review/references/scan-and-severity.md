# The scan order, and severity

## Step 2 — Scan in the order that fails most

Each step reads what the probes pointed at, then the code around it. Load the one satellite the step names — `id-map.md` says where each ID's body lives.

1. **Client and schema boundary** — `DRZ-REL-05`, `DRZ-REL-01`, `DRZ-CORE-02`. Is every relation declared on both sides and registered in the client? Is every table exported? → [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2, [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.
2. **Migrations** — `DRZ-MIG-01`–`05`, the snapshot chain. Which workflow owns which environment? Does `generate` on a clean tree propose nothing? → [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 2.
3. **Reads that multiply queries** — `DRZ-RQB-01`. A read inside `map`/`for`/`Promise.all` is the most common and most expensive finding. → [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 0.2, § 4.
4. **Reads without a ceiling** — listings with no `limit`, offset without a unique tiebreaker. No `DRZ-*` ID: cite the section. → [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 0.3, § 5.
5. **Index × predicate** — a hot filter with no index, an index that is a prefix of another, an expression over a column (`lower(email)`) that no index covers. No `DRZ-*` ID. → [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.4 and `PostgreSQL`.
6. **Writes and transactions** — `DRZ-QUERY-04`–`07`, `DRZ-TX-01`–`05`. Which rows does each write touch? What is atomic? Where does a read decide a write? → [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md).
7. **Projection and raw SQL** — `DRZ-QUERY-01`–`03`. A user value in `sql.raw` is a security finding. → [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.
8. **Boundary validation** — `DRZ-ZOD-01`–`07`. What can a caller set? What leaves in a response? → [Zod](../../../docs/drizzle/drizzle-zod.md).

If a step produces a finding that invalidates the next ones (the relational API is switched off; the whole listing should be paginated), **stop reviewing the interior** and report the change of shape, not the detail.

---

## Step 3 — Classify severity

| Severity | What goes in |
| --- | --- |
| **Blocking** | loss of isolation between tenants or owners; `update`/`delete` without `where` (`DRZ-QUERY-04`); a user value in `sql.raw` (`DRZ-QUERY-02`); `push` in production (`DRZ-MIG-02`); a destructive migration without a rollback; a body schema that lets the caller set `role`, owner or tenant (`DRZ-ZOD-03`) |
| **High** | `DRZ-REL-05`, `DRZ-RQB-01`, `DRZ-TX-01`, `DRZ-TX-03`, `DRZ-TX-05`; a stale snapshot chain; an unbounded read on an open-volume screen; a response schema carrying a secret (`DRZ-ZOD-03`); an untyped `jsonb` written from the body (`DRZ-ZOD-07`) |
| **Medium** | a missing index for a hot filter, a redundant index; `DRZ-CORE-03` when two inputs of the same type sit side by side; `DRZ-QUERY-01`, `DRZ-QUERY-06`, `DRZ-QUERY-07`; `DRZ-TX-04`; `DRZ-ZOD-01`, `DRZ-ZOD-04`, `DRZ-ZOD-05`, `DRZ-ZOD-06` (each turns a client error into a 500 or a wrong 400) |
| **Low** | a preference without an ID — **not a finding**, see `report-and-cut.md` |

**Measured cost beats assumed cost.** "This could get slow" with no number and no execution plan is Low, not Medium. A statement count from a test (`drizzle-query`'s harness) is a number.
