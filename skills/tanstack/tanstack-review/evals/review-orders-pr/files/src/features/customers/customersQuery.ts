import { queryOptions } from '@tanstack/react-query'
import { request } from '../../http'
import type { Customer } from '../../types'

export const customersQuery = (search: string) =>
  queryOptions({
    queryKey: ['customers', 'list', { search }],
    queryFn: async ({ signal }): Promise<Customer[]> => {
      const res = await request(`/customers?search=${encodeURIComponent(search)}`, { signal })
      if (!res.ok) throw new Error(`GET /customers failed: ${res.status}`)
      return res.json()
    },
    staleTime: 5 * 60_000,
  })
