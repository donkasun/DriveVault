import 'server-only';

import { and, inArray, isNotNull } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { documents, vehicles } from '@/server/db/schema';
import type { DocsStatus, VehicleResponse } from '@/server/schemas/vehicles';

import { renewalStatus } from './renewals';

type VehicleRow = typeof vehicles.$inferSelect;

type ExpiryDoc = {
  vehicleId: string;
  expiryDate: string;
};

/**
 * Pure docsStatus computation for one vehicle given its expiry-bearing docs.
 * Port of backend/app/services/vehicles.py::_compute_docs_status.
 */
export function computeDocsStatus(
  docs: ReadonlyArray<{ expiryDate: string | Date | null }>,
  today: Date | string = new Date(),
): DocsStatus {
  const expiryDocs = docs.filter((d) => d.expiryDate != null);
  if (expiryDocs.length === 0) {
    return { state: 'none', needsActionCount: 0 };
  }

  const needsActionCount = expiryDocs.filter((d) => {
    const status = renewalStatus(d.expiryDate!, today);
    return status === 'soon' || status === 'overdue';
  }).length;

  if (needsActionCount > 0) {
    return { state: 'needs_action', needsActionCount };
  }
  return { state: 'valid', needsActionCount: 0 };
}

function toVehicleResponse(row: VehicleRow, docsStatus: DocsStatus): VehicleResponse {
  return {
    id: row.id,
    make: row.make,
    model: row.model,
    year: row.year,
    registrationNumber: row.registrationNumber,
    vin: row.vin,
    purchaseDate: row.purchaseDate,
    purchasePriceCents: row.purchasePriceCents,
    // pg `char(3)` can pad with spaces — trim so the wire value is exactly "LKR".
    currency: row.currency.trim(),
    currentMileage: row.currentMileage,
    vehicleType: row.vehicleType,
    fuelType: row.fuelType,
    distanceUnit: (row.distanceUnit as 'km' | 'mi' | null) ?? null,
    photoUrl: row.photoUrl,
    photoPublicId: row.photoPublicId,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    docsStatus,
  };
}

/**
 * Attach docsStatus to vehicle rows using a single batched documents query
 * (no N+1). Port of backend/app/services/vehicles.py::_attach_docs_status.
 */
export async function attachDocsStatus(
  vehicleRows: VehicleRow[],
  today: Date | string = new Date(),
): Promise<VehicleResponse[]> {
  if (vehicleRows.length === 0) return [];

  const vehicleIds = vehicleRows.map((v) => v.id);

  const allDocs = await db
    .select({
      vehicleId: documents.vehicleId,
      expiryDate: documents.expiryDate,
    })
    .from(documents)
    .where(and(inArray(documents.vehicleId, vehicleIds), isNotNull(documents.expiryDate)));

  const docsByVehicle = new Map<string, ExpiryDoc[]>();
  for (const doc of allDocs) {
    if (doc.expiryDate == null) continue;
    const list = docsByVehicle.get(doc.vehicleId) ?? [];
    list.push({ vehicleId: doc.vehicleId, expiryDate: doc.expiryDate });
    docsByVehicle.set(doc.vehicleId, list);
  }

  return vehicleRows.map((vehicle) =>
    toVehicleResponse(
      vehicle,
      computeDocsStatus(docsByVehicle.get(vehicle.id) ?? [], today),
    ),
  );
}
