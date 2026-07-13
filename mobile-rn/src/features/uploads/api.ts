/** Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { CloudinarySignature } from './types';

export const uploadsApi = {
  /** The backend signs the upload; it never sees the file bytes. */
  signature: (folder: string) =>
    apiClient.post<CloudinarySignature>('/uploads/cloudinary-signature', { folder }),
};
