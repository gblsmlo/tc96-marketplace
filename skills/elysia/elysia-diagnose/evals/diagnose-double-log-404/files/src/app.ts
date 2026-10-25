import { Elysia } from 'elysia'
import { orders } from './orders'
import { reports } from './reports'

export const app = new Elysia()
  .use(orders)
  .use(reports)

export type App = typeof app
