import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createRoot } from 'react-dom/client'
import { OrdersTable } from './features/orders/OrdersTable'
import { ActivityFeed } from './features/orders/ActivityFeed'

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000 } },
})

createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <OrdersTable />
    <ActivityFeed />
  </QueryClientProvider>,
)
