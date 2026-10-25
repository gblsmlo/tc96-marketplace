import { relations } from 'drizzle-orm'
import { boolean, index, integer, pgTable, text, timestamp, varchar } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 80 }).notNull(),
  avatarUrl: text(),
})

export const posts = pgTable('posts', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  authorId: integer().notNull().references(() => users.id),
  title: varchar({ length: 200 }).notNull(),
  body: text().notNull(),
  published: boolean().notNull().default(false),
  createdAt: timestamp().defaultNow().notNull(),
}, (t) => [index('posts_published_created_idx').on(t.published, t.createdAt)])

export const comments = pgTable('comments', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  postId: integer().notNull().references(() => posts.id),
  authorId: integer().notNull().references(() => users.id),
  body: text().notNull(),
  createdAt: timestamp().defaultNow().notNull(),
})

export const usersRelations = relations(users, ({ many }) => ({ posts: many(posts) }))
export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id] }),
  comments: many(comments),
}))
export const commentsRelations = relations(comments, ({ one }) => ({
  post: one(posts, { fields: [comments.postId], references: [posts.id] }),
}))
