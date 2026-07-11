import 'server-only';

import { and, eq, inArray, isNotNull, lte } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { documents, userDocuments } from '@/server/db/schema';
import type { UpcomingRenewal } from '@/server/schemas/dashboard';
import { DOC_TYPE_LABELS } from '@/server/services/driving-credentials';
import { daysUntil, renewalStatus } from '@/server/services/renewals';
import { vehicleLabel, type VehicleLabelSource } from '@/server/services/vehicle-label';

/**
 * Build upcomingRenewals for the dashboard.
 *
 * DOC/CODE DRIFT (Doc 3 § Dashboard):
 * Doc 3 describes upcomingRenewals as vehicle documents only. Real Python
 * (`backend/app/services/dashboard.py`) ALSO merges driving credentials
 * (`user_documents`) with vehicleId/vehicleLabel null and DOC_TYPE_LABELS for
 * title. This port matches Python, not the stale Doc 3 wording.
 *
 * Window: overdue (any age) + expiry within 90 days; sorted ascending by expiryDate.
 */
export async function buildUpcomingRenewals(
  userId: string,
  vehicles: VehicleLabelSource[],
  today: string,
): Promise<UpcomingRenewal[]> {
  if (vehicles.length === 0) return [];

  const vehicleIds = vehicles.map((v) => v.id);
  const labelMap = new Map(vehicles.map((v) => [v.id, vehicleLabel(v)]));

  const ninetyDaysLater = addUtcDays(today, 90);

  const [docs, creds] = await Promise.all([
    db
      .select()
      .from(documents)
      .where(
        and(
          inArray(documents.vehicleId, vehicleIds),
          isNotNull(documents.expiryDate),
          lte(documents.expiryDate, ninetyDaysLater),
        ),
      ),
    db
      .select()
      .from(userDocuments)
      .where(
        and(
          eq(userDocuments.userId, userId),
          isNotNull(userDocuments.expiryDate),
          lte(userDocuments.expiryDate, ninetyDaysLater),
        ),
      ),
  ]);

  const renewals: UpcomingRenewal[] = [];

  for (const doc of docs) {
    const expiry = doc.expiryDate!;
    renewals.push({
      vehicleId: doc.vehicleId,
      title: doc.title,
      expiryDate: expiry,
      docType: doc.docType,
      vehicleLabel: labelMap.get(doc.vehicleId) ?? doc.vehicleId,
      daysRemaining: daysUntil(expiry, today),
      status: renewalStatus(expiry, today),
    });
  }

  for (const cred of creds) {
    const expiry = cred.expiryDate!;
    renewals.push({
      vehicleId: null,
      title: DOC_TYPE_LABELS[cred.docType] ?? cred.docType,
      expiryDate: expiry,
      docType: cred.docType,
      vehicleLabel: null,
      daysRemaining: daysUntil(expiry, today),
      status: renewalStatus(expiry, today),
    });
  }

  renewals.sort((a, b) => a.expiryDate.localeCompare(b.expiryDate));
  return renewals;
}

/** Add days to a YYYY-MM-DD string in UTC. */
export function addUtcDays(dateStr: string, days: number): string {
  const [y, m, d] = dateStr.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + days));
  return dt.toISOString().slice(0, 10);
}
