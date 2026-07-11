import { z } from 'zod';

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD');

/** POST /api/v1/vehicles/{id}/fuel-logs */
export const createFuelLogSchema = z.object({
  id: z.string().uuid().optional(),
  date: dateString,
  liters: z.number().gt(0),
  priceCents: z.number().int(),
  currency: z.string().optional(),
  odometer: z.number().int(),
  isFullTank: z.boolean().default(true),
  notes: z.string().nullable().optional(),
});

export type CreateFuelLog = z.infer<typeof createFuelLogSchema>;

/** PATCH /api/v1/fuel-logs/{id} — all fields optional; no currency re-lock. */
export const updateFuelLogSchema = z.object({
  date: dateString.nullable().optional(),
  liters: z.number().gt(0).nullable().optional(),
  priceCents: z.number().int().nullable().optional(),
  currency: z.string().nullable().optional(),
  odometer: z.number().int().nullable().optional(),
  isFullTank: z.boolean().optional(),
  notes: z.string().nullable().optional(),
});

export type UpdateFuelLog = z.infer<typeof updateFuelLogSchema>;

/** Wire shape for FuelLog responses (Doc 3). */
export const fuelLogResponseSchema = z.object({
  id: z.string().uuid(),
  vehicleId: z.string().uuid(),
  date: z.string(),
  liters: z.number(),
  priceCents: z.number().int(),
  currency: z.string(),
  odometer: z.number().int(),
  isFullTank: z.boolean(),
  notes: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type FuelLogResponse = z.infer<typeof fuelLogResponseSchema>;

export const monthlySpendSchema = z.object({
  month: z.string(),
  spentCents: z.number().int(),
});

export type MonthlySpend = z.infer<typeof monthlySpendSchema>;

/** GET /api/v1/vehicles/{id}/fuel-stats */
export const fuelStatsResponseSchema = z.object({
  avgConsumptionLPer100Km: z.number().nullable(),
  avgCostPerKmCents: z.number().int().nullable(),
  totalLiters: z.number(),
  totalSpentCents: z.number().int(),
  monthlySpend: z.array(monthlySpendSchema),
});

export type FuelStatsResponse = z.infer<typeof fuelStatsResponseSchema>;
