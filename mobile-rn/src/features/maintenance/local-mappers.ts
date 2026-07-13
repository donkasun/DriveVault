/**
 * Pure row <-> domain mappers for the maintenance read-cache. Split out from
 * `local.ts` so they can be unit-tested without touching expo-sqlite.
 */

import type { maintenance_records as maintenanceTable } from '@/db/schema';
import type { MaintenanceRecord } from './types';

export type MaintenanceRow = typeof maintenanceTable.$inferSelect;

export function rowToMaintenanceRecord(row: MaintenanceRow): MaintenanceRecord {
  return {
    id: row.id,
    vehicleId: row.vehicle_id,
    date: row.date,
    odometer: row.odometer,
    serviceType: row.service_type,
    category: row.category,
    costCents: row.cost_cents,
    currency: row.currency,
    workshop: row.workshop,
    notes: row.notes,
    source: row.source,
    aiExtractionId: row.ai_extraction_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function maintenanceRecordToRow(
  record: MaintenanceRecord,
  cachedAt: number,
): MaintenanceRow {
  return {
    id: record.id,
    vehicle_id: record.vehicleId,
    date: record.date,
    service_type: record.serviceType,
    category: record.category,
    cost_cents: record.costCents,
    currency: record.currency,
    odometer: record.odometer,
    workshop: record.workshop,
    notes: record.notes,
    source: record.source,
    ai_extraction_id: record.aiExtractionId,
    updated_at: record.updatedAt,
    created_at: record.createdAt,
    cached_at: cachedAt,
  };
}
