import { useEffect, useState } from 'react'
import { request } from '../../http'
import type { Customer, Invoice, InvoiceStatus, InvoiceSummary } from '../../types'

export function InvoicesPage() {
  const [status, setStatus] = useState<InvoiceStatus | 'all'>('pending')
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [summary, setSummary] = useState<InvoiceSummary | null>(null)
  const [customers, setCustomers] = useState<Customer[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    request(`/invoices?status=${status}`)
      .then((res) => res.json())
      .then((data: Invoice[]) => {
        setInvoices(data)
        setLoading(false)
      })
  }, [status])

  useEffect(() => {
    request('/invoices/summary')
      .then((res) => res.json())
      .then(setSummary)
    request('/customers')
      .then((res) => res.json())
      .then(setCustomers)
  }, [])

  async function approve(id: string) {
    await request(`/invoices/${id}/approve`, { method: 'POST' })
    const res = await request(`/invoices?status=${status}`)
    setInvoices(await res.json())
  }

  const customerName = (id: string) => customers.find((c) => c.id === id)?.name ?? id

  return (
    <section>
      <h1>Invoices</h1>
      {summary && (
        <p>
          {summary.pendingCount} pending, {summary.pendingTotal} total
        </p>
      )}
      <select value={status} onChange={(e) => setStatus(e.target.value as InvoiceStatus | 'all')}>
        <option value="all">All</option>
        <option value="pending">Pending</option>
        <option value="approved">Approved</option>
        <option value="rejected">Rejected</option>
      </select>
      {loading ? (
        <p>Loading…</p>
      ) : (
        <ul>
          {invoices.map((invoice) => (
            <li key={invoice.id}>
              {invoice.number} · {customerName(invoice.customerId)} · {invoice.amount} · {invoice.status}
              {invoice.status === 'pending' && (
                <button type="button" onClick={() => approve(invoice.id)}>
                  Approve
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
