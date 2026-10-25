import { and, eq, lt } from 'drizzle-orm'
import type { Database } from './db/client'
import { posts, tags, users } from './db/schema'

/** PATCH /me — the client sends only the fields that changed; bio: null means "remove my bio". */
export type UpdateProfileInput = { userId: number; patch: { name?: string; bio?: string | null } }

export async function updateProfile(db: Database, { userId, patch }: UpdateProfileInput) {
  const [user] = await db.update(users)
    .set({ name: patch.name, bio: patch.bio || undefined })
    .where(eq(users.id, userId))
    .returning()
  return user
}

/** DELETE /posts/:id — authors delete their own drafts. */
export type DeleteDraftInput = { userId: number; postId: number }

export async function deleteDraft(db: Database, { userId, postId }: DeleteDraftInput) {
  await db.delete(posts).where(eq(posts.id, postId))
}

/** Admin job: purge old drafts, optionally for one author. */
export type PurgeOldDraftsInput = { authorId?: number; olderThan?: Date }

export async function purgeOldDrafts(db: Database, opts: PurgeOldDraftsInput = {}) {
  const removed = await db.delete(posts)
    .where(and(
      opts.authorId ? eq(posts.authorId, opts.authorId) : undefined,
      opts.olderThan ? lt(posts.createdAt, opts.olderThan) : undefined,
    ))
    .returning({ id: posts.id })
  return removed.length
}

/** Import tags from a CSV upload. */
export async function importTags(db: Database, names: string[]) {
  return db.insert(tags).values(names.map((name) => ({ name: name.trim().toLowerCase() }))).returning()
}
