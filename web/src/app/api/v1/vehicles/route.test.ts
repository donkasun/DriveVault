import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { documents, users, vehicles } from '@/server/db/schema';
import { AppError } from '@/server/lib/errors';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-veh-route-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'veh@example.com',
      displayName: overrides.displayName ?? null,
      photoUrl: overrides.photoUrl ?? null,
      currency: overrides.currency ?? 'LKR',
      distanceUnit: overrides.distanceUnit ?? 'km',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
    })
    .returning();
  return row;
}

async function seedVehicle(
  userId: string,
  overrides: Partial<typeof vehicles.$inferInsert> = {},
) {
  const [row] = await db
    .insert(vehicles)
    .values({
      userId,
      make: overrides.make ?? 'Toyota',
      model: overrides.model ?? 'Corolla',
      year: overrides.year ?? 2021,
      ...overrides,
    })
    .returning();
  return row;
}

async function seedDoc(
  vehicleId: string,
  expiryDate: string | null,
) {
  const [row] = await db
    .insert(documents)
    .values({
      vehicleId,
      docType: 'insurance',
      title: 'Insurance',
      storageUrl: 'https://example.com/doc.pdf',
      expiryDate,
    })
    .returning();
  return row;
}

function listRequest(): NextRequest {
  return new NextRequest('http://localhost/api/v1/vehicles', { method: 'GET' });
}

function createRequest(body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/v1/vehicles', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function daysFromToday(delta: number): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + delta);
  return d.toISOString().slice(0, 10);
}

describe('GET/POST /api/v1/vehicles', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET returns empty list when user has no vehicles', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const response = await GET(listRequest());

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual([]);
  });

  it('GET returns vehicles newest-first', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const older = await seedVehicle(owner.id, { make: 'Older' });
    // Ensure distinct created_at ordering
    await new Promise((r) => setTimeout(r, 20));
    const newer = await seedVehicle(owner.id, { make: 'Newer' });

    const { GET } = await import('./route');
    const response = await GET(listRequest());

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.map((v: { id: string }) => v.id)).toEqual([newer.id, older.id]);
  });

  it('POST creates a vehicle with LKR currency and docsStatus none', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest({
        make: 'Toyota',
        model: 'Hilux',
        year: 2021,
        registrationNumber: 'ABC-1234',
        purchasePriceCents: 3500000,
        currentMileage: 48000,
        vehicleType: 'pickup',
        currency: 'EUR',
      }),
    );

    expect(response.status).toBe(201);
    const body = await response.json();
    expect(body).toMatchObject({
      make: 'Toyota',
      model: 'Hilux',
      year: 2021,
      registrationNumber: 'ABC-1234',
      currency: 'LKR',
      currentMileage: 48000,
      vehicleType: 'pickup',
      docsStatus: { state: 'none', needsActionCount: 0 },
    });
    expect(typeof body.id).toBe('string');
    expect(typeof body.createdAt).toBe('string');
    expect(typeof body.updatedAt).toBe('string');
  });

  it('POST with missing make returns 400', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { POST } = await import('./route');
    const response = await POST(createRequest({ model: 'Hilux' }));

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body).toHaveProperty('detail');
  });

  it('docsStatus is none when docs lack expiryDate', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedDoc(vehicle.id, null);

    const { GET } = await import('./route');
    const response = await GET(listRequest());
    const body = await response.json();
    expect(body[0].docsStatus).toEqual({ state: 'none', needsActionCount: 0 });
  });

  it('docsStatus is valid when all expiry docs are >30 days away', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { make: 'Honda' });
    await seedDoc(vehicle.id, daysFromToday(60));
    await seedDoc(vehicle.id, daysFromToday(45));

    const { GET } = await import('./route');
    const response = await GET(listRequest());
    const body = await response.json();
    expect(body[0].docsStatus).toEqual({ state: 'valid', needsActionCount: 0 });
  });

  it('docsStatus is needs_action with correct count for soon/overdue', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { make: 'Suzuki' });
    await seedDoc(vehicle.id, daysFromToday(-5)); // overdue
    await seedDoc(vehicle.id, daysFromToday(10)); // soon
    await seedDoc(vehicle.id, daysFromToday(60)); // ok

    const { GET } = await import('./route');
    const response = await GET(listRequest());
    const body = await response.json();
    expect(body[0].docsStatus).toEqual({ state: 'needs_action', needsActionCount: 2 });
  });

  it('returns 401 without auth', async () => {
    requireUser.mockRejectedValue(new AppError(401, 'Missing authorization token'));

    const { GET } = await import('./route');
    const response = await GET(listRequest());

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({
      detail: 'Missing authorization token',
    });
  });
});

// Keep cascade helpers available for [id] tests via shared cleanup pattern —
// also verify list does not leak other users' vehicles.
describe('vehicles ownership isolation on list', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET list excludes other users vehicles', async () => {
    const owner = await seedUser({ email: 'owner@example.com' });
    const other = await seedUser({ email: 'other@example.com' });
    const mine = await seedVehicle(owner.id, { make: 'Mine' });
    await seedVehicle(other.id, { make: 'Theirs' });
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const response = await GET(listRequest());
    const body = await response.json();
    expect(body.map((v: { id: string }) => v.id)).toEqual([mine.id]);
  });
});
