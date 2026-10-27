import { eq } from "drizzle-orm"
import { db } from "../db/client"
import { sessions } from "../db/schema"
import type { Role } from "./auth"

export type Session = { user: { id: string; role: Role } }

export async function readSession(token: string | undefined): Promise<Session | null> {
  if (!token) return null
  const [row] = await db.select().from(sessions).where(eq(sessions.token, token))
  return row ? { user: { id: row.userId, role: row.role } } : null
}
