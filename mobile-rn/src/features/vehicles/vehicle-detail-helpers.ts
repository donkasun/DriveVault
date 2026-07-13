/**
 * Pure helpers extracted from the vehicle detail screen so they can be unit
 * tested without rendering. Parity with the logic embedded in Flutter's
 * `vehicle_detail_screen.dart` (`_StatsCard`, `_MaintenanceTile`, `_DocumentCard`,
 * `_DocumentsSection._sorted`).
 */

import type { Document } from '@/features/documents/types';
import { daysUntilExpiry } from '@/features/documents/types';
import type { MaintenanceRecord } from '@/features/maintenance/types';
import type { RenewalStatus } from '@/components/status-pill';

/**
 * Splits a formatted distance/economy string into its leading number and a
 * trailing unit suffix. `"78,855 km"` → `["78,855", "km"]`. `"—"` → `["—", null]`.
 * Mirrors Dart `_StatsCard.splitSuffix`.
 */
export function splitStatSuffix(value: string): [string, string | null] {
  if (value === '—') return ['—', null];
  const i = value.lastIndexOf(' ');
  return i === -1 ? [value, null] : [value.slice(0, i), value.slice(i + 1)];
}

/**
 * Splits a formatted money string into a leading currency-symbol prefix and
 * the trailing number. `"Rs 19,393"` → `["Rs", "19,393"]`. Mirrors Dart
 * `_StatsCard.splitPrefix`.
 */
export function splitStatPrefix(value: string): [string | null, string] {
  const i = value.indexOf(' ');
  return i === -1 ? [null, value] : [value.slice(0, i), value.slice(i + 1)];
}

/** Newest-first by an ISO/`YYYY-MM-DD` date string. Stable for equal dates. */
export function sortByDateDesc<T>(items: readonly T[], dateOf: (item: T) => string): T[] {
  return [...items].sort((a, b) => dateOf(b).localeCompare(dateOf(a)));
}

export type MaintenanceIconKey = 'repair' | 'upgrade' | 'inspection' | 'default';

/** Category → icon key. Mirrors Dart `_MaintenanceTile._iconStyle`. */
export function maintenanceIconKey(category: string | null): MaintenanceIconKey {
  switch (category?.toLowerCase()) {
    case 'repair':
      return 'repair';
    case 'upgrade':
      return 'upgrade';
    case 'inspection':
      return 'inspection';
    default:
      return 'default';
  }
}

/**
 * `"2026-05-20 • City Auto • 47800 km"` — date, optional workshop, optional
 * odometer, joined with " • ". Mirrors Dart `_MaintenanceTile._subtitle`.
 */
export function maintenanceSubtitle(record: Pick<MaintenanceRecord, 'date' | 'workshop' | 'odometer'>): string {
  const parts = [record.date];
  if (record.workshop && record.workshop.trim().length > 0) {
    parts.push(record.workshop.trim());
  }
  if (record.odometer != null) {
    parts.push(`${record.odometer} km`);
  }
  return parts.join(' • ');
}

export type DocumentIconKey = 'insurance' | 'revenue_license' | 'emission_test' | 'default';

/** docType → icon key. Mirrors Dart `_DocumentCard._iconStyle`. */
export function documentIconKey(docType: string): DocumentIconKey {
  switch (docType.toLowerCase()) {
    case 'insurance':
      return 'insurance';
    case 'revenue_license':
      return 'revenue_license';
    case 'emission_test':
      return 'emission_test';
    default:
      return 'default';
  }
}

/**
 * "Expires d MMM" / "No expiry date". Mirrors Dart `_DocumentCard._expirySubLabel`,
 * using a caller-supplied formatter so this module stays free of date-formatting deps.
 */
export function documentExpirySubLabel(
  expiryDate: string | null,
  formatDayMonth: (date: Date) => string,
): string {
  if (expiryDate == null) return 'No expiry date';
  const expiry = new Date(expiryDate);
  if (Number.isNaN(expiry.getTime())) return 'No expiry date';
  return `Expires ${formatDayMonth(expiry)}`;
}

/**
 * Renewal status for a document's expiry pill, or null when no pill should be
 * shown (no expiry date, or more than 30 days away). Mirrors Dart
 * `_DocumentCard._statusPill`.
 */
export function documentRenewalStatus(
  expiryDate: string | null,
  now: Date = new Date(),
): { status: RenewalStatus; daysRemaining: number } | null {
  const days = daysUntilExpiry(expiryDate, now);
  if (days == null) return null;
  if (days < 0) return { status: 'overdue', daysRemaining: Math.abs(days) };
  if (days <= 30) return { status: 'soon', daysRemaining: days };
  return null;
}

/**
 * "Today" / "Yesterday" / a formatted day-month string for older dates.
 * Mirrors Dart `fuel_record_card.dart`'s `_relativeDate`. `formatDayMonth` is
 * caller-supplied (e.g. `Intl.DateTimeFormat`) to keep this module dependency-free.
 */
export function relativeDateLabel(
  dateStr: string,
  formatDayMonth: (date: Date) => string,
  now: Date = new Date(),
): string {
  const date = new Date(dateStr);
  if (Number.isNaN(date.getTime())) return dateStr;

  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const msPerDay = 24 * 60 * 60 * 1000;
  const diff = Math.round((today.getTime() - d.getTime()) / msPerDay);

  if (diff === 0) return 'Today';
  if (diff === 1) return 'Yesterday';
  return formatDayMonth(date);
}

/**
 * Sort: overdue first, then soon (fewest days first), then ok, then no expiry
 * last. Mirrors Dart `_DocumentsSection._sorted`.
 */
export function sortDocumentsByExpiry(docs: readonly Document[], now: Date = new Date()): Document[] {
  return [...docs].sort((a, b) => {
    const da = daysUntilExpiry(a.expiryDate, now);
    const db = daysUntilExpiry(b.expiryDate, now);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da - db;
  });
}
