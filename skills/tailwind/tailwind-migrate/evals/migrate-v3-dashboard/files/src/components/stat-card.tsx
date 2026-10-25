export function StatCard({ label, value, trend }: { label: string; value: string; trend: number }) {
  return (
    <div className="card flex flex-col gap-2 dark:bg-slate-900">
      <div className="flex items-center gap-2">
        <span className="rounded bg-brand px-2 py-0.5 text-xs text-white shadow-sm">{label}</span>
        <span className="flex-grow border-b" />
      </div>
      <p className="text-3xl font-semibold" style={{ ['--accent' as string]: trend > 0 ? '#16a34a' : '#dc2626' }}>
        <span className="text-[--accent]">{value}</span>
      </p>
      <input
        className="rounded border px-2 py-1 outline-none focus:ring focus:ring-brand"
        placeholder="Add a note"
      />
      <div className="rounded bg-black bg-opacity-50 p-2 text-white shadow">{trend}%</div>
    </div>
  )
}
