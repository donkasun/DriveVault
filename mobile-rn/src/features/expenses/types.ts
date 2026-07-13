/**
 * Expenses domain types. Parity with Flutter
 * `mobile/lib/features/expenses/domain/expense.dart`.
 *
 * IMPORTANT: there is no `/expenses` backend endpoint. An `Expense` is a
 * client-side merge of a vehicle's fuel logs and maintenance records — see
 * `hooks.ts` for the fan-out that builds this list.
 */

import { FALLBACK_CURRENCY } from '@/lib/currencies';
import type { FuelLog } from '@/features/fuel-logs/types';
import type { MaintenanceRecord } from '@/features/maintenance/types';

export type ExpenseKind = 'fuel' | 'maintenance';

export type Expense = {
  id: string;
  vehicleId: string;
  kind: ExpenseKind;
  /** ISO date (YYYY-MM-DD). */
  date: string;
  /** Maintenance records with a null cost are normalised to 0. */
  costCents: number;
  currency: string;
  /** Present only when `kind === 'fuel'`. */
  fuelLog?: FuelLog;
  /** Present only when `kind === 'maintenance'`. */
  maintenanceRecord?: MaintenanceRecord;
};

export function expenseFromFuelLog(log: FuelLog): Expense {
  return {
    id: log.id,
    vehicleId: log.vehicleId,
    kind: 'fuel',
    date: log.date,
    costCents: log.priceCents,
    currency: log.currency,
    fuelLog: log,
  };
}

export function expenseFromMaintenance(record: MaintenanceRecord): Expense {
  return {
    id: record.id,
    vehicleId: record.vehicleId,
    kind: 'maintenance',
    date: record.date,
    costCents: record.costCents ?? 0,
    currency: record.currency ?? FALLBACK_CURRENCY,
    maintenanceRecord: record,
  };
}
