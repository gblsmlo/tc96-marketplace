import { useMutation, useQueryClient } from '@tanstack/react-query'
import { request } from '../../http'
import type { Order } from '../../types'

export function useCreateOrder() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: { number: string; total: number }): Promise<Order> => {
      const res = await request('/orders', { method: 'POST', body: JSON.stringify(input) })
      if (!res.ok) throw new Error(`POST /orders failed: ${res.status}`)
      return res.json()
    },
    onSuccess: (order) => {
      queryClient.setQueryData<Order[]>(['orders', 'list', 'all'], (old) => {
        old?.push(order)
        return old
      })
      return queryClient.invalidateQueries({ queryKey: ['order'] })
    },
  })
}
