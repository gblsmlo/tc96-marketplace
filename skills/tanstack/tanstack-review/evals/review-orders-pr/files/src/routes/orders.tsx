import { useSuspenseQuery } from '@tanstack/react-query'
import { createRoute, Link } from '@tanstack/react-router'
import { ordersQuery } from '../features/orders/queries'
import { useCancelOrder } from '../features/orders/useCancelOrder'
import type { OrderStatus } from '../types'
import { rootRoute } from './root'

function OrdersPage() {
  const search = ordersRoute.useSearch() as { status?: OrderStatus | 'all' }
  const { data: orders } = useSuspenseQuery(ordersQuery(search.status ?? 'all'))
  const cancel = useCancelOrder()

  return (
    <ul>
      {orders.map((order) => (
        <li key={order.id}>
          <Link to="/orders/$orderId" params={{ orderId: order.id }}>
            {order.number}
          </Link>
          <button type="button" onClick={() => cancel.mutate(order.id)}>
            Cancel
          </button>
        </li>
      ))}
    </ul>
  )
}

export const ordersRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/orders',
  loaderDeps: ({ search }) => search,
  loader: ({ context, deps }) =>
    context.queryClient.ensureQueryData(ordersQuery((deps as { status?: OrderStatus }).status ?? 'all')),
  component: OrdersPage,
})

export const orderRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/orders/$orderId',
  component: () => <h1>Order</h1>,
})

export const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/login',
  component: () => <h1>Login</h1>,
})
