/**
 * Vehicle domain types — Doc 2 schema / Doc 3 contract.
 * Parity with Flutter `mobile/lib/features/vehicles/domain/vehicle.dart`.
 *
 * Money is integer cents (`*_cents`); odometer is integer kilometres (CLAUDE.md).
 */

import { FALLBACK_CURRENCY } from '@/lib/currencies';

/** Derived server-side from the vehicle's documents. */
export type DocsStatus = {
  state: 'valid' | 'needs_action' | 'none';
  needsActionCount: number;
};

/** Sentinel used when the backend omits `docsStatus` entirely. */
export const DOCS_STATUS_NONE: DocsStatus = { state: 'none', needsActionCount: 0 };

export type Vehicle = {
  id: string;
  make: string;
  model: string;
  year: number | null;
  registrationNumber: string | null;
  vin: string | null;
  purchaseDate: string | null;
  purchasePriceCents: number | null;
  currency: string;
  /** Integer kilometres. */
  currentMileage: number | null;
  vehicleType: string | null;
  fuelType: string | null;
  /** Per-vehicle override; null inherits the user's account default. */
  distanceUnit: 'km' | 'mi' | null;
  photoUrl: string | null;
  photoPublicId: string | null;
  createdAt: string;
  updatedAt: string;
  docsStatus: DocsStatus;
};

/** Tolerates a missing/partial `docsStatus`, exactly like Flutter's fromJson. */
export function normalizeVehicle(raw: Vehicle): Vehicle {
  return {
    ...raw,
    currency: raw.currency ?? FALLBACK_CURRENCY,
    docsStatus: raw.docsStatus
      ? {
          state: raw.docsStatus.state ?? 'none',
          needsActionCount: raw.docsStatus.needsActionCount ?? 0,
        }
      : DOCS_STATUS_NONE,
  };
}

/** "2015 Toyota Hilux" — year is omitted when absent. */
export function vehicleDisplayName(vehicle: Vehicle): string {
  return [vehicle.year, vehicle.make, vehicle.model].filter(Boolean).join(' ').trim();
}

export type CreateVehiclePayload = {
  make: string;
  model: string;
  year?: number | null;
  registrationNumber?: string | null;
  vin?: string | null;
  purchaseDate?: string | null;
  purchasePriceCents?: number | null;
  currency?: string;
  currentMileage?: number | null;
  vehicleType?: string | null;
  fuelType?: string | null;
  distanceUnit?: 'km' | 'mi' | null;
  photoUrl?: string | null;
  photoPublicId?: string | null;
};

export type UpdateVehiclePayload = Partial<CreateVehiclePayload>;
