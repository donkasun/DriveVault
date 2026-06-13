class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

/// Profile picker currencies (Doc 3 — 3-letter ISO codes).
const profileCurrencies = [
  CurrencyInfo(code: 'USD', symbol: r'$', name: 'US Dollar'),
  CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyInfo(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
  CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  CurrencyInfo(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
  CurrencyInfo(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar'),
  CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
];

const profileCurrencyCodes = [
  'USD',
  'EUR',
  'GBP',
  'LKR',
  'INR',
  'AUD',
  'CAD',
  'JPY',
];

CurrencyInfo? currencyInfoFor(String code) {
  for (final currency in profileCurrencies) {
    if (currency.code == code) return currency;
  }
  return null;
}

/// Single fallback/seam currency while multi-currency is deferred.
/// Re-enable multi-currency: stop hardcoding this and read the real preference.
const kFallbackCurrency = 'LKR';
