/** Vehicles repository — the only caller of `api.ts` (best-practices §1). */

import { vehiclesApi } from './api';
import {
  normalizeVehicle,
  type CreateVehiclePayload,
  type UpdateVehiclePayload,
  type Vehicle,
} from './types';

function prune<T extends object>(payload: T): T {
  return Object.fromEntries(
    Object.entries(payload).filter(([, value]) => value !== undefined),
  ) as T;
}

export const vehiclesRepository = {
  async list(): Promise<Vehicle[]> {
    const rows = await vehiclesApi.list();
    return rows.map(normalizeVehicle);
  },

  /** Throws ApiError(404) when the vehicle is missing OR belongs to someone else. */
  async get(id: string): Promise<Vehicle> {
    return normalizeVehicle(await vehiclesApi.get(id));
  },

  async create(payload: CreateVehiclePayload): Promise<Vehicle> {
    return normalizeVehicle(await vehiclesApi.create(prune(payload)));
  },

  async update(id: string, payload: UpdateVehiclePayload): Promise<Vehicle> {
    return normalizeVehicle(await vehiclesApi.update(id, prune(payload)));
  },

  remove(id: string): Promise<void> {
    return vehiclesApi.remove(id);
  },
};
