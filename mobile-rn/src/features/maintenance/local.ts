/**
 * Local SQLite read-cache for maintenance records (best-practices.md §6).
 *
 * NOT the write path — see CLAUDE.md / task brief. `repository.ts` still
 * talks to the API for every write; these helpers mirror the
 * server-confirmed result into the on-device cache.
 */

import { eq } from 'drizzle-orm';

import { db } from '@/db/client';
import { maintenance_records as maintenanceTable } from '@/db/schema';
import { maintenanceRecordToRow, rowToMaintenanceRecord } from './local-mappers';
import type { MaintenanceRecord } from './types';

export async function getCachedMaintenanceRecords(vehicleId: string): Promise<MaintenanceRecord[]> {
  const rows = await db
    .select()
    .from(maintenanceTable)
    .where(eq(maintenanceTable.vehicle_id, vehicleId))
    .all();
  return rows.map(rowToMaintenanceRecord);
}

export async function upsertMaintenanceRecords(records: MaintenanceRecord[]): Promise<void> {
  if (records.length === 0) return;
  const cachedAt = Date.now();
  await db.transaction(async (tx) => {
    for (const record of records) {
      await tx
        .insert(maintenanceTable)
        .values(maintenanceRecordToRow(record, cachedAt))
        .onConflictDoUpdate({
          target: maintenanceTable.id,
          set: maintenanceRecordToRow(record, cachedAt),
        });
    }
  });
}

export async function upsertMaintenanceRecord(record: MaintenanceRecord): Promise<void> {
  await upsertMaintenanceRecords([record]);
}

export async function deleteCachedMaintenanceRecord(id: string): Promise<void> {
  await db.delete(maintenanceTable).where(eq(maintenanceTable.id, id));
}

export async function clearMaintenanceRecordsForVehicle(vehicleId: string): Promise<void> {
  await db.delete(maintenanceTable).where(eq(maintenanceTable.vehicle_id, vehicleId));
}

export async function clearMaintenanceRecords(): Promise<void> {
  await db.delete(maintenanceTable);
}
