import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { users } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-cred-list-';

function utcDateOffset(days: number): string {
  const d = new Date();
  const utc = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  utc.setUTCDate(utc.getUTCDate() + days);
  return utc.toISOString().slice(0, 10);
}

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid =
    overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'cred@example.com',
      displayName: overrides.displayName ?? 'Test',
      photoUrl: overrides.photoUrl ?? null,
      currency: overrides.currency ?? 'LKR',
      distanceUnit: overrides.distanceUnit ?? 'km',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
    })
    .returning();
  return row;
}

function listRequest(): NextRequest {
  return new NextRequest('http://localhost/api/v1/me/driving-credentials', {
    method: 'GET',
  });
}

function createRequest(body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/v1/me/driving-credentials', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('GET/POST /api/v1/me/driving-credentials', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET returns empty list', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const response = await GET(listRequest());

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual([]);
  });

  it('POST creates credential and GET lists it with status ok', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { GET, POST } = await import('./route');
    const createResp = await POST(
      createRequest({
        docType: 'license',
        docNumber: 'B1234567',
        issueDate: '2020-01-01',
        expiryDate: '2030-01-01',
      }),
    );

    expect(createResp.status).toBe(201);
    const created = await createResp.json();
    expect(created.docType).toBe('license');
    expect(created.docNumber).toBe('B1234567');
    expect(created.status).toBe('ok');
    expect(created.daysUntilExpiry).toBeGreaterThan(365);

    const listResp = await GET(listRequest());
    expect(listResp.status).toBe(200);
    const list = await listResp.json();
    expect(list.map((c: { id: string }) => c.id)).toContain(created.id);
  });

  it('POST without expiryDate yields null status and daysUntilExpiry', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(createRequest({ docType: 'permit' }));

    expect(response.status).toBe(201);
    const data = await response.json();
    expect(data.expiryDate).toBeNull();
    expect(data.daysUntilExpiry).toBeNull();
    expect(data.status).toBeNull();
  });

  it('computes status overdue when expiryDate is in the past', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest({
        docType: 'license',
        expiryDate: utcDateOffset(-10),
      }),
    );

    expect(response.status).toBe(201);
    const data = await response.json();
    expect(data.status).toBe('overdue');
    expect(data.daysUntilExpiry).toBeLessThan(0);
  });

  it('computes status soon when expiryDate is within 30 days', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest({
        docType: 'license',
        expiryDate: utcDateOffset(15),
      }),
    );

    expect(response.status).toBe(201);
    const data = await response.json();
    expect(data.status).toBe('soon');
    expect(data.daysUntilExpiry).toBe(15);
  });

  it('POST rejects invalid docType with 400', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest({ docType: 'passport' }),
    );

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body.detail).toBeTruthy();
  });

  it('POST rejects missing docType with 400', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(createRequest({ docNumber: 'X' }));

    expect(response.status).toBe(400);
  });
});
