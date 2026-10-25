import { forwardRef } from 'react'
import { ProductCard } from '@/features/catalog/components/product-card'

export const PriceTag = forwardRef<HTMLSpanElement, { value: number }>(({ value }, ref) => (
  <span ref={ref}>${value.toFixed(2)}</span>
))

export const _unused = ProductCard
