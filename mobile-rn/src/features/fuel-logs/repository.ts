/** Fuel repository — the only caller of `api.ts`. */

import { fuelApi } from './api';
import type { FuelLog, FuelStats } from './types';

export const fuelRepository = {
  listForVehicle(vehicleId: string): Promise<FuelLog[]> {
    return fuelApi.listForVehicle(vehicleId);
  },

  stats(vehicleId: string): Promise<FuelStats> {
    return fuelApi.stats(vehicleId);
  },
};
