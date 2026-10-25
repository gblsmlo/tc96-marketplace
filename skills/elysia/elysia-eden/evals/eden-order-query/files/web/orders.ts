import type { createApi } from './api'

type Api = ReturnType<typeof createApi>

export const orderQuery = (api: Api, id: number) => ({
  queryKey: ['orders', 'detail', id] as const,
  queryFn: () => api.orders({ id }).get(),
})

export const ordersPageQuery = (api: Api, page: number) => ({
  queryKey: ['orders', 'list', { page }] as const,
  queryFn: async () => (await api.orders.get({ query: { page } })).data,
})

/** Text for the error toast. */
export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Something went wrong'
}
