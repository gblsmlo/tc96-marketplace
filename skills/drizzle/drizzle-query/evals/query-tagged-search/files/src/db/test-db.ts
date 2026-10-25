import { PGlite } from '@electric-sql/pglite'
import { pushSchema } from 'drizzle-kit/api'
import * as schema from './schema'
import { createDb } from './client'

/** A fresh in-memory PostgreSQL per test, built through the same createDb the app uses. */
export async function createTestDb() {
  const statements: string[] = []
  const db = createDb(new PGlite(), (sql) => statements.push(sql))
  const { apply } = await pushSchema(schema, db as any)
  await apply()
  statements.length = 0
  return { db, statements }
}
