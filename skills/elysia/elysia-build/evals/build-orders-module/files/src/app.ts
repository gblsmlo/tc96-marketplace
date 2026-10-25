import { Elysia } from 'elysia'
import { catalog } from './catalog'

export const app = new Elysia()
  .use(catalog)
  .get('/health', () => ({ ok: true }))
  .onError(({ error }) => ({ message: (error as Error).message }))

export type App = typeof app
