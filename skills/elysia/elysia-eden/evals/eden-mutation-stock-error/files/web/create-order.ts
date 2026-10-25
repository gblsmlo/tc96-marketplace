import { MutationObserver, type QueryClient } from '@tanstack/query-core'
import type { createApi } from './api'

type Api = ReturnType<typeof createApi>
export type OrderInput = { sku: string; quantity: number }

export const createOrderMutation = (client: QueryClient, api: Api) =>
  new MutationObserver(client, {
    mutationFn: async (input: OrderInput) => {
      const { data, error } = await api.orders.post(input)
      if (error) throw error
      return data
    },
  })

/** Message shown next to the SKU field. */
export function formError(error: unknown): string {
  // TODO: "Out of stock for <SKU>" — error.value.sku does not typecheck
  return 'Something went wrong'
}
