import { boolean, integer, pgTable, text, timestamp, uniqueIndex, varchar } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 80 }).notNull(),
})

export const posts = pgTable('posts', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  authorId: integer().notNull().references(() => users.id),
  slug: varchar({ length: 120 }).notNull(),
  title: varchar({ length: 200 }).notNull(),
  body: text().notNull(),
  published: boolean().notNull().default(false),
  publishedAt: timestamp(),
  createdAt: timestamp().defaultNow().notNull(),
}, (t) => [uniqueIndex('posts_slug_idx').on(t.slug)])
