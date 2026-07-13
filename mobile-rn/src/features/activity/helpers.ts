/**
 * Pure helpers for the activity screen — filtering, month grouping, labels.
 * Parity with Flutter `mobile/lib/features/activity/domain/activity_entry.dart`.
 * No providers, no API calls; safe to unit test directly.
 */

import type { ActivityEntry, ActivityKind } from './types';

export function filterActivityByKind(
  entries: ActivityEntry[],
  kind: ActivityKind | null,
): ActivityEntry[] {
  if (kind == null) return entries;
  return entries.filter((e) => e.type === kind);
}

export function filterActivityByVehicle(
  entries: ActivityEntry[],
  vehicleId: string | null,
): ActivityEntry[] {
  if (vehicleId == null) return entries;
  return entries.filter((e) => e.vehicleId === vehicleId);
}

export type ActivityMonthGroup = {
  /** First-of-month `Date`, for formatting (e.g. "July 2026"). */
  month: Date;
  entries: ActivityEntry[];
  subtotalCents: number;
};

/**
 * Groups entries by calendar month (newest month first), summing each
 * group's `amountCents` (nulls treated as 0). Parity with Dart's
 * `groupActivityByMonth`.
 */
export function groupActivityByMonth(entries: ActivityEntry[]): ActivityMonthGroup[] {
  const byMonth = new Map<string, ActivityEntry[]>();

  for (const entry of entries) {
    const parts = entry.date.split('-');
    if (parts.length < 2) continue;
    const key = `${parts[0]}-${parts[1]}`;
    const group = byMonth.get(key);
    if (group) group.push(entry);
    else byMonth.set(key, [entry]);
  }

  const keys = [...byMonth.keys()].sort((a, b) => (a < b ? 1 : a > b ? -1 : 0));

  return keys.map((key) => {
    const group = byMonth.get(key)!;
    const subtotalCents = group.reduce((sum, e) => sum + (e.amountCents ?? 0), 0);
    const [year, month] = key.split('-').map(Number);
    return { month: new Date(year!, month! - 1, 1), entries: group, subtotalCents };
  });
}

const ISO_DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})/;

/** "Today" / "Yesterday" / "d MMM" relative label for an ISO date string. */
export function activityDateLabel(dateStr: string, now: Date = new Date()): string {
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

/** Human label for a document's `docType` — parity with Dart's `_docTypeLabel`. */
export function docTypeLabel(docType: string): string {
  switch (docType) {
    case 'insurance':
      return 'Insurance';
    case 'registration':
      return 'Registration';
    case 'service_record':
      return 'Service record';
    case 'warranty':
      return 'Warranty';
    case 'receipt':
      return 'Receipt';
    default:
      return docType.replaceAll('_', ' ');
  }
}

/** Title shown on an activity tile — parity with Dart's `_title` getter. */
export function activityTitle(entry: ActivityEntry): string {
  switch (entry.type) {
    case 'fuel':
      return 'Fuel';
    case 'maintenance':
      return entry.label.trim() ? entry.label : 'Service';
    case 'document':
      return entry.title ?? entry.label;
  }
}

/** Sub-label shown on an activity tile — parity with Dart's `_subLabel` getter. */
export function activitySubLabel(entry: ActivityEntry, now: Date = new Date()): string {
  const dateLine = activityDateLabel(entry.date, now);
  switch (entry.type) {
    case 'fuel':
      return `${dateLine} · ${(entry.liters ?? 0).toFixed(1)} L · ${
        entry.isFullTank ? 'Full' : 'Partial'
      }`;
    case 'maintenance':
      return dateLine;
    case 'document':
      return `${dateLine} · ${docTypeLabel(entry.docType ?? '')}`;
  }
}
