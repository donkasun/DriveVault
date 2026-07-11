import 'server-only';

import { asc, eq } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { fuelLogs } from '@/server/db/schema';
import type { FuelStatsResponse } from '@/server/schemas/fuel-logs';
import { getVehicleForUser } from '@/server/services/vehicles';

/**
 * Interval-method fuel economy stats.
 *
 * Port of backend/app/services/fuel_logs.py::compute_fuel_stats.
 *
 * A measurement interval can only OPEN and CLOSE at a full-tank fill, where
 * the tank level is a known reference. Partial fills accumulate into the
 * interval that closes at the next full tank. Partial fills before the first
 * full tank (no valid opening anchor) and after the last full tank (interval
 * never closes) are both excluded from the average.
 *
 * Important: `intervalOpen` never resets after the first full tank — once
 * opened it stays open for the rest of the scan (matches Python).
 *
 * Rounding: consumption to 1 decimal; cost-per-km nearest int.
 * Note: Python 3 `round` uses banker's rounding; Math.round is half-up.
 * Current fixtures do not hit half-to-even edge cases.
 */
export async function computeFuelStats(
  userId: string,
  vehicleId: string,
): Promise<FuelStatsResponse> {
  await getVehicleForUser(userId, vehicleId);

  const logs = await db
    .select()
    .from(fuelLogs)
    .where(eq(fuelLogs.vehicleId, vehicleId))
    .orderBy(asc(fuelLogs.date));

  let totalLiters = 0;
  let totalSpentCents = 0;
  const monthlyTotals = new Map<string, number>();

  for (const log of logs) {
    const liters = Number(log.liters);
    totalLiters += liters;
    totalSpentCents += log.priceCents;
    // date is YYYY-MM-DD from pg
    const month = log.date.slice(0, 7);
    monthlyTotals.set(month, (monthlyTotals.get(month) ?? 0) + log.priceCents);
  }

  let pendingLiters = 0;
  let pendingDistance = 0;
  let pendingSpentCents = 0;
  let closedLiters = 0;
  let closedDistance = 0;
  let closedSpentCents = 0;
  let intervalOpen = false;

  for (let i = 0; i < logs.length - 1; i++) {
    const previous = logs[i];
    const current = logs[i + 1];

    if (!intervalOpen) {
      // Only a full-tank log can anchor the start of an interval.
      if (!previous.isFullTank) {
        continue;
      }
      intervalOpen = true;
    }

    const distance = current.odometer - previous.odometer;
    if (distance <= 0) {
      continue;
    }

    pendingLiters += Number(current.liters);
    pendingDistance += distance;
    pendingSpentCents += current.priceCents;

    if (current.isFullTank) {
      closedLiters += pendingLiters;
      closedDistance += pendingDistance;
      closedSpentCents += pendingSpentCents;
      pendingLiters = 0;
      pendingDistance = 0;
      pendingSpentCents = 0;
    }
  }

  let avgConsumptionLPer100Km: number | null = null;
  let avgCostPerKmCents: number | null = null;
  if (closedDistance > 0) {
    // round to 1 decimal (matches Python round(..., 1))
    avgConsumptionLPer100Km =
      Math.round((closedLiters / closedDistance) * 100 * 10) / 10;
    avgCostPerKmCents = Math.round(closedSpentCents / closedDistance);
  }

  const monthlySpend = [...monthlyTotals.entries()]
    .sort(([a], [b]) => (a < b ? 1 : a > b ? -1 : 0))
    .map(([month, spentCents]) => ({ month, spentCents }));

  return {
    avgConsumptionLPer100Km,
    avgCostPerKmCents,
    totalLiters,
    totalSpentCents,
    monthlySpend,
  };
}
