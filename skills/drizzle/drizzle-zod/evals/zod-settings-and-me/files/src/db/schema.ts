import { integer, jsonb, pgTable, text, timestamp, varchar } from 'drizzle-orm/pg-core'

export type UserSettings = { theme: 'light' | 'dark'; emailDigest: boolean }

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  email: varchar({ length: 120 }).notNull().unique(),
  name: varchar({ length: 80 }).notNull(),
  bio: text(),
  passwordHash: text().notNull(),
  settings: jsonb().$type<UserSettings>(),
  createdAt: timestamp().defaultNow().notNull(),
})
