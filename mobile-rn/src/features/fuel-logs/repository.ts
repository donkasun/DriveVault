/** Fuel repository — the only caller of `api.ts`. */

import { fuelApi } from './api';
import type { CreateFuelLogPayload, FuelLog, FuelStats, UpdateFuelLogPayload } from './types';

export const fuelRepository = {
  listForVehicle(vehicleId: string): Promise<FuelLog[]> {
    return fuelApi.listForVehicle(vehicleId);
  },

  stats(vehicleId: string): Promise<FuelStats> {
    return fuelApi.stats(vehicleId);
  },

  create(vehicleId: string, payload: CreateFuelLogPayload): Promise<FuelLog> {
    return fuelApi.create(vehicleId, payload);
  },

  update(id: string, payload: UpdateFuelLogPayload): Promise<FuelLog> {
    return fuelApi.update(id, payload);
  },

  remove(id: string): Promise<void> {
    return fuelApi.remove(id);
  },
};
