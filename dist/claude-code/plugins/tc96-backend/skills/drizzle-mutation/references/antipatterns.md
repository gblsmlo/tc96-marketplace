# Write antipatterns, with IDs

> Each row names the fix and where the rule's body lives. Rows without a `DRZ-*` ID cite the doc section — never an invented ID.

| Antipattern | ID | Fix | Body |
| --- | --- | --- | --- |
| `update`/`delete` with no `where` | `DRZ-QUERY-04` | name the rows; confirm when "all" is intended | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.2 |
| A filter of optional parts that can collapse to `undefined` | `DRZ-QUERY-04` | require one condition before the write | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.2 |
| A delete or update scoped by id alone on user-owned data | `DRZ-QUERY-04` | id **and** owner in the `where` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.2 |
| `set({ field: undefined })` to clear a value | `DRZ-QUERY-05` | `null` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.1 |
| An empty PATCH reaching `set()` — "No values to set" | no ID | reject `{}` before the query | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.1 |
| `select`, then a conditional `insert` | `DRZ-QUERY-06` | `onConflictDoNothing`/`onConflictDoUpdate` on a unique key | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 2 |
| `values(list)` where the list can be empty | `DRZ-QUERY-07` | `if (list.length)` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 1 |
| `const [row] = await …onConflictDoNothing().returning()` used unchecked | no ID | handle `undefined`, read the existing row | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 2 |
| Upsert `target` on a column with no unique constraint | no ID | declare `.unique()`/`uniqueIndex` first | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 2 |
| Related writes as loose calls | `DRZ-TX-01` | one `db.transaction` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5 |
| `throw new Error('rollback')` with no real error | `DRZ-TX-02` | `tx.rollback()`, or a domain error that names the reason | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5.1 |
| `db` instead of `tx` inside the transaction | `DRZ-TX-03` | `tx` everywhere | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5 |
| `tx.rollback()` with the caller expecting a normal return | `DRZ-TX-04` | catch `TransactionRollbackError` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5.1 |
| A nested transaction outside `try`, expected to spare the outer one | `DRZ-TX-04` | `try { await tx.transaction(…) } catch {}` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 5.2 |
| Read the value, `if` in JavaScript, unguarded update | `DRZ-TX-05` | the condition in the `where`, check `returning()`; or `.for('update')` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.3 |
| `error.message.includes('duplicate')` | no ID | `error.cause.code === '23505'` on the `DrizzleQueryError` | [Writes](../../../docs/drizzle/drizzle-writes-and-transactions.md) § 4.4 |
| Owner or author read from the request body | see `drizzle-zod` | add it from the authenticated context | `DRZ-ZOD-03` in [Zod](../../../docs/drizzle/drizzle-zod.md) § 2 |
| Several positional inputs after `db` (`posts(db, authorId, userId, page)`) | `DRZ-CORE-03` | `db: Database`, then one typed input object | [Hub](../../../docs/drizzle/drizzle-orm.md) § 10 |
