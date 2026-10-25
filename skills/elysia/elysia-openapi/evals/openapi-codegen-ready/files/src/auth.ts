import { Elysia } from 'elysia'

const tokens = new Map([['tok-ana', { id: 1 }]])

export const auth = new Elysia({ name: 'auth' })
  .resolve({ as: 'scoped' }, function resolveUser({ headers: { authorization }, status }) {
    const user = authorization?.startsWith('Bearer ') ? tokens.get(authorization.slice(7)) : undefined
    if (!user) return status(401, { error: 'unauthenticated' })
    return { user }
  })
