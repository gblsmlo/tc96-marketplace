import { drizzle } from 'drizzle-orm/node-postgres'
import { projects, tasks, users } from './schema'

export const db = drizzle(process.env.DATABASE_URL!, { schema: { users, projects, tasks } })
export type Database = typeof db
