import { Elysia } from "elysia"
import { readSession } from "./session"

export type Role = "admin" | "seller"

export const authMiddleware = new Elysia({ name: "auth" }).derive(async ({ cookie }) => {
  const session = await readSession(cookie.session?.value)
  return { user: session?.user ?? null }
})

/** An admin may do whatever a seller may; a seller may not do what only an admin may (ADR-0002). */
export function requireRole(role: Role) {
  return ({ user, error }: { user: { id: string; role: Role } | null; error: (code: number) => unknown }) => {
    if (!user) return error(401)
    if (user.role !== role && user.role !== "admin") return error(403)
  }
}
