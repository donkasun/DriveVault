import 'server-only';

import { eq, inArray } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { fuelLogs, maintenanceRecords, vehicles } from '@/server/db/schema';
import {
  EMPTY_DASHBOARD,
  type DashboardRead,
} from '@/server/schemas/dashboard';
import { buildRecentActivity } from '@/server/services/dashboard-activity';
import { buildUpcomingRenewals } from '@/server/services/dashboard-renewals';

/**
 * Aggregated dashboard for the home screen — port of get_dashboard_data.
 *
 * Monthly fuel window: current **UTC** calendar month
 * (`[monthStart, nextMonthStart)`). Python uses `date.today()` (server local
 * calendar date). On Vercel UTC this matches; a FastAPI host in a non-UTC
 * timezone near month boundaries can disagree by up to one day of logs.
 */
export async function getDashboardData(userId: string): Promise<DashboardRead> {
  const userVehicles = await db
    .select()
    .from(vehicles)
    .where(eq(vehicles.userId, userId));

  if (userVehicles.length === 0) {
    return { ...EMPTY_DASHBOARD };
  }

  const vehicleIds = userVehicles.map((v) => v.id);
  const today = utcToday();

  const [allFuel, allMaint, upcomingRenewals, recentActivity] =
    await Promise.all([
      db.select().from(fuelLogs).where(inArray(fuelLogs.vehicleId, vehicleIds)),
      db
        .select()
        .from(maintenanceRecords)
        .where(inArray(maintenanceRecords.vehicleId, vehicleIds)),
      buildUpcomingRenewals(userId, userVehicles, today),
      buildRecentActivity(userVehicles),
    ]);

  const { monthStart, nextMonthStart } = utcMonthBounds(today);

  const monthlyFuelSpendCents = allFuel
    .filter((log) => log.date >= monthStart && log.date < nextMonthStart)
    .reduce((sum, log) => sum + log.priceCents, 0);

  const fuelCents = allFuel.reduce((sum, log) => sum + log.priceCents, 0);
  const maintenanceCents = allMaint.reduce(
    (sum, rec) => sum + rec.costCents,
    0,
  );
  const purchaseCents = userVehicles.reduce(
    (sum, v) => sum + (v.purchasePriceCents ?? 0),
    0,
  );

  return {
    vehicleCount: userVehicles.length,
    monthlyFuelSpendCents,
    totalOwnershipCostCents: fuelCents + maintenanceCents + purchaseCents,
    costBreakdown: {
      fuelCents,
      maintenanceCents,
      purchaseCents,
    },
    upcomingRenewals,
    recentActivity,
  };
}

/** YYYY-MM-DD for the current UTC calendar day. */
export function utcToday(now: Date = new Date()): string {
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  )
    .toISOString()
    .slice(0, 10);
}

/** Inclusive monthStart / exclusive nextMonthStart for the UTC month of `today`. */
export function utcMonthBounds(today: string): {
  monthStart: string;
  nextMonthStart: string;
} {
  const [y, m] = today.split('-').map(Number);
  const monthStart = `${y}-${String(m).padStart(2, '0')}-01`;
  const nextMonthStart =
    m === 12
      ? `${y + 1}-01-01`
      : `${y}-${String(m + 1).padStart(2, '0')}-01`;
  return { monthStart, nextMonthStart };
}
