import type { PGlite } from '@electric-sql/pglite'
import { drizzle } from 'drizzle-orm/pglite'
import { comments, posts, users } from './schema'

// In production this receives the pooled client; tests pass an in-memory PGlite.
export function createDb(client: PGlite, onQuery?: (sql: string) => void) {
  return drizzle({
    client,
    schema: { users, posts, comments },
    logger: onQuery ? { logQuery: (sql) => onQuery(sql) } : false,
  })
}
export type Database = ReturnType<typeof createDb>
