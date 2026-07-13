/** Documents repository — the only caller of `api.ts` (best-practices §1). */

import { documentsApi } from './api';
import type { CreateDocumentPayload, Document, UpdateDocumentPayload } from './types';

export const documentsRepository = {
  listForVehicle(vehicleId: string, docType?: string): Promise<Document[]> {
    return documentsApi.listForVehicle(vehicleId, docType);
  },

  create(vehicleId: string, payload: CreateDocumentPayload): Promise<Document> {
    return documentsApi.create(vehicleId, payload);
  },

  update(id: string, payload: UpdateDocumentPayload): Promise<Document> {
    return documentsApi.update(id, payload);
  },

  remove(id: string): Promise<void> {
    return documentsApi.remove(id);
  },
};
