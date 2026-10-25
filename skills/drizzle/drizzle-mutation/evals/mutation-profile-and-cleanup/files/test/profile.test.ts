import { expect, test } from 'bun:test'
import { updateProfile } from '../src/profile'
import { users } from '../src/db/schema'
import { createTestDb } from '../src/db/test-db'

test('updates the name', async () => {
  const { db } = await createTestDb()
  const [u] = await db.insert(users).values({ name: 'Ana', bio: 'hello' }).returning()
  const updated = await updateProfile(db, { userId: u.id, patch: { name: 'Ana B' } })
  expect(updated.name).toBe('Ana B')
  expect(updated.bio).toBe('hello')
})
