import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { users } from '@/server/db/schema';
import { AppError } from '@/server/lib/errors';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-me-route-';

async function seedUser(overrides: Partial<typeof users.$inferInsert> = {}): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'me@example.com',
      displayName: overrides.displayName ?? null,
      photoUrl: overrides.photoUrl ?? null,
      currency: overrides.currency ?? 'LKR',
      distanceUnit: overrides.distanceUnit ?? 'km',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
    })
    .returning();
  return row;
}

function request(method: 'GET' | 'PATCH', body?: unknown): NextRequest {
  return new NextRequest('http://localhost/api/v1/me', {
    method,
    headers: body !== undefined ? { 'content-type': 'application/json' } : undefined,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
}

describe('GET/PATCH /api/v1/me', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET returns profile fields for the authenticated user', async () => {
    const seeded = await seedUser({
      email: 'profile@example.com',
      displayName: 'Kasun',
    });
    requireUser.mockResolvedValue(seeded);

    const { GET } = await import('./route');
    const response = await GET(request('GET'));

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toMatchObject({
      id: seeded.id,
      firebaseUid: seeded.firebaseUid,
      email: 'profile@example.com',
      displayName: 'Kasun',
      photoUrl: null,
      currency: 'LKR',
      distanceUnit: 'km',
      renewalRemindersEnabled: true,
    });
    expect(typeof body.createdAt).toBe('string');
    expect(body).not.toHaveProperty('updatedAt');
  });

  it('PATCH updates displayName, distanceUnit, and renewalRemindersEnabled', async () => {
    const seeded = await seedUser();
    requireUser.mockResolvedValue(seeded);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      request('PATCH', {
        displayName: 'Updated Name',
        distanceUnit: 'mi',
        renewalRemindersEnabled: false,
      }),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.displayName).toBe('Updated Name');
    expect(body.distanceUnit).toBe('mi');
    expect(body.renewalRemindersEnabled).toBe(false);

    const [row] = await db.select().from(users).where(eq(users.id, seeded.id)).limit(1);
    expect(row.displayName).toBe('Updated Name');
    expect(row.distanceUnit).toBe('mi');
    expect(row.renewalRemindersEnabled).toBe(false);
  });

  it('PATCH coerces any valid currency to LKR', async () => {
    const seeded = await seedUser();
    requireUser.mockResolvedValue(seeded);

    const { PATCH } = await import('./route');
    const response = await PATCH(request('PATCH', { currency: 'EUR' }));

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.currency).toBe('LKR');

    const [row] = await db.select().from(users).where(eq(users.id, seeded.id)).limit(1);
    expect(row.currency.trim()).toBe('LKR');
  });

  it('PATCH with invalid distanceUnit returns 400', async () => {
    const seeded = await seedUser();
    requireUser.mockResolvedValue(seeded);

    const { PATCH } = await import('./route');
    const response = await PATCH(request('PATCH', { distanceUnit: 'miles' }));

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body).toHaveProperty('detail');
  });

  it('PATCH with invalid currency returns 400', async () => {
    const seeded = await seedUser();
    requireUser.mockResolvedValue(seeded);

    const { PATCH } = await import('./route');
    const response = await PATCH(request('PATCH', { currency: 'EURO' }));

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body).toHaveProperty('detail');
  });

  it('returns 401 without auth', async () => {
    requireUser.mockRejectedValue(new AppError(401, 'Missing authorization token'));

    const { GET } = await import('./route');
    const response = await GET(request('GET'));

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({ detail: 'Missing authorization token' });
  });
});
