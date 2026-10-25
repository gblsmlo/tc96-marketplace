import { Elysia } from 'elysia'

const valid = (authorization?: string) => authorization === 'Bearer tok-valid'

export const auth = new Elysia({ name: 'auth' })
  .onBeforeHandle(function verify({ headers }) {
    if (!valid(headers.authorization)) throw new Error('unauthenticated')
  })
  .get('/auth/me', () => ({ id: 1 }))
