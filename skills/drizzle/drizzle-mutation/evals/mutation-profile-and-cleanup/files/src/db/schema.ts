import { boolean, integer, pgTable, text, timestamp, varchar } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 80 }).notNull(),
  bio: text(),
  updatedAt: timestamp().$onUpdate(() => new Date()),
})

export const posts = pgTable('posts', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  authorId: integer().notNull().references(() => users.id),
  title: varchar({ length: 200 }).notNull(),
  published: boolean().notNull().default(false),
  createdAt: timestamp().defaultNow().notNull(),
})

export const tags = pgTable('tags', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 40 }).notNull().unique(),
})
