/** HTTP paths for the vehicles feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { CreateVehiclePayload, UpdateVehiclePayload, Vehicle } from './types';

export const vehiclesApi = {
  list: () => apiClient.get<Vehicle[]>('/vehicles'),
  get: (id: string) => apiClient.get<Vehicle>(`/vehicles/${id}`),
  create: (body: CreateVehiclePayload) => apiClient.post<Vehicle>('/vehicles', body),
  update: (id: string, body: UpdateVehiclePayload) =>
    apiClient.patch<Vehicle>(`/vehicles/${id}`, body),
  remove: (id: string) => apiClient.delete(`/vehicles/${id}`),
};
