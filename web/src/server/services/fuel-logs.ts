import 'server-only';

import { and, desc, eq, gte, lte, max } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { fuelLogs, vehicles } from '@/server/db/schema';
import { LOCKED_CURRENCY } from '@/server/lib/constants';
import { AppError } from '@/server/lib/errors';
import type {
  CreateFuelLog,
  FuelLogResponse,
  UpdateFuelLog,
} from '@/server/schemas/fuel-logs';
import { getVehicleForUser } from '@/server/services/vehicles';

export type FuelLog = typeof fuelLogs.$inferSelect;

function toFuelLogResponse(row: FuelLog): FuelLogResponse {
  return {
    id: row.id,
    vehicleId: row.vehicleId,
    date: row.date,
    liters: Number(row.liters),
    priceCents: row.priceCents,
    // pg `char(3)` can pad with spaces — trim so the wire value is exactly "LKR".
    currency: row.currency.trim(),
    odometer: row.odometer,
    isFullTank: row.isFullTank,
    notes: row.notes,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

/** Set vehicle.currentMileage to MAX(odometer) of its fuel logs, or null if empty. */
async function syncCurrentMileage(vehicleId: string): Promise<void> {
  const [result] = await db
    .select({ maxOdometer: max(fuelLogs.odometer) })
    .from(fuelLogs)
    .where(eq(fuelLogs.vehicleId, vehicleId));

  await db
    .update(vehicles)
    .set({
      currentMileage: result?.maxOdometer ?? null,
      updatedAt: new Date(),
    })
    .where(eq(vehicles.id, vehicleId));
}

/** List fuel logs for an owned vehicle, newest first. Optional from/to date filters. */
export async function listFuelLogs(
  userId: string,
  vehicleId: string,
  fromDate?: string | null,
  toDate?: string | null,
): Promise<FuelLogResponse[]> {
  await getVehicleForUser(userId, vehicleId);

  const conditions = [eq(fuelLogs.vehicleId, vehicleId)];
  if (fromDate) conditions.push(gte(fuelLogs.date, fromDate));
  if (toDate) conditions.push(lte(fuelLogs.date, toDate));

  const rows = await db
    .select()
    .from(fuelLogs)
    .where(and(...conditions))
    .orderBy(desc(fuelLogs.date), desc(fuelLogs.createdAt));

  return rows.map(toFuelLogResponse);
}

/**
 * Create a fuel log. Odometer must be strictly greater than the existing max.
 * Currency is always forced to LOCKED_CURRENCY. Syncs vehicle.currentMileage.
 */
export async function createFuelLog(
  userId: string,
  vehicleId: string,
  payload: CreateFuelLog,
): Promise<FuelLogResponse> {
  await getVehicleForUser(userId, vehicleId);

  const [maxRow] = await db
    .select({ maxOdometer: max(fuelLogs.odometer) })
    .from(fuelLogs)
    .where(eq(fuelLogs.vehicleId, vehicleId));

  const existingMax = maxRow?.maxOdometer ?? null;
  if (existingMax !== null && payload.odometer <= existingMax) {
    throw new AppError(
      400,
      `Odometer must be greater than the latest reading (${existingMax} km)`,
    );
  }

  const values: typeof fuelLogs.$inferInsert = {
    vehicleId,
    date: payload.date,
    liters: String(payload.liters),
    priceCents: payload.priceCents,
    currency: LOCKED_CURRENCY,
    odometer: payload.odometer,
    isFullTank: payload.isFullTank,
    notes: payload.notes ?? null,
  };
  if (payload.id !== undefined) {
    values.id = payload.id;
  }

  const [row] = await db.insert(fuelLogs).values(values).returning();
  await syncCurrentMileage(vehicleId);
  return toFuelLogResponse(row);
}

/** Ownership-checked fetch via join on vehicles.user_id. 404 if missing/not owned. */
export async function getFuelLogForUser(
  userId: string,
  fuelLogId: string,
): Promise<FuelLog> {
  const [row] = await db
    .select({ fuelLog: fuelLogs })
    .from(fuelLogs)
    .innerJoin(vehicles, eq(fuelLogs.vehicleId, vehicles.id))
    .where(and(eq(fuelLogs.id, fuelLogId), eq(vehicles.userId, userId)))
    .limit(1);

  if (!row) {
    throw new AppError(404, 'Fuel log not found');
  }
  return row.fuelLog;
}

/**
 * Partial update. Byte-for-byte Python parity:
 * - NO odometer re-validation
 * - NO mileage re-sync
 * - NO currency re-lock on PATCH
 */
export async function updateFuelLog(
  userId: string,
  fuelLogId: string,
  payload: UpdateFuelLog,
): Promise<FuelLogResponse> {
  const existing = await getFuelLogForUser(userId, fuelLogId);

  const updates: Partial<typeof fuelLogs.$inferInsert> = {
    updatedAt: new Date(),
  };

  if (payload.date !== undefined && payload.date !== null) updates.date = payload.date;
  if (payload.liters !== undefined && payload.liters !== null) {
    updates.liters = String(payload.liters);
  }
  if (payload.priceCents !== undefined && payload.priceCents !== null) {
    updates.priceCents = payload.priceCents;
  }
  // Deliberate: do NOT coerce currency to LOCKED_CURRENCY (matches Python update_fuel_log).
  if (payload.currency !== undefined && payload.currency !== null) {
    updates.currency = payload.currency;
  }
  if (payload.odometer !== undefined && payload.odometer !== null) {
    updates.odometer = payload.odometer;
  }
  if (payload.isFullTank !== undefined) updates.isFullTank = payload.isFullTank;
  if (payload.notes !== undefined) updates.notes = payload.notes;

  const [updated] = await db
    .update(fuelLogs)
    .set(updates)
    .where(eq(fuelLogs.id, existing.id))
    .returning();

  return toFuelLogResponse(updated);
}

/** Delete owned fuel log and resync vehicle.currentMileage. */
export async function deleteFuelLog(userId: string, fuelLogId: string): Promise<void> {
  const fuelLog = await getFuelLogForUser(userId, fuelLogId);
  // Ownership already verified via join; getVehicleForUser confirms vehicle still owned.
  await getVehicleForUser(userId, fuelLog.vehicleId);

  await db.delete(fuelLogs).where(eq(fuelLogs.id, fuelLog.id));
  await syncCurrentMileage(fuelLog.vehicleId);
}
