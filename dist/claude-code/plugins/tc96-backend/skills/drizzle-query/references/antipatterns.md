# Read antipatterns, with IDs

> Each row names the fix and where the rule's body lives. Rows without a `DRZ-*` ID cite the doc section — never an invented ID.

| Antipattern | ID | Fix | Body |
| --- | --- | --- | --- |
| A read inside `map`/`for`/`Promise.all`, once per item | `DRZ-RQB-01` | `with`, or one `inArray` query grouped in a `Map` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 0.2, § 4 |
| `drizzle(client)` or `{ schema: tables }` without the `relations()` | `DRZ-REL-05` | register tables **and** relations | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.5 |
| A relation declared on one side only | `DRZ-REL-01` | declare both sides | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.1 |
| `fields`/`references` on the `many()` side | `DRZ-REL-02` | they belong on the side with the FK | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.1 |
| `with` straight from users to groups, skipping the junction | `DRZ-REL-03` | go through the junction, flatten after | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.3 |
| Two relations to the same table without `relationName` | `DRZ-REL-04` | name both sides alike | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.4 |
| `where: eq(posts.id, id)` in `findMany`/`findFirst` | `DRZ-RQB-03` | `where: (posts, { eq }) => eq(posts.id, id)` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.3 |
| `offset` inside a nested `with` | `DRZ-RQB-02` | `limit` only below the root | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.4 |
| An `extras` entry without `.as()` | `DRZ-RQB-04` | `.as('name')` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.5 |
| `extras: { x: (t) => sql… }` on 0.x (v1 syntax) | no ID | an aliased value, or one function returning the object | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.5 |
| Another table's Drizzle columns in an `extras` subquery | no ID | name the inner table in plain SQL | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.5 |
| A user value in `sql.raw`, or a filter concatenated into `sql` | `DRZ-QUERY-02` | operators; `sql` interpolation is parameterized | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.7 |
| `sql` as the default filter | `DRZ-QUERY-03` | `eq`/`and`/`ilike`/`inArray`… | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.7 |
| `select()` of every column where a subset matters | `DRZ-QUERY-01` | explicit fields, or `columns` in RQB | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 1.1 |
| A hot query rebuilt on every call | `DRZ-RQB-05` | `.prepare()` with `sql.placeholder` | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 3.7 |
| A listing that grows with the data, with no `limit` | no ID | offset or keyset | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 0.3, § 5 |
| Pagination ordered by a non-unique column | no ID | the primary key as the last sort key | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 5.1 |
| A `where` inside `with` expected to filter the parent | no ID | `exists` in the root `where`, or a join | [Reads](../../../docs/drizzle/drizzle-reads-and-relations.md) § 2.3 |
| Several positional inputs after `db` (`posts(db, authorId, userId, page)`) | `DRZ-CORE-03` | `db: Database`, then one typed input object | [Hub](../../../docs/drizzle/drizzle-orm.md) § 10 |
