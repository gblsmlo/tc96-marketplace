import { Elysia } from 'elysia'
import { logger } from './logger'

export const reports = new Elysia({ prefix: '/reports' })
  .use(logger)
  .get('', () => ({ revenue: 1200 }))
