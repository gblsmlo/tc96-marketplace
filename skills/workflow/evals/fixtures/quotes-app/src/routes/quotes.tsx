import { createFileRoute } from "@tanstack/react-router"
import { useQuery } from "@tanstack/react-query"
import { quotesQuery } from "../quotes/queries"
import "../styles/badges.css"

export const Route = createFileRoute("/quotes")({ component: QuotesPage })

type Row = { id: string; customerEmail: string; listPrice: number; status: "pending" | "approved" | "rejected" }

function QuotesPage() {
  const { data = [], isPending, isError } = useQuery(quotesQuery)
  if (isPending) return <p>Loading quotes…</p>
  if (isError) return <p role="alert">Could not load quotes.</p>
  if (data.length === 0) return <p>No quotes yet.</p>
  return <QuotesTable data={data} />
}

export function QuotesTable({ data }: { data: Row[] }) {
  return (
    <table>
      <tbody>
        {data.map((q) => (
          <tr key={q.id}>
            <td>{q.customerEmail}</td>
            <td>{q.listPrice}</td>
            <td><span className={`badge badge-${q.status}`}>{q.status}</span></td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
