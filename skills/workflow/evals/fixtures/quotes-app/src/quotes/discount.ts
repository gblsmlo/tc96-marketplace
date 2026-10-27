/** Total after a percentage discount (AC-07). */
export function applyDiscount(listPrice: number, discountPct: number): number {
  return Math.round(listPrice * (1 - discountPct / 100))
}
