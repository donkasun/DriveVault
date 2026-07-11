import 'server-only';

import { eq } from 'drizzle-orm';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { users } from '@/server/db/schema';
import { LOCKED_CURRENCY } from '@/server/lib/constants';
import type { UpdateMe, UserResponse } from '@/server/schemas/users';

/** Map a Drizzle user row to the Doc 3 /me response (no updatedAt). */
export function toUserResponse(user: User): UserResponse {
  return {
    id: user.id,
    firebaseUid: user.firebaseUid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoUrl,
    // pg `char(3)` can pad with spaces — trim so the wire value is exactly "LKR".
    currency: user.currency.trim(),
    distanceUnit: user.distanceUnit as 'km' | 'mi',
    renewalRemindersEnabled: user.renewalRemindersEnabled,
    createdAt: user.createdAt.toISOString(),
  };
}

/**
 * Apply a partial profile update. When `currency` is present in the patch it is
 * forced to LOCKED_CURRENCY (same as Python `update_user_profile`).
 */
export async function updateUserProfile(user: User, patch: UpdateMe): Promise<User> {
  const updates: Partial<typeof users.$inferInsert> = {};

  if (patch.displayName !== undefined) {
    updates.displayName = patch.displayName;
  }
  if (patch.photoUrl !== undefined) {
    updates.photoUrl = patch.photoUrl;
  }
  if (patch.distanceUnit !== undefined) {
    updates.distanceUnit = patch.distanceUnit;
  }
  if (patch.renewalRemindersEnabled !== undefined) {
    updates.renewalRemindersEnabled = patch.renewalRemindersEnabled;
  }
  if ('currency' in patch && patch.currency !== undefined) {
    updates.currency = LOCKED_CURRENCY;
  }

  updates.updatedAt = new Date();

  const [updated] = await db
    .update(users)
    .set(updates)
    .where(eq(users.id, user.id))
    .returning();

  return updated;
}
