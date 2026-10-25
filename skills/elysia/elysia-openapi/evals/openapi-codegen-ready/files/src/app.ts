import { Elysia } from 'elysia'
import { openapi } from '@elysia/openapi'
import { z } from 'zod'
import { usersModule } from './users'

export const app = new Elysia()
  .use(openapi({ mapJsonSchema: { zod: z.toJSONSchema } }))
  .get('/health', () => ({ ok: true }))
  .use(usersModule)

export type App = typeof app
