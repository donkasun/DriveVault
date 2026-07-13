/** Parity with Flutter `mobile/lib/shared/constants/currencies.dart`. */

export type CurrencyInfo = {
  code: string;
  symbol: string;
  name: string;
};

/** Profile picker currencies (Doc 3 — 3-letter ISO codes). */
export const profileCurrencies: readonly CurrencyInfo[] = [
  { code: 'USD', symbol: '$', name: 'US Dollar' },
  { code: 'EUR', symbol: '€', name: 'Euro' },
  { code: 'GBP', symbol: '£', name: 'British Pound' },
  { code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee' },
  { code: 'INR', symbol: '₹', name: 'Indian Rupee' },
  { code: 'AUD', symbol: 'A$', name: 'Australian Dollar' },
  { code: 'CAD', symbol: 'C$', name: 'Canadian Dollar' },
  { code: 'JPY', symbol: '¥', name: 'Japanese Yen' },
] as const;

export const profileCurrencyCodes: readonly string[] = profileCurrencies.map((c) => c.code);

export function currencyInfoFor(code: string): CurrencyInfo | undefined {
  return profileCurrencies.find((c) => c.code === code);
}

/** Single fallback/seam currency while multi-currency is deferred. */
export const FALLBACK_CURRENCY = 'LKR';
