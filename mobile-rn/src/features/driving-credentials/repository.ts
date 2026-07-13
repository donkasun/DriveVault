/** Driving-credentials repository — the only caller of `api.ts`. */

import { drivingCredentialsApi } from './api';
import type { DrivingCredential } from './types';

export const drivingCredentialsRepository = {
  list(): Promise<DrivingCredential[]> {
    return drivingCredentialsApi.list();
  },
};
