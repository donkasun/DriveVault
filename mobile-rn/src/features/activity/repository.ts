/** Activity repository — the only caller of `api.ts`. */

import { activityApi } from './api';
import type { ActivityEntry } from './types';

export const activityRepository = {
  list(limit = 50): Promise<ActivityEntry[]> {
    return activityApi.list(limit);
  },
};
