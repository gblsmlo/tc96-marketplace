import { Copy } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

type Order = { id: string; customer: string; total: number; paid: boolean }

export function OrderCard({ order, compact }: { order: Order; compact?: boolean }) {
  return (
    <article className={cn('rounded-lg border bg-background p-4 shadow-sm', compact && 'p-2')}>
      <header className="grid flex items-center justify-between gap-2">
        <h3 className="font-semibold text-[#0f766e]">{order.customer}</h3>
        <Badge tone={order.paid ? 'green' : 'amber'}>{order.paid ? 'Paid' : 'Pending'}</Badge>
      </header>
      <p className="sm:text-center mt-2 text-sm text-[#0f766e]">#{order.id}</p>
      <div className="mt-4 flex items-center gap-2 bg-black bg-opacity-50" style={{ padding: 12 }}>
        <span className="tabular-nums text-white font-medium text-lg">{order.total.toFixed(2)}</span>
        <button type="button" className="ml-auto rounded p-1 text-white">
          <Copy aria-hidden="true" className="size-4" />
        </button>
        <Button intent="primary">Refund</Button>
      </div>
    </article>
  )
}
