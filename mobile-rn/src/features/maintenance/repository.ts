/** Maintenance repository — the only caller of `api.ts` (best-practices §1). */

import { maintenanceApi } from './api';
import type { CreateMaintenancePayload, MaintenanceRecord, UpdateMaintenancePayload } from './types';

export const maintenanceRepository = {
  listForVehicle(vehicleId: string): Promise<MaintenanceRecord[]> {
    return maintenanceApi.listForVehicle(vehicleId);
  },

  create(vehicleId: string, payload: CreateMaintenancePayload): Promise<MaintenanceRecord> {
    return maintenanceApi.create(vehicleId, payload);
  },

  update(id: string, payload: UpdateMaintenancePayload): Promise<MaintenanceRecord> {
    return maintenanceApi.update(id, payload);
  },

  remove(id: string): Promise<void> {
    return maintenanceApi.remove(id);
  },
};
