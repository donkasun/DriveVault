import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { maintenanceRecords, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-maint-id-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'maint-id@example.com',
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
      model: overrides.model ?? 'Hilux',
      year: overrides.year ?? 2020,
      ...overrides,
    })
    .returning();
  return row;
}

async function seedMaintenance(
  vehicleId: string,
  recordDate: string,
  serviceType = 'Oil Change',
  category: string | null = 'maintenance',
) {
  const [row] = await db
    .insert(maintenanceRecords)
    .values({
      vehicleId,
      date: recordDate,
      odometer: 48000,
      serviceType,
      category,
      costCents: 6500,
      workshop: 'City Auto',
      notes: '5W-30 synthetic',
      source: 'manual',
    })
    .returning();
  return row;
}

function ctx(id: string) {
  return { params: Promise.resolve({ id }) };
}

function getRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/maintenance/${id}`, { method: 'GET' });
}

function patchRequest(id: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/maintenance/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function deleteRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/maintenance/${id}`, {
    method: 'DELETE',
  });
}

describe('GET/PATCH/DELETE /api/v1/maintenance/[id]', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET returns owned record', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const record = await seedMaintenance(vehicle.id, '2026-05-20', 'Oil Change', 'repair');

    const { GET } = await import('./route');
    const response = await GET(getRequest(record.id), ctx(record.id));

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.category).toBe('repair');
    expect(body.serviceType).toBe('Oil Change');
    expect(body.source).toBe('manual');
  });

  it('GET returns 404 for other user record', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherRecord = await seedMaintenance(otherVehicle.id, '2026-05-21');

    const { GET } = await import('./route');
    const response = await GET(getRequest(otherRecord.id), ctx(otherRecord.id));

    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({
      detail: 'Maintenance record not found',
    });
  });

  it('PATCH updates costCents and notes', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const record = await seedMaintenance(vehicle.id, '2026-06-01');

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(record.id, { costCents: 43000, notes: 'Front ceramic pads' }),
      ctx(record.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.costCents).toBe(43000);
    expect(body.notes).toBe('Front ceramic pads');
  });

  it('PATCH does not re-lock currency (Python parity)', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const record = await seedMaintenance(vehicle.id, '2026-06-01');

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(record.id, { currency: 'USD' }),
      ctx(record.id),
    );

    expect(response.status).toBe(200);
    expect((await response.json()).currency).toBe('USD');
  });

  it('PATCH returns 404 for other user record', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other2@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherRecord = await seedMaintenance(otherVehicle.id, '2026-06-02');

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(otherRecord.id, { notes: 'not mine' }),
      ctx(otherRecord.id),
    );

    expect(response.status).toBe(404);
  });

  it('DELETE removes record and returns 204', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const record = await seedMaintenance(vehicle.id, '2026-06-01');

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(record.id), ctx(record.id));

    expect(response.status).toBe(204);
    const remaining = await db
      .select()
      .from(maintenanceRecords)
      .where(eq(maintenanceRecords.id, record.id));
    expect(remaining).toHaveLength(0);
  });

  it('DELETE returns 404 for other user record', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other3@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherRecord = await seedMaintenance(otherVehicle.id, '2026-06-02');

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(otherRecord.id), ctx(otherRecord.id));

    expect(response.status).toBe(404);
  });
});
