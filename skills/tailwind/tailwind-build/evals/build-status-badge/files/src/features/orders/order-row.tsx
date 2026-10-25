type Order = { id: string; customer: string; total: number; status: 'paid' | 'pending' | 'failed' | 'refunded' }

export function OrderRow({ order }: { order: Order }) {
  return (
    <tr className="border-b">
      <td className="px-4 py-3 font-mono text-sm">{order.id}</td>
      <td className="px-4 py-3">{order.customer}</td>
      <td className="px-4 py-3 text-right tabular-nums">{order.total.toFixed(2)}</td>
      <td className="px-4 py-3">{order.status}</td>
    </tr>
  )
}
