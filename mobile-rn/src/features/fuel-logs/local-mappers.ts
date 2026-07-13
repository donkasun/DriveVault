/**
 * Pure row <-> domain mappers for the fuel-logs read-cache. Split out from
 * `local.ts` so they can be unit-tested without touching expo-sqlite.
 */

import type { fuel_logs as fuelLogsTable } from '@/db/schema';
import type { FuelLog } from './types';

export type FuelLogRow = typeof fuelLogsTable.$inferSelect;

export function rowToFuelLog(row: FuelLogRow): FuelLog {
  return {
    id: row.id,
    vehicleId: row.vehicle_id,
    date: row.date,
    liters: row.liters,
    priceCents: row.price_cents,
    currency: row.currency,
    odometer: row.odometer,
    isFullTank: row.is_full_tank,
    notes: row.notes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function fuelLogToRow(fuelLog: FuelLog, cachedAt: number): FuelLogRow {
  return {
    id: fuelLog.id,
    vehicle_id: fuelLog.vehicleId,
    date: fuelLog.date,
    liters: fuelLog.liters,
    price_cents: fuelLog.priceCents,
    currency: fuelLog.currency,
    odometer: fuelLog.odometer,
    is_full_tank: fuelLog.isFullTank,
    notes: fuelLog.notes,
    created_at: fuelLog.createdAt,
    updated_at: fuelLog.updatedAt,
    cached_at: cachedAt,
  };
}
