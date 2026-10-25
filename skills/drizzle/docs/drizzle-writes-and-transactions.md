---
titulo: Drizzle - Writes and Transactions
Link: https://orm.drizzle.team/docs/insert
tags:
  - typescript
  - backend
  - database
  - orm
  - postgresql
  - agent-context
source: "Official Drizzle ORM documentation — insert, update, delete and transactions, cross-checked against the snapshot pinned to the stable version and executed on PGlite"
verificado-em: 2026-10-24
---

# Drizzle — Writes and Transactions

> `insert` · `returning` · upsert (`onConflictDoNothing`/`onConflictDoUpdate`) · insert from select · `update` · `delete` · `db.transaction` · `tx.rollback()` · savepoints · isolation
>
> How to change data so that the change is exactly the one intended: the rows the filter names, all of it or none of it, and nothing lost between two concurrent requests.

Entry: [Drizzle ORM](drizzle-orm.md) · **Confirm § 0 there before using this note.** The write API diverges little between the stable line and v1-rc.

> **Import convention in this note.** The examples assume `sql`, `eq`, `and`, `gte` and `TransactionRollbackError` imported from `'drizzle-orm'`. Each block is an independent illustration.

---

## 0. Decision trees

### 0.1 Plain insert or upsert?

```
Can the key already exist?
├── NO → insert().values(...)
└── YES
    └── On collision, what should happen?
        ├── Ignore it and keep what exists
        │   → onConflictDoNothing({ target: column })
        ├── Update specific fields
        │   → onConflictDoUpdate({ target, set: {...} })
        └── Update only when a condition holds
            → onConflictDoUpdate + targetWhere/setWhere

Never a select followed by an insert/update in two queries:
two requests both see "absent" and both insert.     DRZ-QUERY-06
```

### 0.2 Does this need a transaction?

```
How many statements does the operation write?
├── ONE (an insert, a guarded update, an upsert)
│   → no transaction: a single statement is already atomic
└── TWO OR MORE that must succeed or fail together
    → db.transaction(async (tx) => ...), with tx in every call   DRZ-TX-01 · DRZ-TX-03
    └── Does a write depend on a value read before it
        (a balance, a stock count, a status)?
        ├── NO → the transaction is enough
        └── YES → the guard goes INTO the write:
                  update ... where (id = ? and balance >= amount) returning
                  (empty result = the guard failed), or lock the row
                  with select ... for update before deciding.        DRZ-TX-05
```

### 0.3 What does the caller get back?

```
Does the caller need the written row (id, defaults, timestamps)?
├── NO  → no returning()
└── YES → .returning() (Postgres) — and handle the EMPTY array:
          onConflictDoNothing on a collision, or an update whose
          where matched nothing, returns [] — `const [row] = ...` is undefined
```

---

## 1. Insert

```ts
await db.insert(users).values({ name: 'Andrew' })
await db.insert(users).values([{ name: 'Andrew' }, { name: 'Dan' }])   // several rows
```

`returning()` (Postgres and SQLite) returns the inserted rows:

```ts
await db.insert(users).values({ name: 'Dan' }).returning()
await db.insert(users).values({ name: 'Dan' }).returning({ insertedId: users.id })
```

The type of the input object comes from `typeof users.$inferInsert` — never written by hand.

**An empty array is an error, not a no-op.** *Verified:* `db.insert(users).values([])` throws `values() must be called with at least one value`. A batch built from user input or a filtered list needs a guard:

```ts
if (rows.length > 0) await db.insert(tags).values(rows)
```

A very large batch also hits Postgres's limit of 65,535 bind parameters per statement — rows × columns. Split it into chunks.

### 1.1 Rule — `DRZ-QUERY-*` (insert)

| ID | Rule |
| --- | --- |
| `DRZ-QUERY-07` | A batch `insert` built from a list that can be empty **MUST** guard the empty case — `values([])` throws. *Added 2026-10-24, verified on 0.45.4.* |

---

## 2. Upsert — `onConflictDoNothing` and `onConflictDoUpdate`

```ts
// ignore on collision
await db.insert(users).values({ id: 1, name: 'John' }).onConflictDoNothing({ target: users.id })

// update specific fields on collision
await db.insert(users)
  .values({ id: 1, name: 'Dan' })
  .onConflictDoUpdate({ target: users.id, set: { name: 'John' } })

// update only under a condition, and reference the new row through `excluded`
await db.insert(employees)
  .values({ employeeId: 123, name: 'John Doe' })
  .onConflictDoUpdate({
    target: employees.employeeId,
    targetWhere: sql`name <> 'John Doe'`,
    set: { name: sql`excluded.name` },
  })
```

