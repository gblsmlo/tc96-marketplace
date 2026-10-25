# Write patterns

> Eight shapes worth copying, each one executed against PostgreSQL (PGlite) on `drizzle-orm@0.45.4`, with a test asserting the guarantee it claims.
> Every function takes `db: Database` first and its input as one typed object (`DRZ-CORE-03`, hub § 10) — three account numbers in a row are exactly the case where positions get swapped.
> The schema: `users`, `posts` (unique `slug`), `tags` (unique `name`), `accounts` (`balance`), and `ledger` (unique `idempotencyKey`, foreign keys to `accounts`).

```ts
import { and, eq, isNull, sql, TransactionRollbackError } from 'drizzle-orm'
import type { Database } from './db'
import { accounts, ledger, posts, tags, users } from '../src/db/schema'

export class NotFound extends Error {}
export class Conflict extends Error {}
export class InsufficientFunds extends Error {}
```

## 1. Create and return: the server decides the owner, the database fills id and defaults

```ts
export type CreatePostInput = { authorId: number; slug: string; title: string }

export async function createPost(db: Database, input: CreatePostInput) {
  const [post] = await db.insert(posts).values(input).returning()
  return post
}
```

The input is one typed object (`DRZ-CORE-03`). `authorId` is part of it, but the route fills it from the authenticated session — never from the request body (`drizzle-zod`, `DRZ-ZOD-03`). `returning()` gives back the id and every default the database filled.

## 2. Create-or-get, idempotent: a collision returns no row, so read the existing one

```ts
export async function ensureTag(db: Database, name: string) {
  const [created] = await db.insert(tags).values({ name }).onConflictDoNothing({ target: tags.name }).returning()
  if (created) return created
  const [existing] = await db.select().from(tags).where(eq(tags.name, name))
  return existing
}
```

A collision returns **no row** from `onConflictDoNothing().returning()`, so `created` is `undefined` and the existing row is read by the same unique key. Two concurrent calls both end with the same tag, and neither fails. A `select` first and an `insert` after would let both insert (`DRZ-QUERY-06`).

## 3. Batch upsert from an external source: guard the empty list, chunk the big one, take the incoming value

```ts
export type SyncTagsInput = { names: string[]; chunkSize?: number }

export async function syncTags(db: Database, { names, chunkSize = 1000 }: SyncTagsInput) {
  const rows = [...new Set(names)].map((name) => ({ name }))
  if (rows.length === 0) return 0
  let written = 0
  for (let i = 0; i < rows.length; i += chunkSize) {
    const res = await db.insert(tags).values(rows.slice(i, i + chunkSize))
      .onConflictDoUpdate({ target: tags.name, set: { name: sql`excluded.name` } })
      .returning({ id: tags.id })
    written += res.length
  }
  return written
}
```

`values([])` throws, so the empty list returns early (`DRZ-QUERY-07`). Deduplicate before the statement: Postgres refuses to update the same row twice in one `ON CONFLICT DO UPDATE`. Chunking keeps each statement under the 65,535 bind-parameter limit. `excluded.name` is the incoming row's value.

## 4. A guarded update: the condition lives in the where, the empty returning is the answer

```ts
export type PublishPostInput = { postId: number; authorId: number }

export async function publishPost(db: Database, { postId, authorId }: PublishPostInput) {
  const [post] = await db.update(posts)
    .set({ published: true, publishedAt: new Date() })
    .where(and(eq(posts.id, postId), eq(posts.authorId, authorId), eq(posts.published, false)))
    .returning()
  if (!post) throw new Conflict(`post ${postId} is not a draft of author ${authorId}`)
  return post
}
```

The rule "only the author, only a draft" is part of the `where`, so it is checked on the current row in the same statement that changes it. An empty `returning()` is the answer "the condition failed" — mapped to a domain error the route turns into a 409.

## 5. A transfer: atomic, guarded against overdraft, idempotent on a client key

```ts
export type TransferInput = { idempotencyKey: string; fromAccountId: number; toAccountId: number; amount: number }

export async function transfer(db: Database, { idempotencyKey, fromAccountId, toAccountId, amount }: TransferInput) {
  if (!Number.isInteger(amount) || amount <= 0) throw new RangeError('amount must be a positive integer')
  return db.transaction(async (tx) => {
    const [entry] = await tx.insert(ledger)
      .values({ idempotencyKey, fromAccountId, toAccountId, amount })
      .onConflictDoNothing({ target: ledger.idempotencyKey })
      .returning()
    if (!entry) {
      const [previous] = await tx.select().from(ledger).where(eq(ledger.idempotencyKey, idempotencyKey))
      return { entry: previous, replayed: true }
    }
    const [debited] = await tx.update(accounts)
      .set({ balance: sql`${accounts.balance} - ${amount}` })
      .where(and(eq(accounts.id, fromAccountId), sql`${accounts.balance} >= ${amount}`))
      .returning({ id: accounts.id })
    if (!debited) throw new InsufficientFunds(`account ${fromAccountId}`)   // a domain error rolls back AND says why
    // an unknown toAccountId never gets here: the ledger's foreign key already rejected the insert
    await tx.update(accounts).set({ balance: sql`${accounts.balance} + ${amount}` }).where(eq(accounts.id, toAccountId))
    return { entry, replayed: false }
  })
}
```

