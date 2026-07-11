import { z } from 'zod';

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD');

/** Cost breakdown nested under DashboardRead (Doc 3 / Python CostBreakdown). */
export const costBreakdownSchema = z.object({
  fuelCents: z.number().int(),
  maintenanceCents: z.number().int(),
  purchaseCents: z.number().int(),
});

export type CostBreakdown = z.infer<typeof costBreakdownSchema>;

/**
 * Upcoming renewal row.
 * vehicleId / vehicleLabel are null for driving-credential renewals
 * (Doc 3 drift — see dashboard-renewals.ts).
 */
export const upcomingRenewalSchema = z.object({
  vehicleId: z.string().uuid().nullable(),
  title: z.string(),
  expiryDate: dateString,
  docType: z.string(),
  vehicleLabel: z.string().nullable(),
  daysRemaining: z.number().int(),
  status: z.enum(['ok', 'soon', 'overdue']),
});

export type UpcomingRenewal = z.infer<typeof upcomingRenewalSchema>;

/**
 * Dashboard recentActivity item — leaner than GET /activity (no id/currency/type-specific extras).
 * Port of Python ActivityItem in schemas/documents.py.
 */
export const dashboardActivityItemSchema = z.object({
  type: z.enum(['fuel', 'maintenance', 'document']),
  vehicleId: z.string().uuid(),
  vehicleLabel: z.string(),
  date: dateString,
  amountCents: z.number().int().nullable(),
  label: z.string(),
  liters: z.number().nullable().optional(),
  isFullTank: z.boolean().nullable().optional(),
});

export type DashboardActivityItem = z.infer<typeof dashboardActivityItemSchema>;

/** GET /api/v1/dashboard response (Python DashboardRead). */
export const dashboardReadSchema = z.object({
  vehicleCount: z.number().int(),
  monthlyFuelSpendCents: z.number().int(),
  totalOwnershipCostCents: z.number().int(),
  costBreakdown: costBreakdownSchema,
  upcomingRenewals: z.array(upcomingRenewalSchema),
  recentActivity: z.array(dashboardActivityItemSchema),
});

export type DashboardRead = z.infer<typeof dashboardReadSchema>;

export const EMPTY_DASHBOARD: DashboardRead = {
  vehicleCount: 0,
  monthlyFuelSpendCents: 0,
  totalOwnershipCostCents: 0,
  costBreakdown: {
    fuelCents: 0,
    maintenanceCents: 0,
    purchaseCents: 0,
  },
  upcomingRenewals: [],
  recentActivity: [],
};
