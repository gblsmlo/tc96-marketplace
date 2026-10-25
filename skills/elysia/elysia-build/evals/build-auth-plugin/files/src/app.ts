import { Elysia } from 'elysia'
import { profile } from './profile'
import { admin } from './admin'

export const app = new Elysia()
  .get('/health', () => ({ ok: true }))
  .use(profile)
  .use(admin)

export type App = typeof app
