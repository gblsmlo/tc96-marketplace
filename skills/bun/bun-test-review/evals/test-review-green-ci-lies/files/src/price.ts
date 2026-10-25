export const config = { currency: "USD", taxRate: 0.1 };

export function priceWithTax(amount: number): number {
  return Math.round(amount * (1 + config.taxRate) * 100) / 100;
}

export function formatPrice(amount: number): string {
  return `${config.currency} ${amount.toFixed(2)}`;
}
