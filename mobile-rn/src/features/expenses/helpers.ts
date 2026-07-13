/**
 * Pure, side-effect-free helpers for the expenses screen — filtering,
 * grouping, and summary totals. Parity with Flutter
 * `mobile/lib/features/expenses/domain/expense_filters.dart`.
 *
 * No providers, no API calls — safe to unit test directly.
 */

import type { FuelLog } from '@/features/fuel-logs/types';
import type { MaintenanceRecord } from '@/features/maintenance/types';
import type { Vehicle } from '@/features/vehicles/types';
import { expenseFromFuelLog, expenseFromMaintenance, type Expense, type ExpenseKind } from './types';

// ---------------------------------------------------------------------------
// Fan-out merge
// ---------------------------------------------------------------------------

/**
 * Merges every vehicle's fuel logs + maintenance records into a single flat,
 * newest-first `Expense` list. Parity with Dart's `allExpensesProvider`
 * fan-out: a vehicle with no logs/records simply contributes nothing (no
 * special-casing needed — `fuelLogsByVehicle`/`maintenanceByVehicle` may omit
 * or empty-array a vehicle's id).
 */
export function mergeExpenses(
  vehicles: Vehicle[],
  fuelLogsByVehicle: Record<string, FuelLog[] | undefined>,
  maintenanceByVehicle: Record<string, MaintenanceRecord[] | undefined>,
): Expense[] {
  const all: Expense[] = [];
  for (const vehicle of vehicles) {
    const logs = fuelLogsByVehicle[vehicle.id] ?? [];
    const records = maintenanceByVehicle[vehicle.id] ?? [];
    for (const log of logs) all.push(expenseFromFuelLog(log));
    for (const record of records) all.push(expenseFromMaintenance(record));
  }
  return [...all].sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
}

const ISO_YEAR_MONTH = /^(\d{4})-(\d{2})/;

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/** Returns only expenses whose date falls within the current calendar month. */
export function filterToCurrentMonth(expenses: Expense[], now: Date = new Date()): Expense[] {
  const year = now.getFullYear();
  const month = now.getMonth() + 1; // 1-indexed, to match the ISO string
  return expenses.filter((e) => {
    const match = ISO_YEAR_MONTH.exec(e.date);
    if (!match) return false;
    return Number(match[1]) === year && Number(match[2]) === month;
  });
}

/** Returns only expenses matching `kind`. If `kind` is null, all are returned. */
export function filterByKind(expenses: Expense[], kind: ExpenseKind | null): Expense[] {
  if (kind == null) return expenses;
  return expenses.filter((e) => e.kind === kind);
}

/** Returns only expenses matching `vehicleId`. If null, all are returned. */
export function filterByVehicle(expenses: Expense[], vehicleId: string | null): Expense[] {
  if (vehicleId == null) return expenses;
  return expenses.filter((e) => e.vehicleId === vehicleId);
}

// ---------------------------------------------------------------------------
// Grouping
// ---------------------------------------------------------------------------

export type ExpenseMonthGroup = {
  /** First-of-month `Date`, for formatting (e.g. "July 2026"). */
  month: Date;
  expenses: Expense[];
  subtotalCents: number;
};

/**
 * Groups `expenses` by calendar month, newest month first. Within each month
 * expenses are sorted newest-date first. The running `subtotalCents` is
 * pre-computed for each group.
 */
export function groupExpensesByMonth(expenses: Expense[]): ExpenseMonthGroup[] {
  const buckets = new Map<string, Expense[]>();

  for (const expense of expenses) {
    const match = ISO_YEAR_MONTH.exec(expense.date);
    const key = match ? `${match[1]}-${match[2]}` : expense.date;
    const bucket = buckets.get(key);
    if (bucket) bucket.push(expense);
    else buckets.set(key, [expense]);
  }

  const groups: ExpenseMonthGroup[] = [...buckets.entries()].map(([key, bucketExpenses]) => {
    const [year, month] = key.split('-').map(Number);
    const sorted = [...bucketExpenses].sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
    const subtotalCents = sorted.reduce((sum, e) => sum + e.costCents, 0);
    return { month: new Date(year!, month! - 1, 1), expenses: sorted, subtotalCents };
  });

  groups.sort((a, b) => b.month.getTime() - a.month.getTime());
  return groups;
}

// ---------------------------------------------------------------------------
// Summary helpers
// ---------------------------------------------------------------------------

/** Total cents across all `expenses`. */
export function totalCents(expenses: Expense[]): number {
  return expenses.reduce((sum, e) => sum + e.costCents, 0);
}

/** Fuel-only cents. */
export function fuelCents(expenses: Expense[]): number {
  return expenses.filter((e) => e.kind === 'fuel').reduce((sum, e) => sum + e.costCents, 0);
}

/** Maintenance-only cents. */
export function maintenanceCents(expenses: Expense[]): number {
  return expenses.filter((e) => e.kind === 'maintenance').reduce((sum, e) => sum + e.costCents, 0);
}

// ---------------------------------------------------------------------------
// Tile label helpers
// ---------------------------------------------------------------------------

const ISO_DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})/;

/** "Today" / "Yesterday" / "d MMM" relative label for an ISO date string. */
export function expenseDateLabel(dateStr: string, now: Date = new Date()): string {
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

/** Category label shown on an expense tile — parity with Dart's `_categoryLabel`. */
export function expenseCategoryLabel(expense: Expense): string {
  if (expense.kind === 'fuel') return 'Fuel';
  const serviceType = expense.maintenanceRecord?.serviceType;
  return serviceType && serviceType.length > 0 ? serviceType : 'Maintenance';
}

/** Sub-label shown on an expense tile — parity with Dart's `_subLabel` getter. */
export function expenseSubLabel(expense: Expense, now: Date = new Date()): string {
  const dateLine = expenseDateLabel(expense.date, now);
  if (expense.kind === 'fuel' && expense.fuelLog) {
    const tank = expense.fuelLog.isFullTank ? 'Full' : 'Partial';
    return `${dateLine} · ${expense.fuelLog.liters.toFixed(1)} L · ${tank}`;
  }
  return dateLine;
}
