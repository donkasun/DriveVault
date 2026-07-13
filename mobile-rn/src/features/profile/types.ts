/**
 * `GET /api/v1/me` (Doc 3). camelCase JSON — parity with Flutter
 * `mobile/lib/features/profile/domain/user.dart`.
 *
 * NOTE: Flutter's AppUser has no `updatedAt` — it is not parsed even if the API
 * sends it. Kept out here too so the two clients agree.
 */
export type AppUser = {
  id: string;
  firebaseUid: string;
  email: string;
  displayName: string | null;
  photoUrl: string | null;
  /** Account-wide money preference (3-letter code, e.g. "LKR"). */
  currency: string;
  /** Account-wide distance display preference. */
  distanceUnit: 'km' | 'mi';
  /** User-level toggle for reminder notifications. */
  renewalRemindersEnabled: boolean;
  createdAt: string;
};

/** PATCH /me body — only the fields being changed are sent. */
export type UpdateMePayload = {
  displayName?: string;
  currency?: string;
  distanceUnit?: 'km' | 'mi';
  renewalRemindersEnabled?: boolean;
};