Three statements, one transaction, `tx` everywhere (`DRZ-TX-01`, `DRZ-TX-03`). The ledger insert comes first: its unique key makes a retry a replay instead of a second debit. The debit carries `balance >= amount` in its own `where` (`DRZ-TX-05`) — reading the balance and comparing in JavaScript would let two concurrent transfers both pass. A thrown domain error rolls everything back **and** tells the caller why. An unknown destination never reaches the credit: the ledger's foreign key rejects it, and the error arrives as a `DrizzleQueryError` with `cause.code === '23503'` (doc § 4.4).

## 6. PATCH: null clears, an absent key stays, an empty patch never reaches set()

```ts
export type UpdateProfileInput = { userId: number; patch: { name?: string; bio?: string | null } }

export async function updateProfile(db: Database, { userId, patch }: UpdateProfileInput) {
  if (Object.keys(patch).length === 0) throw new RangeError('empty patch')
  const [user] = await db.update(users).set(patch).where(eq(users.id, userId)).returning()
  if (!user) throw new NotFound(`user ${userId}`)
  return user
}
```

An absent key stays untouched, `null` clears (`DRZ-QUERY-05`). An empty object would make `set()` throw `No values to set`, so it is rejected before the query — better still at the boundary, with the Zod schema (`drizzle-zod`).

## 7. A scoped delete: the filter is required, and the count is reported

```ts
export async function deleteDrafts(db: Database, authorId: number) {
  const removed = await db.delete(posts)
    .where(and(eq(posts.authorId, authorId), eq(posts.published, false), isNull(posts.publishedAt)))
    .returning({ id: posts.id })
  return removed.length
}
```

The filter names the owner and the state, not just a column: a delete is scoped to what the caller may remove (`DRZ-QUERY-04`). `returning({ id })` turns the result into a count to report.

## 8. A rollback the caller expects: catch TransactionRollbackError, rethrow the rest

```ts
export async function tryArchive(db: Database, postId: number): Promise<'archived' | 'skipped'> {
  try {
    await db.transaction(async (tx) => {
      const [p] = await tx.select({ published: posts.published }).from(posts).where(eq(posts.id, postId)).for('update')
      if (!p || p.published) tx.rollback()
      await tx.delete(posts).where(eq(posts.id, postId))
    })
    return 'archived'
  } catch (error) {
    if (error instanceof TransactionRollbackError) return 'skipped'
    throw error
  }
}
```

`tx.rollback()` makes the awaited `db.transaction()` reject with `TransactionRollbackError` (`DRZ-TX-04`). Here the rollback is an expected outcome, so it is caught and turned into a value; every other error is rethrown. `.for('update')` locks the row between the check and the delete.

## The test harness

The same PGlite harness as the read patterns: a fresh in-memory PostgreSQL per test, the schema applied with `pushSchema` from `drizzle-kit/api`.

```ts
test('transfer: atomic, guarded, idempotent', async () => {
  const [a1] = await db.insert(accounts).values({ ownerId, balance: 100 }).returning()
  const [a2] = await db.insert(accounts).values({ ownerId, balance: 0 }).returning()
  expect((await transfer(db, { idempotencyKey: 'k1', fromAccountId: a1.id, toAccountId: a2.id, amount: 60 })).replayed).toBe(false)
  expect((await transfer(db, { idempotencyKey: 'k1', fromAccountId: a1.id, toAccountId: a2.id, amount: 60 })).replayed).toBe(true)        // a retry is a replay
  await expect(transfer(db, { idempotencyKey: 'k2', fromAccountId: a1.id, toAccountId: a2.id, amount: 60 })).rejects.toBeInstanceOf(InsufficientFunds)
  const fk = await transfer(db, { idempotencyKey: 'k3', fromAccountId: a1.id, toAccountId: 999, amount: 10 }).catch((e) => e)
  expect(fk.cause.code).toBe('23503')                                               // the foreign key said no
  const balances = Object.fromEntries((await db.select().from(accounts)).map((a) => [a.id, a.balance]))
  expect(balances).toEqual({ [a1.id]: 40, [a2.id]: 60 })                            // nothing half-applied
})
```

What PGlite cannot show is a race: it is one connection, so two transactions never interleave. The guarded `where` and `.for('update')` are PostgreSQL semantics; a race test needs a real server and two connections.
