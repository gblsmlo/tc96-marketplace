import { Elysia, t } from 'elysia'

const Order = t.Object({ id: t.Number(), sku: t.String(), total: t.Number(), createdAt: t.String() })
const db = Array.from({ length: 6 }, (_, i) => ({ id: i + 1, sku: `SKU-${i + 1}`, total: 10 * (i + 1), createdAt: '2026-10-20T10:00:00.000Z' }))

export const app = new Elysia()
  .get('/orders', ({ query: { page } }) => ({ items: db.slice((page - 1) * 3, page * 3), total: db.length, hasMore: page * 3 < db.length }), {
    query: t.Object({ page: t.Number({ minimum: 1 }) }),
    response: { 200: t.Object({ items: t.Array(Order), total: t.Number(), hasMore: t.Boolean() }) },
  })
  .get('/orders/:id', ({ params: { id }, status }) => {
    const order = db.find((o) => o.id === id)
    if (!order) return status(404, { error: 'not_found', id })
    return order
  }, {
    params: t.Object({ id: t.Number() }),
    response: { 200: Order, 404: t.Object({ error: t.String(), id: t.Number() }) },
  })

export type App = typeof app
