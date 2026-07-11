import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { db } from '@/server/db/client';
import { users } from '@/server/db/schema';
import { AppError } from '@/server/lib/errors';

const { verifyIdToken } = vi.hoisted(() => ({ verifyIdToken: vi.fn() }));

vi.mock('@/server/auth/firebase-admin', () => ({
  firebaseAuth: { verifyIdToken },
}));

const { requireUser } = await import('./require-user');

const TEST_UID_PREFIX = 'test-require-user-';

function requestWithToken(token?: string): NextRequest {
  const headers = new Headers();
  if (token) {
    headers.set('authorization', `Bearer ${token}`);
  }
  return new NextRequest('http://localhost/api/v1/_auth-check', { headers });
}

describe('requireUser', () => {
  beforeEach(() => {
    verifyIdToken.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('throws 401 Missing authorization token when there is no Authorization header', async () => {
    await expect(requireUser(requestWithToken())).rejects.toMatchObject({
      status: 401,
      detail: 'Missing authorization token',
    } satisfies Partial<AppError>);
  });

  it('throws 401 Token has been revoked when Firebase reports a revoked token', async () => {
    verifyIdToken.mockRejectedValue({ code: 'auth/id-token-revoked' });

    await expect(requireUser(requestWithToken('revoked-token'))).rejects.toMatchObject({
      status: 401,
      detail: 'Token has been revoked',
    } satisfies Partial<AppError>);

    expect(verifyIdToken).toHaveBeenCalledWith('revoked-token', true);
  });

  it('throws 401 Invalid or expired token for any other verification failure', async () => {
    verifyIdToken.mockRejectedValue(new Error('boom'));

    await expect(requireUser(requestWithToken('bad-token'))).rejects.toMatchObject({
      status: 401,
      detail: 'Invalid or expired token',
    } satisfies Partial<AppError>);
  });

  it('creates a new user on first call, ignoring an unverified email', async () => {
    const firebaseUid = `${TEST_UID_PREFIX}new`;
    verifyIdToken.mockResolvedValue({
      uid: firebaseUid,
      email: 'unverified@example.com',
      email_verified: false,
    });

    const user = await requireUser(requestWithToken('valid-token'));

    expect(user.firebaseUid).toBe(firebaseUid);
    expect(user.email).toBe('');
  });

  it('trusts the email when Firebase reports it as verified', async () => {
    const firebaseUid = `${TEST_UID_PREFIX}verified`;
    verifyIdToken.mockResolvedValue({
      uid: firebaseUid,
      email: 'verified@example.com',
      email_verified: true,
    });

    const user = await requireUser(requestWithToken('valid-token'));

    expect(user.email).toBe('verified@example.com');
  });

  it('keeps displayName/photoUrl in sync with Google sign-in on repeat calls', async () => {
    const firebaseUid = `${TEST_UID_PREFIX}google`;
    verifyIdToken.mockResolvedValue({
      uid: firebaseUid,
      email: 'google@example.com',
      email_verified: true,
      name: 'First Name',
      picture: 'https://example.com/first.png',
      firebase: { sign_in_provider: 'google.com' },
    });

    const created = await requireUser(requestWithToken('valid-token'));
    expect(created.displayName).toBe('First Name');

    verifyIdToken.mockResolvedValue({
      uid: firebaseUid,
      email: 'google@example.com',
      email_verified: true,
      name: 'Updated Name',
      picture: 'https://example.com/updated.png',
      firebase: { sign_in_provider: 'google.com' },
    });

    const updated = await requireUser(requestWithToken('valid-token'));
    expect(updated.id).toBe(created.id);
    expect(updated.displayName).toBe('Updated Name');
    expect(updated.photoUrl).toBe('https://example.com/updated.png');
  });
});
