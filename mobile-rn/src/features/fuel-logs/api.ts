/** HTTP paths for the fuel feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { FuelLog, FuelStats } from './types';

export const fuelApi = {
  listForVehicle: (vehicleId: string) =>
    apiClient.get<FuelLog[]>(`/vehicles/${vehicleId}/fuel-logs`),
  stats: (vehicleId: string) => apiClient.get<FuelStats>(`/vehicles/${vehicleId}/fuel-stats`),
};
