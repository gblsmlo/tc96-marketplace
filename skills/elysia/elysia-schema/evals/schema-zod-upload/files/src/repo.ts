import type { SignUp } from './shared/user'

const rows: unknown[] = []

/** Inserts a user. Rows come back from the driver as plain JSON, like our Postgres client returns them. */
export function insertUser(input: SignUp) {
  const row = { id: rows.length + 1, name: input.name, email: input.email, plan: input.plan, createdAt: new Date().toISOString() }
  rows.push(row)
  return JSON.parse(JSON.stringify(row))
}
