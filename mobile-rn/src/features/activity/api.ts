/** HTTP paths for the activity feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { ActivityEntry } from './types';

export const activityApi = {
  list: (limit = 50) => apiClient.get<ActivityEntry[]>('/activity', { limit }),
};
