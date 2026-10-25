import { useEffect, useState } from 'react'
import { ProductCard } from './product-card'
import { useCartTotals } from '@/features/checkout/hooks/use-cart-totals'

type Product = { id: string; name: string; price: number; category: string }

export function ProductList({ initialCategory }: { initialCategory?: string }) {
  const [products, setProducts] = useState<Product[]>([])
  const [category, setCategory] = useState(initialCategory ?? 'all')
  const [visible, setVisible] = useState<Product[]>([])
  const { count } = useCartTotals()

  useEffect(() => {
    fetch('/api/products')
      .then((r) => r.json())
      .then(setProducts)
  }, [])

  useEffect(() => {
    setVisible(category === 'all' ? products : products.filter((p) => p.category === category))
  }, [products, category])

  return (
    <section>
      <select value={category} onChange={(e) => setCategory(e.target.value)}>
        <option value="all">All</option>
        <option value="books">Books</option>
      </select>
      <p>{count} in cart</p>
      {visible.map((p, index) => (
        <ProductCard key={index} product={p} onAdd={() => console.log(p.id)} style={{ margin: 4 }} />
      ))}
    </section>
  )
}
