import { Elysia } from 'elysia'
import { logger } from './logger'

export const orders = new Elysia({ prefix: '/orders' })
  .use(logger)
  .get('', () => [{ id: 1 }])
