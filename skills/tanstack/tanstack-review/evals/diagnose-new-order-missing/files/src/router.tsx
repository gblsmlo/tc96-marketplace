import { createRouter } from '@tanstack/react-router'
import { queryClient } from './queryClient'
import { newOrderRoute, ordersRoute } from './routes/orders'
import { rootRoute } from './routes/root'

const routeTree = rootRoute.addChildren([ordersRoute, newOrderRoute])

export const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreload: 'intent',
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
