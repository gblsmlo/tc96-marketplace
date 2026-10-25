import { useEffect, useState } from 'react'
import { request } from '../../http'
import type { OrdersPage } from '../../types'

const PAGE_SIZE = 20

export function OrdersTable() {
  const [page, setPage] = useState(1)
  const [data, setData] = useState<OrdersPage | null>(null)

  useEffect(() => {
    setData(null)
    request(`/orders?page=${page}&pageSize=${PAGE_SIZE}`)
      .then((res) => res.json())
      .then(setData)
  }, [page])

  if (!data) return <p>Loading…</p>

  return (
    <section>
      <table>
        <tbody>
          {data.items.map((order) => (
            <tr key={order.id}>
              <td>{order.number}</td>
              <td>{order.total}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <button type="button" disabled={page === 1} onClick={() => setPage((p) => p - 1)}>
        Previous
      </button>
      <span>Page {page}</span>
      <button type="button" disabled={!data.hasMore} onClick={() => setPage((p) => p + 1)}>
        Next
      </button>
    </section>
  )
}
