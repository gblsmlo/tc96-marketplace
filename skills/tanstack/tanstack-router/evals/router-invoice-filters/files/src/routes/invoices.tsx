import { useQuery } from '@tanstack/react-query'
import { createRoute } from '@tanstack/react-router'
import { useEffect, useState } from 'react'
import { request } from '../http'
import type { Invoice, InvoiceStatus } from '../types'
import { rootRoute } from './root'

type Sort = 'number' | 'amount'

interface InvoicesPage {
  items: Invoice[]
  hasMore: boolean
}

function InvoicesList() {
  const params = new URLSearchParams(window.location.search)
  const [status, setStatus] = useState<InvoiceStatus | 'all'>((params.get('status') as InvoiceStatus) ?? 'all')
  const [page, setPage] = useState(Number(params.get('page') ?? 1))
  const [sort, setSort] = useState<Sort>((params.get('sort') as Sort) ?? 'number')

  useEffect(() => {
    window.history.replaceState(null, '', `/invoices?status=${status}&page=${page}&sort=${sort}`)
  }, [status, page, sort])

  const { data, isPending } = useQuery({
    queryKey: ['invoices', status],
    queryFn: async () => {
      const res = await request(`/invoices?status=${status}&page=${page}&sort=${sort}`)
      return (await res.json()) as InvoicesPage
    },
  })

  return (
    <section>
      <select value={status} onChange={(e) => setStatus(e.target.value as InvoiceStatus | 'all')}>
        <option value="all">All</option>
        <option value="pending">Pending</option>
        <option value="approved">Approved</option>
        <option value="rejected">Rejected</option>
      </select>
      <button type="button" onClick={() => setSort(sort === 'number' ? 'amount' : 'number')}>
        Sort by {sort === 'number' ? 'amount' : 'number'}
      </button>
      {isPending ? (
        <p>Loading…</p>
      ) : (
        <ul>
          {data?.items.map((invoice) => (
            <li key={invoice.id}>
              <a href={`/invoices/${invoice.id}`}>{invoice.number}</a> · {invoice.amount}
            </li>
          ))}
        </ul>
      )}
      <button type="button" disabled={page === 1} onClick={() => setPage(page - 1)}>
        Previous
      </button>
      <button type="button" disabled={!data?.hasMore} onClick={() => setPage(page + 1)}>
        Next
      </button>
    </section>
  )
}

export const invoicesRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/invoices',
  component: InvoicesList,
})
