import type { PGlite } from '@electric-sql/pglite'
import { drizzle } from 'drizzle-orm/pglite'
import * as schema from './schema'

export function createDb(client: PGlite, onQuery?: (sql: string) => void) {
  return drizzle({ client, schema, logger: onQuery ? { logQuery: (sql) => onQuery(sql) } : false })
}
export type Database = ReturnType<typeof createDb>
