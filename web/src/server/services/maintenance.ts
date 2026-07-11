import 'server-only';

import { and, desc, eq, gte, lte } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { maintenanceRecords, vehicles } from '@/server/db/schema';
import { LOCKED_CURRENCY } from '@/server/lib/constants';
import { AppError } from '@/server/lib/errors';
import type {
  CreateMaintenance,
  MaintenanceResponse,
  UpdateMaintenance,
} from '@/server/schemas/maintenance';
import { getVehicleForUser } from '@/server/services/vehicles';

export type MaintenanceRecord = typeof maintenanceRecords.$inferSelect;

function toMaintenanceResponse(row: MaintenanceRecord): MaintenanceResponse {
  return {
    id: row.id,
    vehicleId: row.vehicleId,
    date: row.date,
    odometer: row.odometer,
    serviceType: row.serviceType,
    category: row.category,
    costCents: row.costCents,
    // pg `char(3)` can pad with spaces — trim so the wire value is exactly "LKR".
    currency: row.currency.trim(),
    workshop: row.workshop,
    notes: row.notes,
    source: row.source,
    aiExtractionId: row.aiExtractionId,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

/**
 * List maintenance records for an owned vehicle, newest first.
 * Optional category / from / to filters (matches Python list_maintenance_records).
 */
export async function listMaintenanceRecords(
  userId: string,
  vehicleId: string,
  category?: string | null,
  fromDate?: string | null,
  toDate?: string | null,
): Promise<MaintenanceResponse[]> {
  await getVehicleForUser(userId, vehicleId);

  const conditions = [eq(maintenanceRecords.vehicleId, vehicleId)];
  if (category) conditions.push(eq(maintenanceRecords.category, category));
  if (fromDate) conditions.push(gte(maintenanceRecords.date, fromDate));
  if (toDate) conditions.push(lte(maintenanceRecords.date, toDate));

  const rows = await db
    .select()
    .from(maintenanceRecords)
    .where(and(...conditions))
    .orderBy(desc(maintenanceRecords.date), desc(maintenanceRecords.createdAt));

  return rows.map(toMaintenanceResponse);
}

/**
 * Create a maintenance record. Currency is always forced to LOCKED_CURRENCY.
 * source='manual', aiExtractionId=null (matches Python create_maintenance_record).
 */
export async function createMaintenanceRecord(
  userId: string,
  vehicleId: string,
  payload: CreateMaintenance,
): Promise<MaintenanceResponse> {
  await getVehicleForUser(userId, vehicleId);

  const values: typeof maintenanceRecords.$inferInsert = {
    vehicleId,
    date: payload.date,
    odometer: payload.odometer ?? null,
    serviceType: payload.serviceType,
    category: payload.category ?? null,
    costCents: payload.costCents,
    currency: LOCKED_CURRENCY,
    workshop: payload.workshop ?? null,
    notes: payload.notes ?? null,
    source: 'manual',
    aiExtractionId: null,
  };
  if (payload.id !== undefined) {
    values.id = payload.id;
  }

  const [row] = await db.insert(maintenanceRecords).values(values).returning();
  return toMaintenanceResponse(row);
}

/** Ownership-checked fetch via join on vehicles.user_id. 404 if missing/not owned. */
export async function getMaintenanceRecordForUser(
  userId: string,
  maintenanceId: string,
): Promise<MaintenanceRecord> {
  const [row] = await db
    .select({ record: maintenanceRecords })
    .from(maintenanceRecords)
    .innerJoin(vehicles, eq(maintenanceRecords.vehicleId, vehicles.id))
    .where(and(eq(maintenanceRecords.id, maintenanceId), eq(vehicles.userId, userId)))
    .limit(1);

  if (!row) {
    throw new AppError(404, 'Maintenance record not found');
  }
  return row.record;
}

/** API read: owned maintenance record serialized for the wire. */
export async function getMaintenanceRecordResponseForUser(
  userId: string,
  maintenanceId: string,
): Promise<MaintenanceResponse> {
  const record = await getMaintenanceRecordForUser(userId, maintenanceId);
  return toMaintenanceResponse(record);
}

/**
 * Partial update. Matches Python update_maintenance_record:
 * - NO currency re-lock on PATCH (same as updateFuelLog)
 */
export async function updateMaintenanceRecord(
  userId: string,
  maintenanceId: string,
  payload: UpdateMaintenance,
): Promise<MaintenanceResponse> {
  const existing = await getMaintenanceRecordForUser(userId, maintenanceId);

  const updates: Partial<typeof maintenanceRecords.$inferInsert> = {
    updatedAt: new Date(),
  };

  if (payload.date !== undefined && payload.date !== null) updates.date = payload.date;
  if (payload.odometer !== undefined) updates.odometer = payload.odometer;
  if (payload.serviceType !== undefined && payload.serviceType !== null) {
    updates.serviceType = payload.serviceType;
  }
  if (payload.category !== undefined) updates.category = payload.category;
  if (payload.costCents !== undefined) updates.costCents = payload.costCents;
  // Deliberate: do NOT coerce currency to LOCKED_CURRENCY (matches Python).
  if (payload.currency !== undefined && payload.currency !== null) {
    updates.currency = payload.currency;
  }
  if (payload.workshop !== undefined) updates.workshop = payload.workshop;
  if (payload.notes !== undefined) updates.notes = payload.notes;

  const [updated] = await db
    .update(maintenanceRecords)
    .set(updates)
    .where(eq(maintenanceRecords.id, existing.id))
    .returning();

  return toMaintenanceResponse(updated);
}

/** Delete owned maintenance record. */
export async function deleteMaintenanceRecord(
  userId: string,
  maintenanceId: string,
): Promise<void> {
  const record = await getMaintenanceRecordForUser(userId, maintenanceId);
  await db.delete(maintenanceRecords).where(eq(maintenanceRecords.id, record.id));
}
