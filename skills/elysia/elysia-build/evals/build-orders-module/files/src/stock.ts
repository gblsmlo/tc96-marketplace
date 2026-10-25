const stock = new Map<string, number>([['ABC-1', 5], ['XYZ-9', 0]])

export const stockOf = (sku: string) => stock.get(sku) ?? 0

/** Reserves `quantity` units. Returns false when there is not enough stock. */
export function reserve(sku: string, quantity: number): boolean {
  const left = stock.get(sku) ?? 0
  if (left < quantity) return false
  stock.set(sku, left - quantity)
  return true
}
