import { relations } from 'drizzle-orm'
import { boolean, integer, pgTable, primaryKey, text, timestamp, varchar } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 80 }).notNull(),
})

export const posts = pgTable('posts', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  authorId: integer().notNull().references(() => users.id),
  title: varchar({ length: 200 }).notNull(),
  body: text().notNull(),
  published: boolean().notNull().default(false),
  publishedAt: timestamp(),
})

export const tags = pgTable('tags', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 40 }).notNull().unique(),
})

export const postsToTags = pgTable('posts_to_tags', {
  postId: integer().notNull().references(() => posts.id),
  tagId: integer().notNull().references(() => tags.id),
}, (t) => [primaryKey({ columns: [t.postId, t.tagId] })])

export const usersRelations = relations(users, ({ many }) => ({ posts: many(posts) }))
export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id] }),
  postsToTags: many(postsToTags),
}))
export const tagsRelations = relations(tags, ({ many }) => ({ postsToTags: many(postsToTags) }))
export const postsToTagsRelations = relations(postsToTags, ({ one }) => ({
  post: one(posts, { fields: [postsToTags.postId], references: [posts.id] }),
  tag: one(tags, { fields: [postsToTags.tagId], references: [tags.id] }),
}))
