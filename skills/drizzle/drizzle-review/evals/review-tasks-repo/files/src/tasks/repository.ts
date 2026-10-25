import { and, eq, sql } from 'drizzle-orm'
import type { Database } from '../db/client'
import { projects, tasks, users } from '../db/schema'
import { createTaskBody } from './schemas'

/** GET /projects/:id/tasks */
export async function listProjectTasks(db: Database, projectId: number) {
  const rows = await db.select().from(tasks).where(eq(tasks.projectId, projectId))
  return Promise.all(rows.map(async (task) => {
    const [owner] = await db.select({ id: users.id, name: users.name }).from(users).where(eq(users.id, task.ownerId))
    return { ...task, owner }
  }))
}

/** GET /projects/:id — with its tasks and owners */
export function getProject(db: Database, projectId: number) {
  return db.query.projects.findFirst({
    where: (p, { eq }) => eq(p.id, projectId),
    with: { owner: true, tasks: { with: { owner: true } } },
  })
}

/** GET /tasks/search?q= */
export type SearchTasksInput = { userId: number; q: string }

export function searchTasks(db: Database, { userId, q }: SearchTasksInput) {
  return db.select().from(tasks)
    .where(and(eq(tasks.ownerId, userId), sql.raw(`title ilike '%${q}%'`)))
    .limit(50)
}

/** POST /tasks */
export async function createTask(db: Database, body: unknown) {
  const input = createTaskBody.parse(body)
  const [task] = await db.insert(tasks).values(input).returning()
  return task
}

/** POST /tasks/:id/complete — awards the task's points to the project owner's score once */
export type CompleteTaskInput = { userId: number; taskId: number }

export async function completeTask(db: Database, { userId, taskId }: CompleteTaskInput) {
  const [task] = await db.select().from(tasks).where(eq(tasks.id, taskId))
  if (!task || task.ownerId !== userId) throw new Error('not found')
  if (task.done) return task
  return db.transaction(async (tx) => {
    const [updated] = await tx.update(tasks).set({ done: true }).where(eq(tasks.id, taskId)).returning()
    await db.update(projects).set({ name: sql`${projects.name}` }).where(eq(projects.id, task.projectId))
    return updated
  })
}

/** POST /projects/:id/archive-done — archives the finished tasks of a project */
export type ArchiveDoneInput = { projectId: number; everything?: boolean }

export async function archiveDone(db: Database, { projectId, everything = false }: ArchiveDoneInput) {
  if (everything) {
    return db.update(tasks).set({ archived: true })
  }
  return db.update(tasks).set({ archived: true }).where(and(eq(tasks.projectId, projectId), eq(tasks.done, true)))
}
