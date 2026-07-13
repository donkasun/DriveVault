/**
 * Pure payload <-> JSON mappers for the dashboard read-cache. Split out from
 * `local.ts` so they can be unit-tested without touching expo-sqlite.
 */

import type { DashboardData } from './types';

export function serializeDashboard(payload: DashboardData): string {
  return JSON.stringify(payload);
}

/** Returns null on malformed JSON rather than throwing — cache corruption should never crash a screen. */
export function parseDashboard(json: string): DashboardData | null {
  try {
    return JSON.parse(json) as DashboardData;
  } catch {
    return null;
  }
}
