import { z } from 'zod';

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD');

/**
 * POST /api/v1/vehicles/{id}/documents
 * docType is a plain string (matches Python DocumentCreate — no enum validation).
 */
export const createDocumentSchema = z.object({
  docType: z.string().min(1),
  title: z.string().min(1),
  storageUrl: z.string().min(1),
  storagePublicId: z.string().nullable().optional(),
  mimeType: z.string().nullable().optional(),
  fileSizeBytes: z.number().int().nullable().optional(),
  issueDate: dateString.nullable().optional(),
  expiryDate: dateString.nullable().optional(),
});

export type CreateDocument = z.infer<typeof createDocumentSchema>;

/** PATCH /api/v1/documents/{id} — all fields optional. */
export const updateDocumentSchema = z.object({
  docType: z.string().min(1).nullable().optional(),
  title: z.string().min(1).nullable().optional(),
  storageUrl: z.string().min(1).nullable().optional(),
  storagePublicId: z.string().nullable().optional(),
  mimeType: z.string().nullable().optional(),
  fileSizeBytes: z.number().int().nullable().optional(),
  issueDate: dateString.nullable().optional(),
  expiryDate: dateString.nullable().optional(),
});

export type UpdateDocument = z.infer<typeof updateDocumentSchema>;

/** Wire shape for Document responses (Doc 3). */
export const documentResponseSchema = z.object({
  id: z.string().uuid(),
  vehicleId: z.string().uuid(),
  docType: z.string(),
  title: z.string(),
  storageUrl: z.string(),
  storagePublicId: z.string().nullable(),
  mimeType: z.string().nullable(),
  fileSizeBytes: z.number().int().nullable(),
  issueDate: z.string().nullable(),
  expiryDate: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type DocumentResponse = z.infer<typeof documentResponseSchema>;