A composite key in `target` accepts an array: `target: [users.firstName, users.lastName]`. `excluded.<column>` is the row that tried to insert — the way to say "take the incoming value" without repeating it.

`.returning()` chains after `onConflictDoUpdate`/`onConflictDoNothing` as usual — it is the same method as § 1, applied to the final row (inserted or updated):

```ts
const [post] = await db.insert(posts)
  .values({ slug: 'my-post', title: 'My Post' })
  .onConflictDoUpdate({ target: posts.slug, set: { title: 'My Post' } })
  .returning()
```

**With `onConflictDoNothing`, a collision returns no row.** *Verified:* `.returning()` after a conflicting `onConflictDoNothing` returns `[]`. When the caller needs the existing row (an idempotent "create or get"), read it afterwards by the same key.

**`target` must be a column with `UNIQUE` or a primary key in the database** — Postgres's `ON CONFLICT` requires a real constraint to know which collision to observe. *Verified:* a `target` on a column with no unique constraint fails with a database error at runtime, not at compile time. Declaring `.unique()` on the schema column (see [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) § 1.4) is a prerequisite, not a Drizzle detail.

### 2.1 Rule — `DRZ-QUERY-*` (upsert)

| ID | Rule |
| --- | --- |
| `DRZ-QUERY-06` | An upsert **MUST** use `onConflictDoNothing`/`onConflictDoUpdate`, **NEVER** a `select` followed by a conditional `insert`/`update` in two queries — it loses atomicity. |

---

## 3. Insert from a select

```ts
await db
  .insert(employees)
  .select(
    db.select({ name: users.name }).from(users).where(eq(users.role, 'employee')),
  )
  .returning({ id: employees.id })
```

`INSERT ... SELECT` in a single query, without bringing the data into the application and inserting it back — important when the volume is large.

---

## 4. Update and delete

### 4.1 Update

```ts
await db.update(users).set({ name: 'Mr. Dan' }).where(eq(users.name, 'Dan'))

// an SQL expression in set — increment, touch a timestamp
await db.update(users).set({ updatedAt: sql`now()` }).where(eq(users.name, 'Dan'))
await db.update(accounts).set({ balance: sql`${accounts.balance} - ${amount}` }).where(eq(accounts.id, id))
```

**`undefined` in the `set` object is ignored — the field does not change.** To set `null`, pass an explicit `null`. *Verified:* `set({ bio: undefined, name: 'x' })` changes `name` and keeps `bio`. It is the same care as on the form side: `undefined` is never "empty", it is "I did not touch this".

**A `set` whose fields are all `undefined` throws.** *Verified:* `set({ bio: undefined })` fails with `No values to set`. That is the shape of an empty PATCH body after validation — reject it at the boundary ([Drizzle - Zod](drizzle-zod.md) § 6) instead of letting it reach the query as a 500.

`returning()` works as in insert. `limit()` on update only exists in MySQL/SQLite/SingleStore — **not in Postgres**. A column with `.$onUpdate()` is filled by every update that does not set it.

### 4.2 Delete

```ts
await db.delete(users).where(eq(users.name, 'Dan'))
await db.delete(users)   // no where: deletes the whole table
```

`returning()` works the same. The same absence of `limit()` in Postgres.

> **The most expensive trap in this note.** `db.delete(users)` without `.where()` **is not a syntax error** — it is `DELETE FROM users` with no filter, and it deletes everything. The same goes for `update` without `where`: it updates the whole table. No TypeScript warning catches it, because `where()` is optional in the signature. *Verified:* `db.delete(posts).returning()` issues `delete from "posts" returning ...` and removes every row.

**`where(undefined)` is the same trap, one step removed.** `and()` with every argument `undefined` returns `undefined` (*verified*), so a filter built from optional inputs can collapse to no filter at all. A write whose filter is assembled from optional values must check that at least one condition exists.

### 4.3 The guard goes into the write

A decision made on a value read earlier — "debit only if the balance covers it", "publish only if it is still a draft" — has to be enforced by the write itself, because another request can change the value between the read and the write:

```ts
const [debited] = await db.update(accounts)
  .set({ balance: sql`${accounts.balance} - ${amount}` })
  .where(and(eq(accounts.id, fromId), gte(accounts.balance, amount)))
  .returning({ id: accounts.id })

if (!debited) throw new InsufficientFunds(fromId)
```

