import { createRouter } from '@tanstack/react-router'
import { queryClient } from './queryClient'
import { loginRoute, orderRoute, ordersRoute } from './routes/orders'
import { rootRoute } from './routes/root'

const routeTree = rootRoute.addChildren([ordersRoute, orderRoute, loginRoute])

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
