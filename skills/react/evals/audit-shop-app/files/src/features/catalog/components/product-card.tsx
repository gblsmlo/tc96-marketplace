import { memo, useMemo } from 'react'

type Props = { product: { id: string; name: string; price: number }; onAdd: () => void; style?: object }

export const ProductCard = memo(function ProductCard({ product, onAdd, style }: Props) {
  if (!product) return null
  const label = useMemo(() => `${product.name} — $${product.price}`, [product])
  return (
    <article style={style}>
      <h3>{label}</h3>
      <button onClick={onAdd}>Add</button>
    </article>
  )
})
