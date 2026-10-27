import { integer, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core"

export const quotes = pgTable("quotes", {
  id: uuid("id").primaryKey().defaultRandom(),
  sellerId: uuid("seller_id").notNull(),
  customerEmail: text("customer_email").notNull(),
  listPrice: integer("list_price").notNull(),
  discountPct: integer("discount_pct").notNull().default(0),
  status: text("status", { enum: ["pending", "approved", "rejected"] }).notNull().default("pending"),
  sentAt: timestamp("sent_at").notNull().defaultNow(),
  decidedAt: timestamp("decided_at"),
})

export const sessions = pgTable("sessions", {
  token: text("token").primaryKey(),
  userId: uuid("user_id").notNull(),
  role: text("role", { enum: ["admin", "seller"] }).notNull(),
})
