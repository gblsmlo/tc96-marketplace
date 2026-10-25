# The antipatterns a review meets most, with IDs

> `DRZ-SCHEMA-01` is an alias of `DRZ-CORE-02` and never appears in a review.
> Rows **without an ID** cite the doc section, never an invented `DRZ-*`. The full grids live in the build skills' `references/antipatterns.md` and in each satellite's antipattern table.

| Antipattern | Canonical ID | Satellite |
| --- | --- | --- |
| `drizzle({ schema })` without the `relations` — `with` throws at runtime | `DRZ-REL-05` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.5 |
| A relation declared on one side only | `DRZ-REL-01` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.1 |
| Two relations between the same tables without `relationName` | `DRZ-REL-04` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.4 |
| One query per item inside `map`/`for` | `DRZ-RQB-01` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 0.2 |
| `offset` inside a nested `with` | `DRZ-RQB-02` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.4 |
| `eq`/`and` imported inside an RQB `where` | `DRZ-RQB-03` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.3 |
| `extras` without `.as()`, or with v1 per-field callbacks | `DRZ-RQB-04` / no ID | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.5 |
| A user value in `sql.raw` | `DRZ-QUERY-02` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.7 |
| `sql` as the default filtering route | `DRZ-QUERY-03` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.7 |
| `select` without a projection where the subset matters | `DRZ-QUERY-01` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.1 |
| `update`/`delete` without `where`, or with a filter that can collapse | `DRZ-QUERY-04` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.2 |
| `undefined` used to clear a field | `DRZ-QUERY-05` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.1 |
| `select` followed by a conditional `insert` instead of an upsert | `DRZ-QUERY-06` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 2 |
| `values(list)` with no guard for an empty list | `DRZ-QUERY-07` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 1 |
| Atomic writes outside a shared transaction | `DRZ-TX-01` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5 |
| The outer `db` used inside the transaction block | `DRZ-TX-03` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5 |
| `tx.rollback()` with no `TransactionRollbackError` handling; an uncaught savepoint | `DRZ-TX-04` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5.1 |
| Read a value, check in JavaScript, unguarded write | `DRZ-TX-05` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.3 |
| Matching a constraint violation on `error.message` | no ID | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.4 |
| Hand-written Zod duplicating columns | `DRZ-ZOD-01` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 0.2 |
| `.extend()` over a generated column | `DRZ-ZOD-02` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4 |
| The table's whole insert schema as the body; a response with the password hash | `DRZ-ZOD-03` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 2 |
| A date column parsed from JSON without coercion | `DRZ-ZOD-04` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 3 |
| A replacement that drops `null` on a nullable column | `DRZ-ZOD-05` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4.1 |
| An update schema that lets `{}` reach `set()` | `DRZ-ZOD-06` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 6 |
| A `jsonb().$type<T>()` written without a schema | `DRZ-ZOD-07` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4.3 |
| `push` in staging or production | `DRZ-MIG-02` | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 2.2 |
| `push` and `generate` coexisting in the same environment | `DRZ-MIG-04` | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 2.3 |
| An enum value changed without a migration | `DRZ-MIG-05` | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 2.4 |
| `.default` confused with `.$default` | `DRZ-SCHEMA-04` | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.3 |
| Self-referencing FK without `AnyPgColumn` | `DRZ-SCHEMA-02` | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.6 |
| A migration edited by hand without updating its snapshot | no ID | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 2.3 |
| An index that is a strict prefix of another | no ID | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.4 |
| A listing without `limit` on an open-volume screen | no ID | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 0.3 |
| `updated_at` kept by discipline, with neither `$onUpdate` nor a trigger | no ID | [Schema](../../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.3 |
| Several positional inputs after `db` — two ids of the same type can swap | `DRZ-CORE-03` | [Hub](../../../docs/drizzle/drizzle-orm.md) § 10 |
