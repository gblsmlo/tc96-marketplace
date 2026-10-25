import { Elysia, t } from 'elysia'

export const profile = new Elysia()
  .get('/me', () => ({ name: 'TODO: the signed-in user' }))
  .patch('/me', ({ body }) => ({ renamed: body.name }), { body: t.Object({ name: t.String() }) })
