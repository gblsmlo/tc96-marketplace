import { count, desc, eq } from 'drizzle-orm'
import type { Database } from './db/client'
import { comments, posts, users } from './db/schema'

export type FeedItem = {
  id: number
  title: string
  createdAt: Date
  author: { id: number; name: string; avatarUrl: string | null }
  commentCount: number
}

/** GET /feed — published posts, newest first. */
export async function listFeed(db: Database): Promise<FeedItem[]> {
  const rows = await db.select().from(posts).where(eq(posts.published, true)).orderBy(desc(posts.createdAt))

  return Promise.all(
    rows.map(async (post) => {
      const [author] = await db.select().from(users).where(eq(users.id, post.authorId))
      const [{ total }] = await db.select({ total: count() }).from(comments).where(eq(comments.postId, post.id))
      return {
        id: post.id,
        title: post.title,
        createdAt: post.createdAt,
        author: { id: author.id, name: author.name, avatarUrl: author.avatarUrl },
        commentCount: total,
      }
    }),
  )
}
