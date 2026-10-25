import { getLocale } from "./registry";

export function formatMoney(amount: number): string {
  const { locale, currency } = getLocale();
  return new Intl.NumberFormat(locale, { style: "currency", currency }).format(amount);
}
