import { eq } from 'drizzle-orm'
import { z } from 'zod'
import type { Database } from './db/client'
import { users } from './db/schema'

/** GET /me */
export async function getMe(db: Database, userId: number) {
  const [user] = await db.select().from(users).where(eq(users.id, userId))
  return user
}

const ProfilePatch = z.object({ name: z.string().min(2).optional(), bio: z.string().max(280).optional() })

/** PATCH /me — bio: null removes it. */
export type PatchMeRequest = { userId: number; body: unknown }

export async function patchMe(db: Database, { userId, body }: PatchMeRequest) {
  const patch = ProfilePatch.parse(body)
  const [user] = await db.update(users).set(patch).where(eq(users.id, userId)).returning()
  return user
}

/** PATCH /me/settings */
export type UpdateSettingsRequest = { userId: number; body: any }

export async function updateSettings(db: Database, { userId, body }: UpdateSettingsRequest) {
  const [user] = await db.update(users).set({ settings: body.settings }).where(eq(users.id, userId)).returning()
  return user
}
