# Most frequent antipatterns, with IDs

> Check `mapa-de-ids.md`: `DRZ-SCHEMA-01` is an alias of `DRZ-CORE-02`.
> The rows **without an ID** cite the normative note, never an invented `DRZ-*`.

| Antipattern | Canonical ID | Satellite |
| --- | --- | --- |
| `drizzle({ schema })` without the `relations` — `with` throws at runtime | `DRZ-REL-05` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Table exported but absent from the client's schema object | `DRZ-CORE-02` (adjacent; see Step 6) | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| Relation declared on one side only | `DRZ-REL-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Two relations between the same tables without `relationName` | `DRZ-REL-04` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| One query per item inside `map`/`for` | `DRZ-RQB-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `offset` inside a nested `with` | `DRZ-RQB-02` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `eq`/`and` imported inside an RQB `where` | `DRZ-RQB-03` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Atomic writes outside a shared transaction | `DRZ-TX-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| External `db` used inside the transaction block | `DRZ-TX-03` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `update`/`delete` without `where` | `DRZ-QUERY-04` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `select` followed by a conditional `insert`/`update` instead of an upsert | `DRZ-QUERY-06` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `undefined` used to clear a field (`set` ignores it) | `DRZ-QUERY-05` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| ``sql`...` `` as the default filtering route | `DRZ-QUERY-03` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `select` without a projection where the subset matters | `DRZ-QUERY-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Hand-written Zod duplicating columns | `DRZ-ZOD-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Extra rule via `.extend` instead of the 2nd argument of `create*Schema` | `DRZ-ZOD-02` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `push` in staging or production | `DRZ-MIG-02` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| `push` and `generate` coexisting in the same environment | `DRZ-MIG-04` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| `.default` confused with `.$default` | `DRZ-SCHEMA-04` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| Self-referencing FK without `AnyPgColumn` | `DRZ-SCHEMA-02` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| Snapshot not updated by a hand-written migration | no ID — see Step 6 | |
| Index that is a strict prefix of another index | no ID — see Step 6 | — |
| Date-range filter with no index covering it | no ID — see Step 6 | — |
| Expression over a column in the predicate (`split_part`, `lower`) | no ID — see Step 6 | — |
| Listing without `limit` on an open-volume screen | no ID — see Step 6 | |
| `updated_at` kept by discipline, with neither `$onUpdate` nor a trigger | no ID — see Step 6 | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |

