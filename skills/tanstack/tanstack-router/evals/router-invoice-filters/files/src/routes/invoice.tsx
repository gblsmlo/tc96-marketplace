import { useQuery } from '@tanstack/react-query'
import { createRoute } from '@tanstack/react-router'
import { request } from '../http'
import type { Invoice } from '../types'
import { rootRoute } from './root'

function InvoiceDetail() {
  const { invoiceId } = invoiceRoute.useParams()
  const { data } = useQuery({
    queryKey: ['invoices', 'detail', invoiceId],
    queryFn: async () => {
      const res = await request(`/invoices/${invoiceId}`)
      if (!res.ok) throw new Error(`GET /invoices/${invoiceId} failed: ${res.status}`)
      return (await res.json()) as Invoice
    },
  })
  return data ? <h1>{data.number}</h1> : null
}

export const invoiceRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/invoices/$invoiceId',
  component: InvoiceDetail,
})
