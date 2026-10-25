import { queryOptions } from '@tanstack/react-query'
import type { Order, OrderStatus } from '../../types'

export const ordersQuery = (status: OrderStatus | 'all') =>
  queryOptions({
    queryKey: ['orders'],
    queryFn: async (): Promise<Order[]> => {
      const res = await fetch(`/api/orders?status=${status}`)
      return res.json()
    },
  })
