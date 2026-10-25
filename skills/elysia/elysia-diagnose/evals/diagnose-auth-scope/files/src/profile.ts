import { Elysia, t } from 'elysia'
import { protectedRoutes } from './protected'

export const profile = new Elysia({ prefix: '/profile' })
  .use(protectedRoutes)
  .patch('/rename', ({ body }) => ({ renamed: body.name }), { body: t.Object({ name: t.String() }) })