The database evaluates the guard and the change in one statement, on the current row. *Verified:* an update whose guard fails returns `[]`. A transaction alone does **not** make "select, check in JavaScript, then update" safe: under Postgres's default `read committed`, two transactions can read the same balance and both pass the check. The alternatives are the guarded write above, or `select ... for update` (`.for('update')` on the select) inside the transaction, which makes the second reader wait. *Not executed:* PGlite is single-connection, so the race itself was not reproduced; this is Postgres semantics.

### 4.4 When the database says no

A constraint violation — unique, foreign key, check, not null — is the database enforcing a rule the code may have missed, and it is usually a **client** error (409, 422), not a 500. *Verified* on 0.45.4: the query rejects with a `DrizzleQueryError` (exported from `'drizzle-orm'`) whose message is `Failed query: <sql>`; the driver's error, with the PostgreSQL code, is on `.cause`:

```ts
import { DrizzleQueryError } from 'drizzle-orm'

try {
  await db.insert(users).values(input)
} catch (error) {
  const pg = error instanceof DrizzleQueryError ? (error.cause as { code?: string; constraint?: string }) : undefined
  if (pg?.code === '23505') throw new Conflict(`already exists (${pg.constraint})`)   // unique_violation
  if (pg?.code === '23503') throw new UnprocessableEntity('a referenced row does not exist') // foreign_key_violation
  throw error
}
```

Matching on `error.message` does not work: the message is the SQL, not the reason. And prefer `onConflictDoNothing`/`onConflictDoUpdate` (§ 2) when the collision is an expected path rather than an error.

### 4.5 Rules — `DRZ-QUERY-*` (update and delete)

| ID | Rule |
| --- | --- |
| `DRZ-QUERY-04` | An `update`/`delete` without `where` **MUST** have the absence of the filter confirmed as intentional — it is the most expensive cause of incidents in this API. |
| `DRZ-QUERY-05` | To clear a field, the value **MUST** be an explicit `null`; `undefined` is ignored by `set`. |

---

## 5. Transactions

```ts
await db.transaction(async (tx) => {
  await tx.update(accounts).set({ balance: sql`${accounts.balance} - 100` }).where(eq(accounts.id, 1))
  await tx.update(accounts).set({ balance: sql`${accounts.balance} + 100` }).where(eq(accounts.id, 2))
})
```

Every method of `tx` mirrors `db` — including RQB (`tx.query.users.findMany(...)`). Calling the outer `db` inside the callback by mistake behaves differently by driver: with a pool it silently runs on another connection, outside the transaction (`DRZ-TX-03`); on a single-connection client such as PGlite it waits for the transaction that is waiting for it — *verified*: the test hangs until its timeout. The callback's return value is what `db.transaction()` resolves to; an exception thrown inside rolls everything back and rejects with that exception (*verified*).

### 5.1 Rollback, and what the caller sees

```ts
try {
  const newBalance = await db.transaction(async (tx) => {
    const [account] = await tx.select({ balance: accounts.balance })
      .from(accounts).where(eq(accounts.id, 1)).for('update')
    if (account.balance < 100) {
      tx.rollback()   // stops here and undoes everything
    }
    await tx.update(accounts).set({ balance: sql`${accounts.balance} - 100` }).where(eq(accounts.id, 1))
    return account.balance - 100
  })
} catch (error) {
  if (error instanceof TransactionRollbackError) {
    // the business outcome "not enough balance" — map it to a 409/422, not a 500
  } else {
    throw error
  }
}
```

**`tx.rollback()` does not end the transaction quietly.** It throws inside the callback, and the awaited `db.transaction()` **rejects** with `TransactionRollbackError` (*verified* on 0.45.4 — the previous Portuguese note said otherwise). So a rollback is a rejection the caller must handle: catch `TransactionRollbackError` when the rollback is an expected business outcome, or throw your own domain error instead when the caller needs to know *why*. What `rollback()` buys over an arbitrary `throw` is that the caller can tell "rolled back on purpose" from "failed".

### 5.2 Savepoints (nested transactions)

```ts
await db.transaction(async (tx) => {
  await tx.update(accounts).set({ balance: sql`${accounts.balance} - 100` }).where(eq(accounts.id, 1))

  try {
    await tx.transaction(async (tx2) => {
      await tx2.update(users).set({ name: 'Mr. Dan' }).where(eq(users.id, 1))
    })
  } catch (error) {
    // the inner work is undone; the outer transaction continues
  }
})
```

A `transaction` inside another becomes a `SAVEPOINT` in Postgres. **The inner one only spares the outer one when its rejection is caught.** *Verified:* an inner `rollback()` surfaces in the outer callback as `TransactionRollbackError`; caught, the outer commits its own writes and the inner ones are undone; uncaught, it propagates and the outer rolls back too.

