let current = { locale: "en-US", currency: "USD" };

export function setLocale(locale: string, currency: string): void {
  current = { locale, currency };
}

export function getLocale() {
  return current;
}
