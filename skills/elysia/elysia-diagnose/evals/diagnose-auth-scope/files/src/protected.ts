import { Elysia } from 'elysia'
import { auth } from './auth'

/** Every feature module that needs a signed-in user starts from here. */
export const protectedRoutes = new Elysia({ name: 'protected' })
  .use(auth)
