/**
 * Local SQLite read-cache for vehicles (best-practices.md §6).
 *
 * This is NOT the write path — see CLAUDE.md / task brief. `repository.ts`
 * still talks to the API for every write; these helpers only mirror the
 * server-confirmed result into the on-device cache so a cold/offline launch
 * can show something instantly. All raw `db` access for this feature is
 * confined to this file.
 */

import { eq } from 'drizzle-orm';

import { db } from '@/db/client';
import { vehicles as vehiclesTable } from '@/db/schema';
import { rowToVehicle, vehicleToRow } from './local-mappers';
import type { Vehicle } from './types';

export async function getCachedVehicles(): Promise<Vehicle[]> {
  const rows = await db.select().from(vehiclesTable).all();
  return rows.map(rowToVehicle);
}

export async function getCachedVehicle(id: string): Promise<Vehicle | null> {
  const rows = await db.select().from(vehiclesTable).where(eq(vehiclesTable.id, id)).all();
  return rows[0] ? rowToVehicle(rows[0]) : null;
}

/** Replaces the whole cached list with the given (server-confirmed) rows. */
export async function upsertVehicles(vehicles: Vehicle[]): Promise<void> {
  if (vehicles.length === 0) return;
  const cachedAt = Date.now();
  await db.transaction(async (tx) => {
    for (const vehicle of vehicles) {
      await tx
        .insert(vehiclesTable)
        .values(vehicleToRow(vehicle, cachedAt))
        .onConflictDoUpdate({
          target: vehiclesTable.id,
          set: vehicleToRow(vehicle, cachedAt),
        });
    }
  });
}

export async function upsertVehicle(vehicle: Vehicle): Promise<void> {
  await upsertVehicles([vehicle]);
}

export async function deleteCachedVehicle(id: string): Promise<void> {
  await db.delete(vehiclesTable).where(eq(vehiclesTable.id, id));
}

export async function clearVehicles(): Promise<void> {
  await db.delete(vehiclesTable);
}
