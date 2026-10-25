import { Elysia, t } from 'elysia'
import { stockOf } from './stock'

export const catalog = new Elysia({ prefix: '/catalog' })
  .get('/:sku', ({ params: { sku } }) => ({ sku, available: stockOf(sku) }), {
    params: t.Object({ sku: t.String() })
  })
