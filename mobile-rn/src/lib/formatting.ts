/** Parity with Flutter `mobile/lib/shared/utils/formatting.dart`. */

import { currencyInfoFor, FALLBACK_CURRENCY } from './currencies';
import { formatEconomy, type DistanceUnit } from './distance-unit';

const moneyFmt = new Intl.NumberFormat('en-US', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** Removes a trailing ".00" (or ",00") decimal-zero suffix. */
function stripDecimalZeros(s: string): string {
  return s.replace(/[.,]00$/, '');
}

/**
 * Inserts a space between a multi-LETTER currency symbol and the amount.
 * e.g. "Rs26,793.00" → "Rs 26,793.00". Single-glyph symbols ($, €, ₹) and
 * mixed ones (A$, C$) do not match and stay tight against the digits.
 */
function ensureSymbolSpacing(formatted: string): string {
  const match = /^(-?)([A-Za-z]{2,})(\d)/.exec(formatted);
  if (!match) return formatted;
  const sign = match[1] ?? '';
  const symbol = match[2];
  const rest = formatted.slice(sign.length + symbol.length);
  return `${sign}${symbol} ${rest}`;
}

/**
 * Format integer cents to a currency string using the given ISO currency code.
 *   formatCents(2679300, 'LKR') → "Rs 26,793"
 *   formatCents(412050, 'USD')  → "$4,120.50"
 *
 * When the amount has no fractional cents the decimal part is omitted — this
 * matches real-world LKR usage where prices are always whole rupees.
 *
 * Unknown currency codes fall back to using the code itself as the symbol,
 * which then picks up the multi-letter space: "XYZ 1,234.56".
 */
export function formatCents(cents: number, currency: string = FALLBACK_CURRENCY): string {
  const symbol = currencyInfoFor(currency)?.symbol ?? currency;
  const sign = cents < 0 ? '-' : '';
  const body = moneyFmt.format(Math.abs(cents) / 100);

  const spaced = ensureSymbolSpacing(`${sign}${symbol}${body}`);
  return cents % 100 === 0 ? stripDecimalZeros(spaced) : spaced;
}

/**
 * Canonical economy formatter: converts backend L/100km to the user's unit.
 * Single source of truth — garage card and vehicle detail both call this so
 * they always show the same string for the same data.
 */
export function formatEconomyFromStats(
  lPer100km: number | null | undefined,
  unit: DistanceUnit,
): string {
  return formatEconomy(lPer100km, unit);
}

// NOTE: Flutter's `expiryColor()` (formatting.dart) is intentionally NOT ported —
// it has zero call sites in `mobile/lib` and returns raw Material colours that
// contradict the design tokens. Status colours come from StatusPill's PillTone
// scale instead. Do not "restore" it.
