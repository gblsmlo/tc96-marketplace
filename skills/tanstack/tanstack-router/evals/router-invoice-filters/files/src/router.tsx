import { QueryClient } from '@tanstack/react-query'
import { createRouter } from '@tanstack/react-router'
import { invoiceRoute } from './routes/invoice'
import { invoicesRoute } from './routes/invoices'
import { rootRoute } from './routes/root'

export const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000 } },
})

const routeTree = rootRoute.addChildren([invoicesRoute, invoiceRoute])

export const router = createRouter({ routeTree, context: { queryClient } })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
