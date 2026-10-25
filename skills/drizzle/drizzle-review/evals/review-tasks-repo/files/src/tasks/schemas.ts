import { createInsertSchema, createSelectSchema } from 'drizzle-zod'
import { tasks } from '../db/schema'

export const createTaskBody = createInsertSchema(tasks)
export const taskResponse = createSelectSchema(tasks)
