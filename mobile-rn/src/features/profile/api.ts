/** HTTP paths for the profile feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { AppUser, UpdateMePayload } from './types';

export const profileApi = {
  getMe: () => apiClient.get<AppUser>('/me'),
  updateMe: (body: UpdateMePayload) => apiClient.patch<AppUser>('/me', body),
};
