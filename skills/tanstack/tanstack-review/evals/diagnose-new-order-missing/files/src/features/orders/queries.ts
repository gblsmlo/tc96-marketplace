import { queryOptions } from '@tanstack/react-query'
import { request } from '../../http'
import type { Order, OrderStatus } from '../../types'

export const ordersListQuery = (status: OrderStatus | 'all') =>
  queryOptions({
    queryKey: ['orders', 'list', status],
    queryFn: async ({ signal }): Promise<Order[]> => {
      const res = await request(`/orders?status=${status}`, { signal })
      if (!res.ok) throw new Error(`GET /orders failed: ${res.status}`)
      return res.json()
    },
  })
