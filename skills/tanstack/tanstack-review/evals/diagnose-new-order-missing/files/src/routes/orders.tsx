import { useSuspenseQuery } from '@tanstack/react-query'
import { createRoute, useNavigate } from '@tanstack/react-router'
import type { FormEvent } from 'react'
import { ordersListQuery } from '../features/orders/queries'
import { useCreateOrder } from '../features/orders/useCreateOrder'
import { rootRoute } from './root'

function OrdersPage() {
  const { data: orders } = useSuspenseQuery(ordersListQuery('all'))
  return (
    <ul>
      {orders.map((order) => (
        <li key={order.id}>
          {order.number} · {order.total}
        </li>
      ))}
    </ul>
  )
}

function NewOrderPage() {
  const create = useCreateOrder()
  const navigate = useNavigate()

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    create.mutate(
      { number: String(form.get('number')), total: Number(form.get('total')) },
      { onSuccess: () => navigate({ to: '/orders' }) },
    )
  }

  return (
    <form onSubmit={onSubmit}>
      <input name="number" />
      <input name="total" type="number" />
      <button type="submit" disabled={create.isPending}>
        Create
      </button>
    </form>
  )
}

export const ordersRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/orders',
  loader: ({ context }) => context.queryClient.ensureQueryData(ordersListQuery('all')),
  errorComponent: () => <p>Could not load orders.</p>,
  component: OrdersPage,
})

export const newOrderRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/orders/new',
  component: NewOrderPage,
})
