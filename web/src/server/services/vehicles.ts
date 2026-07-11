import 'server-only';

import { and, desc, eq } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { vehicles } from '@/server/db/schema';
import { LOCKED_CURRENCY } from '@/server/lib/constants';
import { AppError } from '@/server/lib/errors';
import type {
  CreateVehicle,
  UpdateVehicle,
  VehicleResponse,
} from '@/server/schemas/vehicles';

import { attachDocsStatus } from './docs-status';

export type Vehicle = typeof vehicles.$inferSelect;

/**
 * Ownership-checked fetch returning the ORM vehicle row.
 * Shared building block for write paths and Phase 3b fuel-log services.
 * Throws AppError 404 "Vehicle not found" when missing or not owned.
 */
export async function getVehicleForUser(
  userId: string,
  vehicleId: string,
): Promise<Vehicle> {
  const [vehicle] = await db
    .select()
    .from(vehicles)
    .where(and(eq(vehicles.id, vehicleId), eq(vehicles.userId, userId)))
    .limit(1);

  if (!vehicle) {
    throw new AppError(404, 'Vehicle not found');
  }
  return vehicle;
}

/** API read: owned vehicle serialized with docsStatus. */
export async function getVehicleResponseForUser(
  userId: string,
  vehicleId: string,
): Promise<VehicleResponse> {
  const vehicle = await getVehicleForUser(userId, vehicleId);
  const [response] = await attachDocsStatus([vehicle]);
  return response;
}

/** List caller's vehicles, newest first, with docsStatus. */
export async function listVehicles(userId: string): Promise<VehicleResponse[]> {
  const rows = await db
    .select()
    .from(vehicles)
    .where(eq(vehicles.userId, userId))
    .orderBy(desc(vehicles.createdAt));
  return attachDocsStatus(rows);
}

/** Create a vehicle; currency is always forced to LOCKED_CURRENCY. */
export async function createVehicle(
  userId: string,
  payload: CreateVehicle,
): Promise<VehicleResponse> {
  const [vehicle] = await db
    .insert(vehicles)
    .values({
      userId,
      make: payload.make,
      model: payload.model,
      year: payload.year ?? null,
      registrationNumber: payload.registrationNumber ?? null,
      vin: payload.vin ?? null,
      purchaseDate: payload.purchaseDate ?? null,
      purchasePriceCents: payload.purchasePriceCents ?? null,
      currency: LOCKED_CURRENCY,
      currentMileage: payload.currentMileage ?? null,
      vehicleType: payload.vehicleType ?? null,
      fuelType: payload.fuelType ?? null,
      distanceUnit: payload.distanceUnit ?? null,
      photoUrl: payload.photoUrl ?? null,
      photoPublicId: payload.photoPublicId ?? null,
    })
    .returning();

  const [response] = await attachDocsStatus([vehicle]);
  return response;
}

/**
 * Partial update. When `currency` is present in the patch it is forced to
 * LOCKED_CURRENCY — deliberate deviation from Python `update_vehicle`, which
 * leaves currency untouched on PATCH. Matches the LKR invariant used by /me.
 */
export async function updateVehicle(
  userId: string,
  vehicleId: string,
  payload: UpdateVehicle,
): Promise<VehicleResponse> {
  const existing = await getVehicleForUser(userId, vehicleId);

  const updates: Partial<typeof vehicles.$inferInsert> = {
    updatedAt: new Date(),
  };

  if (payload.make !== undefined) updates.make = payload.make;
  if (payload.model !== undefined) updates.model = payload.model;
  if (payload.year !== undefined) updates.year = payload.year;
  if (payload.registrationNumber !== undefined) {
    updates.registrationNumber = payload.registrationNumber;
  }
  if (payload.vin !== undefined) updates.vin = payload.vin;
  if (payload.purchaseDate !== undefined) updates.purchaseDate = payload.purchaseDate;
  if (payload.purchasePriceCents !== undefined) {
    updates.purchasePriceCents = payload.purchasePriceCents;
  }
  if (payload.currentMileage !== undefined) updates.currentMileage = payload.currentMileage;
  if (payload.vehicleType !== undefined) updates.vehicleType = payload.vehicleType;
  if (payload.fuelType !== undefined) updates.fuelType = payload.fuelType;
  if (payload.distanceUnit !== undefined) updates.distanceUnit = payload.distanceUnit;
  if (payload.photoUrl !== undefined) updates.photoUrl = payload.photoUrl;
  if (payload.photoPublicId !== undefined) updates.photoPublicId = payload.photoPublicId;
  // Deliberate vs Python: coerce currency to LOCKED_CURRENCY on PATCH for LKR invariant.
  if ('currency' in payload && payload.currency !== undefined) {
    updates.currency = LOCKED_CURRENCY;
  }

  const [updated] = await db
    .update(vehicles)
    .set(updates)
    .where(eq(vehicles.id, existing.id))
    .returning();

  const [response] = await attachDocsStatus([updated]);
  return response;
}

/** Delete owned vehicle (DB cascades nested fuel_logs / documents / …). */
export async function deleteVehicle(userId: string, vehicleId: string): Promise<void> {
  const existing = await getVehicleForUser(userId, vehicleId);
  await db.delete(vehicles).where(eq(vehicles.id, existing.id));
}
