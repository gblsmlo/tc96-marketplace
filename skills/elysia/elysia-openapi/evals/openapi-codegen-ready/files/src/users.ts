import { Elysia, t } from 'elysia'
import { z } from 'zod'
import { auth } from './auth'

const User = t.Object({ id: t.Number(), name: t.String(), role: t.String() })
const users = [{ id: 1, name: 'Ana', role: 'admin' }]

export const usersModule = new Elysia({ prefix: '/users' })
  .use(auth)
  .get('/:id', ({ params: { id }, status }) => users.find((u) => u.id === id) ?? status(404, { error: 'not_found' }), {
    params: t.Object({ id: t.Number() }),
    response: { 200: User, 404: t.Object({ error: t.String() }) },
  })
  .get('/byId', ({ query: { id } }) => users.filter((u) => u.id === id), {
    query: t.Object({ id: t.Number() }),
    response: { 200: t.Array(User) },
  })
  .post('/', ({ body, status }) => status(201, { id: users.length + 1, ...body }), {
    body: z.object({ name: z.string().min(2), role: z.enum(['admin', 'member']).default('member') }),
    response: { 201: User },
  })
