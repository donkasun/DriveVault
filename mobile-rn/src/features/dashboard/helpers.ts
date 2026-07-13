/**
 * Pure helpers for the dashboard screen — status derivation, date labels.
 * No providers, no API calls; safe to unit test directly.
 */

import type { RenewalStatus, UpcomingRenewal } from './types';

/** Renewals that need surfacing in the "Needs attention" card: `soon` or `overdue`. */
export function attentionRenewals(renewals: UpcomingRenewal[]): UpcomingRenewal[] {
  return renewals.filter(
    (r): r is UpcomingRenewal & { status: RenewalStatus } =>
      r.status === 'overdue' || r.status === 'soon',
  );
}

/** Good morning / afternoon / Welcome back greeting keyed off the local hour. */
export function greetingFor(hour: number): string {
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Welcome back,';
}

/** "JD" / "J" / "?" initials from a display name — parity with Dart's `_initials`. */
export function initialsFor(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return '?';
  const parts = trimmed.split(/\s+/);
  if (parts.length === 1) return parts[0]![0]!.toUpperCase();
  return `${parts[0]![0]}${parts[1]![0]}`.toUpperCase();
}

const ISO_DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})/;

/** "Today" / "Yesterday" / "d MMM" relative label for an ISO date string. */
export function friendlyDate(dateStr: string, now: Date = new Date()): string {
  // Parse the "YYYY-MM-DD" components directly (rather than `new Date(dateStr)`)
  // so the calendar day isn't shifted by a UTC→local conversion.
  const match = ISO_DATE_ONLY.exec(dateStr);
  if (!match) return dateStr;
  const [, y, m, d] = match;
  const day = new Date(Number(y), Number(m) - 1, Number(d));
  if (Number.isNaN(day.getTime())) return dateStr;

  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diffDays = Math.round((today.getTime() - day.getTime()) / 86_400_000);

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';

  const MONTHS = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return `${day.getDate()} ${MONTHS[day.getMonth()]}`;
}
