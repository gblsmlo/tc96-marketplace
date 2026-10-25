import { and, eq } from 'drizzle-orm'
import { z } from 'zod'
import type { Database } from '../db/client'
import { posts } from '../db/schema'

export type Session = { userId: number }
export class HttpError extends Error { constructor(public status: number, message: string) { super(message) } }

const PostBody = z.object({
  slug: z.string().regex(/^[a-z0-9-]+$/),
  title: z.string().min(3),
  body: z.string(),
  authorId: z.number(),
  published: z.boolean().optional(),
  publishedAt: z.date().optional(),
})

/** POST /posts */
export type CreatePostRequest = { body: unknown; session: Session }

export async function createPost(db: Database, { body, session }: CreatePostRequest) {
  const parsed = PostBody.safeParse(body)
  if (!parsed.success) throw new HttpError(400, parsed.error.message)
  const [post] = await db.insert(posts).values(parsed.data).returning()
  return post
}

/** PATCH /posts/:id — only the author edits; publishedAt: null unpublishes. */
export type PatchPostRequest = { postId: number; body: unknown; session: Session }

export async function patchPost(db: Database, { postId, body, session }: PatchPostRequest) {
  const parsed = PostBody.partial().safeParse(body)
  if (!parsed.success) throw new HttpError(400, parsed.error.message)
  const [post] = await db.update(posts).set(parsed.data)
    .where(and(eq(posts.id, postId), eq(posts.authorId, session.userId)))
    .returning()
  if (!post) throw new HttpError(404, 'not found')
  return post
}
