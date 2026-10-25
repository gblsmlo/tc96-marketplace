import { index, integer, pgEnum, pgTable, text, timestamp, varchar } from 'drizzle-orm/pg-core'

export const cardStatus = pgEnum('card_status', ['todo', 'doing', 'done', 'archived'])

export const boards = pgTable('boards', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 120 }).notNull(),
})

export const cards = pgTable('cards', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  boardId: integer().notNull().references(() => boards.id),
  parentId: integer().references(() => cards.id),
  title: varchar({ length: 200 }).notNull(),
  status: cardStatus().notNull().default('todo'),
  createdAt: timestamp().defaultNow().notNull(),
}, (t) => [index('cards_board_idx').on(t.boardId), index('cards_board_status_idx').on(t.boardId, t.status)])

// who moved which card, for the activity feed
const cardEvents = pgTable('card_events', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  cardId: integer().notNull().references(() => cards.id),
  event: text().notNull(),
  at: timestamp().defaultNow().notNull(),
})
