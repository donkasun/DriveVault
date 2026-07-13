/** HTTP paths for the driving-credentials feature. Only `repository.ts` may call this. */

import { apiClient } from '@/lib/api-client';
import type { CreateCredentialPayload, DrivingCredential, UpdateCredentialPayload } from './types';

export const drivingCredentialsApi = {
  list: () => apiClient.get<DrivingCredential[]>('/me/driving-credentials'),
  create: (body: CreateCredentialPayload) =>
    apiClient.post<DrivingCredential>('/me/driving-credentials', body),
  update: (id: string, body: UpdateCredentialPayload) =>
    apiClient.patch<DrivingCredential>(`/me/driving-credentials/${id}`, body),
  remove: (id: string) => apiClient.delete(`/me/driving-credentials/${id}`),
};
