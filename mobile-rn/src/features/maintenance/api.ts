/** HTTP paths for the maintenance feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { CreateMaintenancePayload, MaintenanceRecord, UpdateMaintenancePayload } from './types';

export const maintenanceApi = {
  listForVehicle: (vehicleId: string) =>
    apiClient.get<MaintenanceRecord[]>(`/vehicles/${vehicleId}/maintenance`),
  create: (vehicleId: string, body: CreateMaintenancePayload) =>
    apiClient.post<MaintenanceRecord>(`/vehicles/${vehicleId}/maintenance`, body),
  update: (id: string, body: UpdateMaintenancePayload) =>
    apiClient.patch<MaintenanceRecord>(`/maintenance/${id}`, body),
  remove: (id: string) => apiClient.delete(`/maintenance/${id}`),
};
