import { Elysia, t } from 'elysia'

interface OrderInput { sku: string; quantity: number; note?: string }
interface Order { id: number; sku: string; quantity: number; note?: string; internalCost: number }

const orders: Order[] = Array.from({ length: 7 }, (_, i) => ({ id: i + 1, sku: `SKU-${i + 1}`, quantity: 1, internalCost: 3.2 }))

export const app = new Elysia()
  .guard({ headers: t.Object({ 'X-Tenant': t.String() }) })
  .get('/orders', ({ query }) => {
    const page = Number(query.page ?? 1)
    const pageSize = Number(query.pageSize ?? 20)
    return orders.slice((page - 1) * pageSize, page * pageSize)
  })
  .get('/orders/:id', ({ params, set }) => {
    const order = orders.find((o) => o.id === Number(params.id))
    if (!order) {
      set.status = 404
      return { error: 'not found' }
    }
    return order
  })
  .post('/orders', ({ body, set }) => {
    const input = body as OrderInput
    if (!input.sku) {
      set.status = 400
      return { error: 'sku required' }
    }
    const order: Order = { id: orders.length + 1, ...input, internalCost: 2.5 }
    orders.push(order)
    set.status = 201
    return order
  }, { headers: t.Object({ 'idempotency-key': t.String() }) })

export type App = typeof app
