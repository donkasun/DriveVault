/**
 * Local SQLite read-cache for fuel logs (best-practices.md §6).
 *
 * NOT the write path — see CLAUDE.md / task brief. `repository.ts` still
 * talks to the API for every write; these helpers mirror the
 * server-confirmed result into the on-device cache.
 */

import { eq } from 'drizzle-orm';

import { db } from '@/db/client';
import { fuel_logs as fuelLogsTable } from '@/db/schema';
import { fuelLogToRow, rowToFuelLog } from './local-mappers';
import type { FuelLog } from './types';

export async function getCachedFuelLogs(vehicleId: string): Promise<FuelLog[]> {
  const rows = await db
    .select()
    .from(fuelLogsTable)
    .where(eq(fuelLogsTable.vehicle_id, vehicleId))
    .all();
  return rows.map(rowToFuelLog);
}

export async function upsertFuelLogs(fuelLogs: FuelLog[]): Promise<void> {
  if (fuelLogs.length === 0) return;
  const cachedAt = Date.now();
  await db.transaction(async (tx) => {
    for (const fuelLog of fuelLogs) {
      await tx
        .insert(fuelLogsTable)
        .values(fuelLogToRow(fuelLog, cachedAt))
        .onConflictDoUpdate({
          target: fuelLogsTable.id,
          set: fuelLogToRow(fuelLog, cachedAt),
        });
    }
  });
}

export async function upsertFuelLog(fuelLog: FuelLog): Promise<void> {
  await upsertFuelLogs([fuelLog]);
}

export async function deleteCachedFuelLog(id: string): Promise<void> {
  await db.delete(fuelLogsTable).where(eq(fuelLogsTable.id, id));
}

export async function clearFuelLogsForVehicle(vehicleId: string): Promise<void> {
  await db.delete(fuelLogsTable).where(eq(fuelLogsTable.vehicle_id, vehicleId));
}

export async function clearFuelLogs(): Promise<void> {
  await db.delete(fuelLogsTable);
}
