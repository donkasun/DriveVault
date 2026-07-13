/**
 * Local SQLite read-cache for the dashboard (best-practices.md §6).
 *
 * NOT the write path. The dashboard has no mutation of its own — it's a
 * read-only aggregate — so this only ever gets upserted after a successful
 * `GET /dashboard`. Single row at id=1, mirroring Flutter's
 * `dashboard_snapshots` table (whole payload cached as JSON).
 */

import { eq } from 'drizzle-orm';

import { db } from '@/db/client';
import { dashboard_snapshots as dashboardTable, DASHBOARD_SNAPSHOT_ID } from '@/db/schema';
import { parseDashboard, serializeDashboard } from './local-mappers';
import type { DashboardData } from './types';

export async function getCachedDashboard(): Promise<DashboardData | null> {
  const rows = await db
    .select()
    .from(dashboardTable)
    .where(eq(dashboardTable.id, DASHBOARD_SNAPSHOT_ID))
    .all();
  const row = rows[0];
  return row ? parseDashboard(row.payload) : null;
}

export async function upsertDashboard(payload: DashboardData): Promise<void> {
  const cachedAt = Date.now();
  const serialized = serializeDashboard(payload);
  await db
    .insert(dashboardTable)
    .values({ id: DASHBOARD_SNAPSHOT_ID, payload: serialized, cached_at: cachedAt })
    .onConflictDoUpdate({
      target: dashboardTable.id,
      set: { payload: serialized, cached_at: cachedAt },
    });
}

export async function clearDashboard(): Promise<void> {
  await db.delete(dashboardTable);
}
