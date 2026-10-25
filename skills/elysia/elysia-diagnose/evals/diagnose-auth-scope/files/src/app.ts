import { Elysia } from 'elysia'
import { profile } from './profile'

export const app = new Elysia()
  .use(profile)

export type App = typeof app
