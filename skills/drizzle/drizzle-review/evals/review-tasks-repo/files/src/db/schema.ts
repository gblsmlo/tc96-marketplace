import { relations } from 'drizzle-orm'
import { boolean, integer, pgTable, text, timestamp, varchar } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  email: varchar({ length: 120 }).notNull().unique(),
  name: varchar({ length: 80 }).notNull(),
})

export const projects = pgTable('projects', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  ownerId: integer().notNull().references(() => users.id),
  name: varchar({ length: 120 }).notNull(),
  shareToken: text().notNull().default(crypto.randomUUID()),
})

export const tasks = pgTable('tasks', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  projectId: integer().notNull().references(() => projects.id),
  ownerId: integer().notNull().references(() => users.id),
  title: varchar({ length: 200 }).notNull(),
  done: boolean().notNull().default(false),
  archived: boolean().notNull().default(false),
  points: integer().notNull().default(0),
  createdAt: timestamp().defaultNow().notNull(),
})

export const usersRelations = relations(users, ({ many }) => ({ tasks: many(tasks), projects: many(projects) }))
export const projectsRelations = relations(projects, ({ one, many }) => ({
  owner: one(users, { fields: [projects.ownerId], references: [users.id] }),
  tasks: many(tasks),
}))
export const tasksRelations = relations(tasks, ({ one }) => ({
  project: one(projects, { fields: [tasks.projectId], references: [projects.id] }),
  owner: one(users, { fields: [tasks.ownerId], references: [users.id] }),
}))
