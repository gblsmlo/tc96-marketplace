import { integer, pgTable, timestamp, varchar } from 'drizzle-orm/pg-core'

export const accounts = pgTable('accounts', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  ownerName: varchar({ length: 80 }).notNull(),
  balance: integer().notNull().default(0), // in cents
})

export const transfers = pgTable('transfers', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  idempotencyKey: varchar({ length: 64 }).notNull(),
  fromAccountId: integer().notNull().references(() => accounts.id),
  toAccountId: integer().notNull().references(() => accounts.id),
  amount: integer().notNull(),
  createdAt: timestamp().defaultNow().notNull(),
})
