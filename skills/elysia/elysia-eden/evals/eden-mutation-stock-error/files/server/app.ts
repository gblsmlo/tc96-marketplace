import { Elysia, t } from 'elysia'

const stock = new Map<string, number>([['ABC-1', 3]])

export const app = new Elysia()
  .post('/orders', ({ body, status }) => {
    const left = stock.get(body.sku) ?? 0
    if (left < body.quantity) throw status(409, { error: 'out_of_stock', sku: body.sku })
    stock.set(body.sku, left - body.quantity)
    return { id: 1, ...body }
  }, {
    body: t.Object({ sku: t.String(), quantity: t.Number({ minimum: 1 }) }),
  })

export type App = typeof app
