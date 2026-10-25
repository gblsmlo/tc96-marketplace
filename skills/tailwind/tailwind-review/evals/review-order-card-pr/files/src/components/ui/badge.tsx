type Tone = 'green' | 'amber' | 'red'

export function Badge({ tone, children }: { tone: Tone; children: React.ReactNode }) {
  return <span className={`bg-${tone}-100 text-${tone}-800 rounded-full px-2 py-0.5 text-xs`}>{children}</span>
}
