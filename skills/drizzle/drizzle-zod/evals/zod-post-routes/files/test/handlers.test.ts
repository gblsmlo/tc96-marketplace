import { expect, test } from 'bun:test'
import { createPost } from '../src/posts/handlers'
import { users } from '../src/db/schema'
import { createTestDb } from '../src/db/test-db'

test('creates a post', async () => {
  const { db } = await createTestDb()
  const [ana] = await db.insert(users).values({ name: 'Ana' }).returning()
  const post = await createPost(db, { body: { slug: 'hello', title: 'Hello', body: '…', authorId: ana.id }, session: { userId: ana.id } })
  expect(post.slug).toBe('hello')
})
