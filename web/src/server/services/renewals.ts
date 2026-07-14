/**
 * Shared renewal status helpers — reused by dashboard and vehicle docsStatus.
 * Port of backend/app/services/renewals.py.
 */

// Both branches must read the same calendar. Reading local components here
// (getFullYear/getMonth/getDate) while parsing strings as UTC shifted every
// result by a day whenever the host's local date differed from its UTC date.
function toUtcDateOnly(value: Date | string): Date {
  if (typeof value === 'string') {
    const [y, m, d] = value.split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, d));
  }
  return new Date(
    Date.UTC(value.getUTCFullYear(), value.getUTCMonth(), value.getUTCDate()),
  );
}

/** Return days until expiry (negative if already overdue). */
export function daysUntil(expiryDate: Date | string, today: Date | string): number {
  const expiry = toUtcDateOnly(expiryDate).getTime();
  const now = toUtcDateOnly(today).getTime();
  return Math.round((expiry - now) / (24 * 60 * 60 * 1000));
}

/** Return 'overdue', 'soon' (0–30 days), or 'ok' (>30 days). */
export function renewalStatus(
  expiryDate: Date | string,
  today: Date | string,
): 'overdue' | 'soon' | 'ok' {
  const remaining = daysUntil(expiryDate, today);
  if (remaining < 0) return 'overdue';
  if (remaining <= 30) return 'soon';
  return 'ok';
}
