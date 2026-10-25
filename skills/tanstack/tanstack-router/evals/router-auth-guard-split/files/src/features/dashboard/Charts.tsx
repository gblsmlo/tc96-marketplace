// Stands in for a ~400 kB charting bundle.
export function Charts({ series }: { series: number[] }) {
  return (
    <svg width={600} height={200} role="img" aria-label="Revenue">
      {series.map((value, i) => (
        <rect key={i} x={i * 20} y={200 - value} width={16} height={value} />
      ))}
    </svg>
  )
}
