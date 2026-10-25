import { eq, sql } from 'drizzle-orm'
import type { Database } from './db/client'
import { accounts, transfers } from './db/schema'

export type TransferInput = { idempotencyKey: string; fromAccountId: number; toAccountId: number; amount: number }

/** POST /transfers — the mobile app sends a fresh idempotencyKey per tap on "Send". */
export async function transfer(db: Database, input: TransferInput) {
  const existing = await db.select().from(transfers).where(eq(transfers.idempotencyKey, input.idempotencyKey))
  if (existing.length > 0) return existing[0]

  const [from] = await db.select().from(accounts).where(eq(accounts.id, input.fromAccountId))
  if (!from) throw new Error('account not found')
  if (from.balance < input.amount) throw new Error('insufficient funds')

  return db.transaction(async (tx) => {
    await tx.update(accounts).set({ balance: from.balance - input.amount }).where(eq(accounts.id, input.fromAccountId))
    await db.update(accounts).set({ balance: sql`${accounts.balance} + ${input.amount}` }).where(eq(accounts.id, input.toAccountId))
    const [row] = await tx.insert(transfers).values(input).returning()
    if (!row) throw new Error('rollback')
    return row
  })
}
