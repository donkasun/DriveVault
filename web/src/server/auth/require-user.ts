import 'server-only';

import type { NextRequest } from 'next/server';

import { firebaseAuth } from '@/server/auth/firebase-admin';
import { upsertUserFromToken, type User } from '@/server/auth/upsert-user';
import { AppError } from '@/server/lib/errors';

/**
 * Ports `backend/app/deps.py::get_current_user`: verify the Firebase Bearer
 * token (rejecting revoked tokens immediately) and lazily upsert the matching
 * `users` row.
 */
export async function requireUser(req: NextRequest): Promise<User> {
  const token = extractBearerToken(req);

  let decoded;
  try {
    decoded = await firebaseAuth.verifyIdToken(token, true);
  } catch (err) {
    if (isRevokedTokenError(err)) {
      throw new AppError(401, 'Token has been revoked');
    }
    throw new AppError(401, 'Invalid or expired token');
  }

  return upsertUserFromToken(decoded);
}

function extractBearerToken(req: NextRequest): string {
  const header = req.headers.get('authorization');
  if (!header) {
    throw new AppError(401, 'Missing authorization token');
  }

  const [scheme, token] = header.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    throw new AppError(401, 'Missing authorization token');
  }

  return token;
}

function isRevokedTokenError(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code?: string }).code === 'auth/id-token-revoked'
  );
}
