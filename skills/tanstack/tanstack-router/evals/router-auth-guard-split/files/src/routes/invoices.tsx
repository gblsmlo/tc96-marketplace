import { createRoute } from '@tanstack/react-router'
import { request } from '../http'
import type { Invoice } from '../types'
import { rootRoute } from './root'

function InvoicesPage() {
  const { invoices } = invoicesRoute.useRouteContext()
  return (
    <ul>
      {invoices.map((invoice) => (
        <li key={invoice.id}>{invoice.number}</li>
      ))}
    </ul>
  )
}

export const invoicesRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/invoices',
  beforeLoad: async () => {
    const res = await request('/invoices')
    return { invoices: (await res.json()) as Invoice[] }
  },
  component: InvoicesPage,
})
