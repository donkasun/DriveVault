import { z } from 'zod';

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD');

/**
 * GET /activity?limit= — FastAPI Query(ge=1, le=200), default 50.
 * Invalid values → ZodError → 400 via toErrorResponse.
 * (Doc 3 has no /activity section; Python is sole source of truth.)
 */
export const activityLimitSchema = z.coerce
  .number()
  .int()
  .min(1, 'limit must be >= 1')
  .max(200, 'limit must be <= 200');

/**
 * Richer activity feed item — port of Python ActivityItemRead.
 * Includes id, currency, createdAt, and type-specific fields.
 * Does NOT include driving credentials (Python activity_service.py).
 */
export const activityItemReadSchema = z.object({
  type: z.enum(['fuel', 'maintenance', 'document']),
  id: z.string().uuid(),
  vehicleId: z.string().uuid(),
  vehicleLabel: z.string(),
  date: dateString,
  amountCents: z.number().int().nullable(),
  label: z.string(),
  currency: z.string(),
  createdAt: z.string(),

  liters: z.number().nullable().optional(),
  isFullTank: z.boolean().nullable().optional(),
  odometer: z.number().int().nullable().optional(),
  notes: z.string().nullable().optional(),
  source: z.string().nullable().optional(),
  category: z.string().nullable().optional(),
  workshop: z.string().nullable().optional(),

  title: z.string().nullable().optional(),
  docType: z.string().nullable().optional(),
  storageUrl: z.string().nullable().optional(),
  storagePublicId: z.string().nullable().optional(),
  mimeType: z.string().nullable().optional(),
  fileSizeBytes: z.number().int().nullable().optional(),
  issueDate: dateString.nullable().optional(),
  expiryDate: dateString.nullable().optional(),
});

export type ActivityItemRead = z.infer<typeof activityItemReadSchema>;
