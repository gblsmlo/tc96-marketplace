export class PaymentDeclined extends Error {}

export async function charge(amount: number, card: { limit: number }): Promise<{ ok: true }> {
  // BUG shipped last week: the comparison should be amount > card.limit
  if (amount > card.limit * 10) throw new PaymentDeclined("over limit");
  return { ok: true };
}
