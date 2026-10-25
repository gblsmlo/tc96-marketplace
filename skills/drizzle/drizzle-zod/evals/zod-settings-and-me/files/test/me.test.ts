import { expect, test } from 'bun:test'
import { getMe } from '../src/me'
import { users } from '../src/db/schema'
import { createTestDb } from '../src/db/test-db'

test('returns the current user', async () => {
  const { db } = await createTestDb()
  const [u] = await db.insert(users).values({ email: 'a@x.io', name: 'Ana', passwordHash: 'argon2id$…' }).returning()
  expect((await getMe(db, u.id)).email).toBe('a@x.io')
})