### 5.3 Isolation (PostgreSQL)

```ts
await db.transaction(
  async (tx) => { /* ... */ },
  {
    isolationLevel: 'serializable',   // 'read uncommitted' | 'read committed' | 'repeatable read' | 'serializable'
    accessMode: 'read write',          // 'read only' | 'read write'
  },
)
```

`serializable` makes Postgres abort one of two conflicting transactions with a serialization error — the caller must be ready to retry it. For a single guarded value, § 4.3 is usually simpler.

### 5.4 Rules — `DRZ-TX-*`

| ID | Rule |
| --- | --- |
| `DRZ-TX-01` | Two or more writes that must be atomic **MUST** be inside the same `db.transaction`, **NEVER** loose calls in sequence. |
| `DRZ-TX-02` | Rolling back a transaction **MUST** use `tx.rollback()`, **NEVER** a `throw` only to produce the same effect when there is no real error to propagate. |
| `DRZ-TX-03` | Every operation inside the transaction **MUST** use `tx`, **NEVER** the outer `db` — using `db` by mistake runs outside the transaction and breaks atomicity with no visible error. |
| `DRZ-TX-04` | Code that calls `tx.rollback()` **MUST** handle the `TransactionRollbackError` the awaited `db.transaction()` rejects with — a rollback is not a quiet return; and an inner transaction (savepoint) that may fail **MUST** be caught to spare the outer one. *Added 2026-10-24, verified on 0.45.4.* |
| `DRZ-TX-05` | A write that depends on a value read earlier (balance, stock, status) **MUST** carry the condition in its own `where` and check `returning()`, or lock the row with `for('update')` first — **NEVER** a read, a check in application code and an unguarded write. *Added 2026-10-24; Postgres `read committed` semantics, not reproduced on single-connection PGlite.* |

---

## 6. Antipatterns

| Antipattern | Fix |
| --- | --- |
| `update`/`delete` without `where`, without confirming it is intentional | review before running · `DRZ-QUERY-04` |
| A filter assembled from optional values that can collapse to `undefined` | require at least one condition · `DRZ-QUERY-04` |
| `set({ field: undefined })` expecting to clear the value | an explicit `null` · `DRZ-QUERY-05` |
| An empty PATCH reaching `set()` and failing with "No values to set" | reject `{}` at the boundary · § 4.1 |
| `select` + conditional `insert`/`update` in two calls to simulate an upsert | `onConflictDoUpdate`/`DoNothing` · `DRZ-QUERY-06` |
| `values(list)` with no guard for an empty list | `if (list.length)` · `DRZ-QUERY-07` |
| `const [row] = await ...onConflictDoNothing().returning()` used without a check | handle `undefined`, then read the existing row · § 2 |
| Two related writes outside `db.transaction` | wrap them in the same transaction · `DRZ-TX-01` |
| `throw` only to provoke a rollback with no real error | `tx.rollback()` · `DRZ-TX-02` |
| Calling `db` instead of `tx` inside a transaction | use `tx` everywhere · `DRZ-TX-03` |
| Matching a constraint violation on `error.message` | `error.cause.code` (`23505`, `23503`) on the `DrizzleQueryError` · § 4.4 |
| `tx.rollback()` with the caller not expecting a rejection | catch `TransactionRollbackError` · `DRZ-TX-04` |
| An uncaught inner transaction expected to spare the outer one | catch it · `DRZ-TX-04` |
| Read the balance, `if` in JavaScript, then an unguarded update | a guarded `where` + `returning`, or `for('update')` · `DRZ-TX-05` |

---

## Related

- [Drizzle ORM](drizzle-orm.md) — entry, § 0 on which version these docs document
- [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) — the unique constraint an upsert needs, `$onUpdate`
- [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) — reading what was written
- [Drizzle - Zod](drizzle-zod.md) — validating the body before it reaches `values()` or `set()`

## Sources consulted

Snapshot of the `drizzle-team/drizzle-orm-docs` repository, commit `3e7fe1b3` (2026-03-21, closest to the `drizzle-orm@0.45.2` tag, published on 2026-03-27), verified on 2026-08-16; every claim marked *verified* executed on 2026-10-24 against `drizzle-orm@0.45.4` on PGlite 0.3.16:

- `insert.mdx` · `update.mdx` · `delete.mdx` — the write builders, `returning`, upsert, insert from select
- `transactions.mdx` — `db.transaction`, `tx.rollback()`, savepoints, isolation per dialect
- `select.mdx` — `.for('update')` row locking

See [Drizzle ORM](drizzle-orm.md) § 0 for the caveat about the live docs being on the v1-rc line at these same URLs.
