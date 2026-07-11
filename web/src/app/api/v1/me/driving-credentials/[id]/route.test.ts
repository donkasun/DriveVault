import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { userDocuments, users } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-cred-id-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid =
    overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'cred-id@example.com',
      displayName: overrides.displayName ?? 'Test',
      photoUrl: overrides.photoUrl ?? null,
      currency: overrides.currency ?? 'LKR',
      distanceUnit: overrides.distanceUnit ?? 'km',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
    })
    .returning();
  return row;
}

async function seedCredential(
  userId: string,
  overrides: Partial<typeof userDocuments.$inferInsert> = {},
) {
  const [row] = await db
    .insert(userDocuments)
    .values({
      userId,
      docType: overrides.docType ?? 'license',
      docNumber: overrides.docNumber ?? null,
      issueDate: overrides.issueDate ?? null,
      expiryDate: overrides.expiryDate ?? null,
      notes: overrides.notes ?? null,
      ...overrides,
    })
    .returning();
  return row;
}

function ctx(id: string) {
  return { params: Promise.resolve({ id }) };
}

function patchRequest(id: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/me/driving-credentials/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function deleteRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/me/driving-credentials/${id}`, {
    method: 'DELETE',
  });
}

describe('PATCH/DELETE /api/v1/me/driving-credentials/[id]', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('PATCH updates docNumber', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const cred = await seedCredential(owner.id);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(cred.id, { docNumber: 'X999' }),
      ctx(cred.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.docNumber).toBe('X999');
  });

  it('DELETE removes credential and returns 204', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const cred = await seedCredential(owner.id);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(cred.id), ctx(cred.id));

    expect(response.status).toBe(204);
    const remaining = await db
      .select()
      .from(userDocuments)
      .where(eq(userDocuments.id, cred.id));
    expect(remaining).toHaveLength(0);
  });

  it('PATCH returns 404 for other user credential', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other-cred@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherCred = await seedCredential(other.id);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(otherCred.id, { docNumber: 'X' }),
      ctx(otherCred.id),
    );

    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({
      detail: 'Credential not found',
    });
  });

  it('DELETE returns 404 for other user credential', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other-cred2@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherCred = await seedCredential(other.id);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(otherCred.id), ctx(otherCred.id));

    expect(response.status).toBe(404);
  });
});
