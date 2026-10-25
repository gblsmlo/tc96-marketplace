import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useRef } from 'react'
import { request } from '../../http'
import type { Order } from '../../types'

export function useCancelOrder() {
  const queryClient = useQueryClient()
  const snapshot = useRef<Order[] | undefined>(undefined)

  return useMutation({
    mutationFn: async (orderId: string) => {
      const res = await request(`/orders/${orderId}/cancel`, { method: 'POST' })
      if (!res.ok) throw new Error(`cancel failed: ${res.status}`)
    },
    onMutate: (orderId) => {
      snapshot.current = queryClient.getQueryData<Order[]>(['orders'])
      queryClient.setQueryData<Order[]>(['orders'], (old) =>
        old?.map((order) => (order.id === orderId ? { ...order, status: 'cancelled' } : order)),
      )
    },
    onError: () => {
      queryClient.setQueryData(['orders'], snapshot.current)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}
