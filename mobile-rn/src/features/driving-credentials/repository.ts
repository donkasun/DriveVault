/**
 * Driving-credentials repository — the only caller of `api.ts`. Parity with
 * Flutter `mobile/lib/features/driving_credentials/data/driving_credential_repository.dart`.
 */

import { drivingCredentialsApi } from './api';
import type { CreateCredentialPayload, DrivingCredential, UpdateCredentialPayload } from './types';

/** Drops undefined keys so PATCH only sends what actually changed. */
function prune<T extends object>(payload: T): T {
  return Object.fromEntries(
    Object.entries(payload).filter(([, value]) => value !== undefined),
  ) as T;
}

export const drivingCredentialsRepository = {
  list(): Promise<DrivingCredential[]> {
    return drivingCredentialsApi.list();
  },

  create(payload: CreateCredentialPayload): Promise<DrivingCredential> {
    return drivingCredentialsApi.create(prune(payload));
  },

  update(id: string, payload: UpdateCredentialPayload): Promise<DrivingCredential> {
    return drivingCredentialsApi.update(id, prune(payload));
  },

  remove(id: string): Promise<void> {
    return drivingCredentialsApi.remove(id);
  },
};
