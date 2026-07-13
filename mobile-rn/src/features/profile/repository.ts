/**
 * Profile repository — the only caller of `api.ts` (best-practices §1).
 * Parity with Flutter `mobile/lib/features/profile/data/user_repository.dart`.
 */

import { profileApi } from './api';
import type { AppUser, UpdateMePayload } from './types';

/** Drops undefined keys so PATCH only sends what actually changed. */
function pruneUndefined(payload: UpdateMePayload): UpdateMePayload {
  return Object.fromEntries(
    Object.entries(payload).filter(([, value]) => value !== undefined),
  ) as UpdateMePayload;
}

export const profileRepository = {
  getMe(): Promise<AppUser> {
    return profileApi.getMe();
  },

  /** Update display name and/or preferences. Only non-undefined fields are sent. */
  updateMe(payload: UpdateMePayload): Promise<AppUser> {
    return profileApi.updateMe(pruneUndefined(payload));
  },
};
