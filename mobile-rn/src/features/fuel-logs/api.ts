/** HTTP paths for the fuel feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { CreateFuelLogPayload, FuelLog, FuelStats, UpdateFuelLogPayload } from './types';

export const fuelApi = {
  listForVehicle: (vehicleId: string) =>
    apiClient.get<FuelLog[]>(`/vehicles/${vehicleId}/fuel-logs`),
  stats: (vehicleId: string) => apiClient.get<FuelStats>(`/vehicles/${vehicleId}/fuel-stats`),
  create: (vehicleId: string, body: CreateFuelLogPayload) =>
    apiClient.post<FuelLog>(`/vehicles/${vehicleId}/fuel-logs`, body),
  update: (id: string, body: UpdateFuelLogPayload) =>
    apiClient.patch<FuelLog>(`/fuel-logs/${id}`, body),
  remove: (id: string) => apiClient.delete(`/fuel-logs/${id}`),
};
