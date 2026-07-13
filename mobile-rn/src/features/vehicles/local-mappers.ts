/**
 * Pure row <-> domain mappers for the vehicles read-cache. Split out from
 * `local.ts` so they can be unit-tested without touching expo-sqlite
 * (importing `db/client` opens a real native SQLite connection).
 */

import type { vehicles as vehiclesTable } from '@/db/schema';
import { DOCS_STATUS_NONE, type DocsStatus, type Vehicle } from './types';

export type VehicleRow = typeof vehiclesTable.$inferSelect;

export function parseDocsStatus(json: string): DocsStatus {
  try {
    const parsed = JSON.parse(json) as Partial<DocsStatus>;
    return {
      state: parsed.state ?? 'none',
      needsActionCount: parsed.needsActionCount ?? 0,
    };
  } catch {
    return DOCS_STATUS_NONE;
  }
}

export function rowToVehicle(row: VehicleRow): Vehicle {
  return {
    id: row.id,
    make: row.make,
    model: row.model,
    year: row.year,
    registrationNumber: row.registration_number,
    vin: row.vin,
    purchaseDate: row.purchase_date,
    purchasePriceCents: row.purchase_price_cents,
    currency: row.currency,
    currentMileage: row.current_mileage,
    vehicleType: row.vehicle_type,
    fuelType: row.fuel_type,
    distanceUnit: row.distance_unit as 'km' | 'mi' | null,
    photoUrl: row.photo_url,
    photoPublicId: row.photo_public_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    docsStatus: parseDocsStatus(row.docs_status_json),
  };
}

export function vehicleToRow(vehicle: Vehicle, cachedAt: number): VehicleRow {
  return {
    id: vehicle.id,
    make: vehicle.make,
    model: vehicle.model,
    year: vehicle.year,
    registration_number: vehicle.registrationNumber,
    vin: vehicle.vin,
    purchase_date: vehicle.purchaseDate,
    purchase_price_cents: vehicle.purchasePriceCents,
    currency: vehicle.currency,
    current_mileage: vehicle.currentMileage,
    vehicle_type: vehicle.vehicleType,
    fuel_type: vehicle.fuelType,
    distance_unit: vehicle.distanceUnit,
    photo_url: vehicle.photoUrl,
    photo_public_id: vehicle.photoPublicId,
    docs_status_json: JSON.stringify(vehicle.docsStatus),
    created_at: vehicle.createdAt,
    updated_at: vehicle.updatedAt,
    cached_at: cachedAt,
  };
}
