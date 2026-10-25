import { beforeEach, expect, test } from 'bun:test'
import { listFeed } from '../src/feed'
import { comments, posts, users } from '../src/db/schema'
import { createTestDb } from '../src/db/test-db'

let t: Awaited<ReturnType<typeof createTestDb>>
beforeEach(async () => { t = await createTestDb() })

test('the feed lists published posts newest first, with author and comment count', async () => {
  const [ana] = await t.db.insert(users).values({ name: 'Ana' }).returning()
  const [p1] = await t.db.insert(posts).values({ authorId: ana.id, title: 'First', body: '…', published: true, createdAt: new Date('2026-01-01') }).returning()
  const [p2] = await t.db.insert(posts).values({ authorId: ana.id, title: 'Second', body: '…', published: true, createdAt: new Date('2026-01-02') }).returning()
  await t.db.insert(posts).values({ authorId: ana.id, title: 'Draft', body: '…' })
  await t.db.insert(comments).values([{ postId: p1.id, authorId: ana.id, body: 'hi' }, { postId: p1.id, authorId: ana.id, body: 'yo' }])

  const feed = await listFeed(t.db)
  expect(feed.map((f) => f.title)).toEqual(['Second', 'First'])
  expect(feed[0]).toMatchObject({ id: p2.id, author: { id: ana.id, name: 'Ana', avatarUrl: null }, commentCount: 0 })
  expect(feed[1].commentCount).toBe(2)
})
