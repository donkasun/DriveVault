import { z } from 'zod';

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD');

/** Allowed docType values — matches Python Literal + DB check constraint. */
export const DOC_TYPES = ['license', 'permit', 'international_license'] as const;

export const docTypeSchema = z.enum(DOC_TYPES);

/**
 * POST /api/v1/me/driving-credentials
 * docType is required; remaining fields optional (matches CredentialCreate).
 */
export const createCredentialSchema = z.object({
  docType: docTypeSchema,
  docNumber: z.string().nullable().optional(),
  issueDate: dateString.nullable().optional(),
  expiryDate: dateString.nullable().optional(),
  notes: z.string().nullable().optional(),
});

export type CreateCredential = z.infer<typeof createCredentialSchema>;

/** PATCH /api/v1/me/driving-credentials/{id} — all fields optional. */
export const updateCredentialSchema = z.object({
  docType: docTypeSchema.optional(),
  docNumber: z.string().nullable().optional(),
  issueDate: dateString.nullable().optional(),
  expiryDate: dateString.nullable().optional(),
  notes: z.string().nullable().optional(),
});

export type UpdateCredential = z.infer<typeof updateCredentialSchema>;

/**
 * Wire shape for Credential responses.
 * status / daysUntilExpiry are computed; null when no expiryDate.
 */
export const credentialResponseSchema = z.object({
  id: z.string().uuid(),
  docType: z.string(),
  docNumber: z.string().nullable(),
  issueDate: z.string().nullable(),
  expiryDate: z.string().nullable(),
  notes: z.string().nullable(),
  status: z.enum(['overdue', 'soon', 'ok']).nullable(),
  daysUntilExpiry: z.number().int().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type CredentialResponse = z.infer<typeof credentialResponseSchema>;
