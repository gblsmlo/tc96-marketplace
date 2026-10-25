import { Elysia, t } from 'elysia'
import { openapi } from '@elysia/openapi'

let remaining = 100

const orders = new Elysia({ prefix: '/orders', detail: { tags: ['orders'] } })
  .get('', ({ set }) => {
    set.headers['x-ratelimit-remaining'] = String(--remaining)
    return [{ id: 1, total: 10 }]
  }, {
    response: { 200: t.Array(t.Object({ id: t.Number(), total: t.Number() })) },
    detail: { summary: 'List orders' },
  })
  .post('/', ({ body, status }) => status(201, { id: 2, ...body }), {
    body: t.Object({ total: t.Number() }),
    response: { 201: t.Object({ id: t.Number(), total: t.Number() }) },
    detail: { summary: 'Create an order' },
  })

const admin = new Elysia({ prefix: '/admin' })
  .guard({ detail: { tags: ['admin'], summary: 'Admin' } }, (app) => app
    .get('/stats', () => ({ orders: 2 }), { detail: { summary: 'Order statistics' } })
    .post('/reindex', () => ({ ok: true }), { detail: { summary: 'Rebuild the search index' } })
  )

const internal = new Elysia({ prefix: '/internal' })
  .get('/metrics', () => 'up 1')
  .get('/debug/config', () => ({ env: 'test' }))

export const app = new Elysia()
  .use(openapi({ exclude: { tags: ['internal'] } }))
  .get('/health', () => ({ ok: true }))
  .use(orders)
  .use(admin)
  .use(internal)

export type App = typeof app
