/** HTTP paths for the dashboard feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { DashboardData } from './types';

export const dashboardApi = {
  get: () => apiClient.get<DashboardData>('/dashboard'),
};
