import { Elysia, t } from 'elysia'

export const admin = new Elysia({ prefix: '/admin' })
  .delete('/users/:id', ({ params: { id } }) => ({ deleted: id }), { params: t.Object({ id: t.Number() }) })
  .get('/stats', () => ({ users: 2 }))
