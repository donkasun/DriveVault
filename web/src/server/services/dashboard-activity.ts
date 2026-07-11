import 'server-only';

import { inArray } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { documents, fuelLogs, maintenanceRecords } from '@/server/db/schema';
import type { DashboardActivityItem } from '@/server/schemas/dashboard';
import { vehicleLabel, type VehicleLabelSource } from '@/server/services/vehicle-label';

const RECENT_ACTIVITY_LIMIT = 10;

/**
 * Merged recentActivity for the dashboard — fuel + maintenance + documents,
 * date-descending, capped at 10. Leaner shape than GET /activity.
 * Does NOT include driving credentials (matches Python).
 */
export async function buildRecentActivity(
  vehicles: VehicleLabelSource[],
): Promise<DashboardActivityItem[]> {
  if (vehicles.length === 0) return [];

  const vehicleIds = vehicles.map((v) => v.id);
  const labelMap = new Map(vehicles.map((v) => [v.id, vehicleLabel(v)]));

  const [allFuel, allMaint, allDocs] = await Promise.all([
    db.select().from(fuelLogs).where(inArray(fuelLogs.vehicleId, vehicleIds)),
    db
      .select()
      .from(maintenanceRecords)
      .where(inArray(maintenanceRecords.vehicleId, vehicleIds)),
    db.select().from(documents).where(inArray(documents.vehicleId, vehicleIds)),
  ]);

  const items: DashboardActivityItem[] = [];

  for (const log of allFuel) {
    items.push({
      type: 'fuel',
      vehicleId: log.vehicleId,
      vehicleLabel: labelMap.get(log.vehicleId) ?? log.vehicleId,
      date: log.date,
      amountCents: log.priceCents,
      label: 'Fuel',
      liters: Number(log.liters),
      isFullTank: log.isFullTank,
    });
  }

  for (const rec of allMaint) {
    items.push({
      type: 'maintenance',
      vehicleId: rec.vehicleId,
      vehicleLabel: labelMap.get(rec.vehicleId) ?? rec.vehicleId,
      date: rec.date,
      amountCents: rec.costCents,
      label: rec.serviceType,
      liters: null,
      isFullTank: null,
    });
  }

  for (const doc of allDocs) {
    const docDate =
      doc.issueDate ?? doc.createdAt.toISOString().slice(0, 10);
    items.push({
      type: 'document',
      vehicleId: doc.vehicleId,
      vehicleLabel: labelMap.get(doc.vehicleId) ?? doc.vehicleId,
      date: docDate,
      amountCents: null,
      label: doc.title,
      liters: null,
      isFullTank: null,
    });
  }

  items.sort((a, b) => b.date.localeCompare(a.date));
  return items.slice(0, RECENT_ACTIVITY_LIMIT);
}
