import { z } from 'zod';

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD');

/** POST /api/v1/vehicles/{id}/maintenance */
export const createMaintenanceSchema = z.object({
  id: z.string().uuid().optional(),
  date: dateString,
  odometer: z.number().int().nullable().optional(),
  serviceType: z.string().min(1),
  category: z.string().nullable().optional(),
  costCents: z.number().int().default(0),
  currency: z.string().optional(),
  workshop: z.string().nullable().optional(),
  notes: z.string().nullable().optional(),
});

export type CreateMaintenance = z.infer<typeof createMaintenanceSchema>;

/** PATCH /api/v1/maintenance/{id} — all fields optional; no currency re-lock. */
export const updateMaintenanceSchema = z.object({
  date: dateString.nullable().optional(),
  odometer: z.number().int().nullable().optional(),
  serviceType: z.string().min(1).nullable().optional(),
  category: z.string().nullable().optional(),
  costCents: z.number().int().optional(),
  currency: z.string().nullable().optional(),
  workshop: z.string().nullable().optional(),
  notes: z.string().nullable().optional(),
});

export type UpdateMaintenance = z.infer<typeof updateMaintenanceSchema>;

/** Wire shape for MaintenanceRecord responses (Doc 3). */
export const maintenanceResponseSchema = z.object({
  id: z.string().uuid(),
  vehicleId: z.string().uuid(),
  date: z.string(),
  odometer: z.number().int().nullable(),
  serviceType: z.string(),
  category: z.string().nullable(),
  costCents: z.number().int(),
  currency: z.string(),
  workshop: z.string().nullable(),
  notes: z.string().nullable(),
  source: z.string(),
  aiExtractionId: z.string().uuid().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type MaintenanceResponse = z.infer<typeof maintenanceResponseSchema>;
