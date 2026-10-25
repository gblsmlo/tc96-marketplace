import { expect, test } from 'bun:test'
import { transfer } from '../src/credits'
import { accounts } from '../src/db/schema'
import { createTestDb } from '../src/db/test-db'

test('moves money between two accounts', async () => {
  const { db } = await createTestDb()
  const [a] = await db.insert(accounts).values({ ownerName: 'Ana', balance: 1000 }).returning()
  const [b] = await db.insert(accounts).values({ ownerName: 'Bia', balance: 0 }).returning()
  await transfer(db, { idempotencyKey: 'k1', fromAccountId: a.id, toAccountId: b.id, amount: 300 })
  const rows = await db.select().from(accounts).orderBy(accounts.id)
  expect(rows.map((r) => r.balance)).toEqual([700, 300])
})
