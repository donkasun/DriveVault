import { z } from 'zod';

/** POST /api/v1/uploads/cloudinary-signature request body. */
export const cloudinarySignatureRequestSchema = z.object({
  folder: z.string().min(1),
});

export type CloudinarySignatureRequest = z.infer<
  typeof cloudinarySignatureRequestSchema
>;

/** Wire shape for CloudinarySignatureRead (Doc 3). */
export const cloudinarySignatureResponseSchema = z.object({
  signature: z.string(),
  timestamp: z.number().int(),
  apiKey: z.string(),
  cloudName: z.string(),
  folder: z.string(),
});

export type CloudinarySignatureResponse = z.infer<
  typeof cloudinarySignatureResponseSchema
>;
