import { expect, test } from 'bun:test'
import { users } from '../src/db/schema'
import { createTestDb } from '../src/db/test-db'

test('the test database starts empty', async () => {
  const { db } = await createTestDb()
  expect(await db.select().from(users)).toEqual([])
})
