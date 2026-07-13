/**
 * HTTP paths for the documents feature. Only `repository.ts` may call this.
 *
 * Doc 3: `GET /vehicles/{vehicleId}/documents` takes an optional `docType`
 * query param alias for filtering by document type.
 */

import { apiClient } from '@/lib/api-client';
import type { CreateDocumentPayload, Document, UpdateDocumentPayload } from './types';

export const documentsApi = {
  listForVehicle: (vehicleId: string, docType?: string) =>
    apiClient.get<Document[]>(`/vehicles/${vehicleId}/documents`, docType ? { docType } : undefined),
  create: (vehicleId: string, body: CreateDocumentPayload) =>
    apiClient.post<Document>(`/vehicles/${vehicleId}/documents`, body),
  update: (id: string, body: UpdateDocumentPayload) =>
    apiClient.patch<Document>(`/documents/${id}`, body),
  remove: (id: string) => apiClient.delete(`/documents/${id}`),
};
