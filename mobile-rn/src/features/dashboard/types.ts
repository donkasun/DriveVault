/**
 * Dashboard domain types — `GET /dashboard`.
 *
 * Field names verified against `backend/app/schemas/documents.py`
 * (`DashboardRead`, `CostBreakdown`, `UpcomingRenewal`, `ActivityItem`) and
 * parity with Flutter `mobile/lib/features/dashboard/domain/dashboard_data.dart`.
 *
 * NOTE (CLAUDE.md / task brief): Doc 3 (`docs/03-api-contract.md`) claims
 * `upcomingRenewals` is documents-only — that is WRONG. The backend merges
 * BOTH vehicle documents and driving credentials into this list; credential
 * entries have `vehicleId` and `vehicleLabel` set to null. Trust the Dart +
 * backend schema here, not Doc 3.
 *
 * Money is integer cents; odometer/mileage would be integer km (not present
 * on this shape).
 */

export type CostBreakdown = {
  fuelCents: number;
  maintenanceCents: number;
  purchaseCents: number;
};

export type RenewalStatus = 'ok' | 'soon' | 'overdue';

/**
 * One row of `upcomingRenewals`. `vehicleId`/`vehicleLabel` are null for
 * personal (driving) credentials — see the module note above.
 */
export type UpcomingRenewal = {
  vehicleId: string | null;
  title: string;
  /** "YYYY-MM-DD" */
  expiryDate: string;
  docType: string | null;
  vehicleLabel: string | null;
  daysRemaining: number | null;
  status: RenewalStatus | null;
};

export type ActivityType = 'fuel' | 'maintenance' | 'document';

/**
 * One row of the dashboard's embedded `recentActivity` — distinct from (and
 * poorer than) the standalone `GET /activity` feed: no `id`/`currency`, and it
 * never includes driving credentials. See `features/activity/types.ts` for
 * the richer, real activity feed.
 */
export type ActivityItem = {
  type: ActivityType;
  vehicleId: string;
  vehicleLabel: string;
  /** "YYYY-MM-DD" */
  date: string;
  /** Null for document entries. */
  amountCents: number | null;
  label: string;
  /** Fuel-only. */
  liters: number | null;
  /** Fuel-only. */
  isFullTank: boolean | null;
};

export type DashboardData = {
  vehicleCount: number;
  monthlyFuelSpendCents: number;
  totalOwnershipCostCents: number;
  costBreakdown: CostBreakdown;
  upcomingRenewals: UpcomingRenewal[];
  recentActivity: ActivityItem[];
};

/** True for personal (driving) credential renewal rows — parity with Dart's `isPersonalCredential`. */
export function isPersonalCredential(renewal: UpcomingRenewal): boolean {
  return renewal.vehicleId == null;
}
