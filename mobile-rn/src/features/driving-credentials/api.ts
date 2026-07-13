/** HTTP paths for the driving-credentials feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { DrivingCredential } from './types';

export const drivingCredentialsApi = {
  list: () => apiClient.get<DrivingCredential[]>('/me/driving-credentials'),
};
