import { Suspense } from 'react'
import { ProductList } from '@/features/catalog/components/product-list'
import { CheckoutForm } from '@/features/checkout/components/checkout-form'

export function App() {
  return (
    <Suspense fallback={<p>Loading…</p>}>
      <ProductList />
      <CheckoutForm />
    </Suspense>
  )
}
