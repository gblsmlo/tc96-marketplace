import { useEffect, useState } from 'react'

export function useCartTotals() {
  const [items, setItems] = useState<{ price: number; qty: number }[]>([])
  const [count, setCount] = useState(0)

  useEffect(async () => {
    const res = await fetch('/api/cart')
    setItems(await res.json())
  }, [])

  useEffect(() => {
    setCount(items.length)
  }, [items])

  const sorted = items.sort((a, b) => a.price - b.price)
  return { items: sorted, count }
}
