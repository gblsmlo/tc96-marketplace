import { Elysia, t } from 'elysia'
import { z } from 'zod'
import { SignUp } from './shared/user'
import { insertUser } from './repo'

export const app = new Elysia()
  .post('/users', ({ body, status }) => status(201, insertUser(body)), {
    body: SignUp,
    response: { 201: t.Object({ id: t.Number(), name: t.String(), email: t.String(), plan: t.String() }) },
  })
  .post('/users/:id/avatar', ({ params: { id }, body }) => ({ id, file: body.avatar.name, size: body.avatar.size }), {
    params: t.Object({ id: t.Number() }),
    body: z.object({ avatar: z.file() }),
  })

export type App = typeof app
