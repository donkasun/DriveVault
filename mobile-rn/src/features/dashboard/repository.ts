/** Dashboard repository — the only caller of `api.ts`. */

import { dashboardApi } from './api';
import type { DashboardData } from './types';

export const dashboardRepository = {
  get(): Promise<DashboardData> {
    return dashboardApi.get();
  },
};
