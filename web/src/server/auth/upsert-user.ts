import 'server-only';

import { eq } from 'drizzle-orm';
import type { DecodedIdToken } from 'firebase-admin/auth';

import { db } from '@/server/db/client';
import { users } from '@/server/db/schema';
import { AppError } from '@/server/lib/errors';

export type User = typeof users.$inferSelect;

const UNIQUE_VIOLATION = '23505';

/**
 * Lazily creates (or syncs) the `users` row for a verified Firebase token.
 * Ports `backend/app/deps.py::get_current_user`'s upsert behavior exactly:
 * - `email` is only trusted when Firebase reports it as verified.
 * - Google sign-in keeps `displayName`/`photoUrl` in sync on every request.
 * - A concurrent-insert race (unique violation on `firebase_uid`) re-selects
 *   the row that the other request just created instead of failing.
 */
export async function upsertUserFromToken(decoded: DecodedIdToken): Promise<User> {
  const firebaseUid = decoded.uid;
  const email = decoded.email_verified === true ? decoded.email ?? '' : '';
  const signInProvider = decoded.firebase?.sign_in_provider ?? '';
  const isGoogle = signInProvider === 'google.com';
  const displayName = decoded.name ?? '';
  const photoUrl = decoded.picture ?? '';

  const existing = await findByFirebaseUid(firebaseUid);

  if (!existing) {
    try {
      const [created] = await db
        .insert(users)
        .values({ firebaseUid, email, displayName, photoUrl })
        .returning();
      return created;
    } catch (err) {
      if (!isUniqueViolation(err)) {
        throw err;
      }
      const raced = await findByFirebaseUid(firebaseUid);
      if (!raced) {
        throw new AppError(500, 'User creation failed');
      }
      return raced;
    }
  }

  if (isGoogle) {
    const updates: Partial<typeof users.$inferInsert> = {};
    if (displayName && existing.displayName !== displayName) {
      updates.displayName = displayName;
    }
    if (photoUrl && existing.photoUrl !== photoUrl) {
      updates.photoUrl = photoUrl;
    }
    if (Object.keys(updates).length > 0) {
      const [updated] = await db
        .update(users)
        .set(updates)
        .where(eq(users.id, existing.id))
        .returning();
      return updated;
    }
  }

  return existing;
}

async function findByFirebaseUid(firebaseUid: string): Promise<User | undefined> {
  const [row] = await db.select().from(users).where(eq(users.firebaseUid, firebaseUid)).limit(1);
  return row;
}

function isUniqueViolation(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code?: string }).code === UNIQUE_VIOLATION
  );
}
