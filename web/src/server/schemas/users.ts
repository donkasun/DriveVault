import { z } from 'zod';

/** Wire shape for GET/PATCH /api/v1/me — matches Doc 3 / Python UserRead (no updatedAt). */
export const userResponseSchema = z.object({
  id: z.string().uuid(),
  firebaseUid: z.string(),
  email: z.string(),
  displayName: z.string().nullable(),
  photoUrl: z.string().nullable(),
  currency: z.string(),
  distanceUnit: z.enum(['km', 'mi']),
  renewalRemindersEnabled: z.boolean(),
  createdAt: z.string(),
});

export type UserResponse = z.infer<typeof userResponseSchema>;

/** PATCH /api/v1/me body — all fields optional. */
export const updateMeSchema = z.object({
  displayName: z.string().nullable().optional(),
  photoUrl: z.string().nullable().optional(),
  currency: z
    .string()
    .regex(/^[A-Za-z]{3}$/, 'currency must be a 3-letter code')
    .optional(),
  distanceUnit: z.enum(['km', 'mi']).optional(),
  renewalRemindersEnabled: z.boolean().optional(),
});

export type UpdateMe = z.infer<typeof updateMeSchema>;
