import 'server-only';

import { desc, eq, inArray } from 'drizzle-orm';

import { db } from '@/server/db/client';
import {
  documents,
  fuelLogs,
  maintenanceRecords,
  vehicles,
} from '@/server/db/schema';
import { LOCKED_CURRENCY } from '@/server/lib/constants';
import type { ActivityItemRead } from '@/server/schemas/activity';
import { vehicleLabel } from '@/server/services/vehicle-label';

/**
 * Richer activity feed — port of activity_service.get_activity.
 *
 * DOC/CODE DRIFT: Doc 3 has no `/activity` section. Python is sole source of
 * truth. Shape is richer than dashboard recentActivity (id, currency,
 * type-specific fields). Does NOT include driving credentials.
 *
 * Fetch strategy matches Python: up to `limit` fuel + `limit` maintenance
 * (newest first each), all documents, then merge/sort/slice to `limit`.
 */
export async function getActivity(
  userId: string,
  limit: number = 50,
): Promise<ActivityItemRead[]> {
  const userVehicles = await db
    .select()
    .from(vehicles)
    .where(eq(vehicles.userId, userId));

  if (userVehicles.length === 0) return [];

  const vehicleIds = userVehicles.map((v) => v.id);
  const labelMap = new Map(
    userVehicles.map((v) => [v.id, vehicleLabel(v)]),
  );

  const [fuelRows, maintRows, docRows] = await Promise.all([
    db
      .select()
      .from(fuelLogs)
      .where(inArray(fuelLogs.vehicleId, vehicleIds))
      .orderBy(desc(fuelLogs.date))
      .limit(limit),
    db
      .select()
      .from(maintenanceRecords)
      .where(inArray(maintenanceRecords.vehicleId, vehicleIds))
      .orderBy(desc(maintenanceRecords.date))
      .limit(limit),
    db.select().from(documents).where(inArray(documents.vehicleId, vehicleIds)),
  ]);

  const items: ActivityItemRead[] = [];

  for (const log of fuelRows) {
    items.push({
      type: 'fuel',
      id: log.id,
      vehicleId: log.vehicleId,
      vehicleLabel: labelMap.get(log.vehicleId) ?? log.vehicleId,
      date: log.date,
      currency: log.currency.trim(),
      amountCents: log.priceCents,
      label: 'Fuel',
      createdAt: log.createdAt.toISOString(),
      liters: Number(log.liters),
      isFullTank: log.isFullTank,
      odometer: log.odometer,
      notes: log.notes,
    });
  }

  for (const record of maintRows) {
    items.push({
      type: 'maintenance',
      id: record.id,
      vehicleId: record.vehicleId,
      vehicleLabel: labelMap.get(record.vehicleId) ?? record.vehicleId,
      date: record.date,
      currency: (record.currency ?? LOCKED_CURRENCY).trim(),
      amountCents: record.costCents,
      label: record.serviceType,
      createdAt: record.createdAt.toISOString(),
      odometer: record.odometer,
      notes: record.notes,
      category: record.category,
      workshop: record.workshop,
      source: record.source,
    });
  }

  for (const doc of docRows) {
    const docDate =
      doc.issueDate ?? doc.createdAt.toISOString().slice(0, 10);
    items.push({
      type: 'document',
      id: doc.id,
      vehicleId: doc.vehicleId,
      vehicleLabel: labelMap.get(doc.vehicleId) ?? doc.vehicleId,
      date: docDate,
      amountCents: null,
      label: doc.title,
      currency: LOCKED_CURRENCY,
      createdAt: doc.createdAt.toISOString(),
      title: doc.title,
      docType: doc.docType,
      storageUrl: doc.storageUrl,
      storagePublicId: doc.storagePublicId,
      mimeType: doc.mimeType,
      fileSizeBytes: doc.fileSizeBytes,
      issueDate: doc.issueDate,
      expiryDate: doc.expiryDate,
    });
  }

  items.sort((a, b) => b.date.localeCompare(a.date));
  return items.slice(0, limit);
}
