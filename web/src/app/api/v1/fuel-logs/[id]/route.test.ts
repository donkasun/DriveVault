import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { fuelLogs, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-fuel-id-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'fuel-id@example.com',
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

async function seedFuelLog(
  vehicleId: string,
  logDate: string,
  odometer: number,
  liters = '40.000',
  priceCents = 6000,
  isFullTank = true,
) {
  const [row] = await db
    .insert(fuelLogs)
    .values({
      vehicleId,
      date: logDate,
      liters,
      priceCents,
      odometer,
      isFullTank,
    })
    .returning();
  return row;
}

function ctx(id: string) {
  return { params: Promise.resolve({ id }) };
}

function patchRequest(id: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/fuel-logs/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function deleteRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/fuel-logs/${id}`, { method: 'DELETE' });
}

describe('PATCH/DELETE /api/v1/fuel-logs/[id]', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('PATCH updates notes and isFullTank', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const log = await seedFuelLog(vehicle.id, '2026-06-01', 48500);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(log.id, { notes: 'Updated note', isFullTank: false }),
      ctx(log.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.notes).toBe('Updated note');
    expect(body.isFullTank).toBe(false);
  });

  it('PATCH returns 404 for other user fuel log', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherLog = await seedFuelLog(otherVehicle.id, '2026-06-02', 10000);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(otherLog.id, { notes: 'not mine' }),
      ctx(otherLog.id),
    );

    expect(response.status).toBe(404);
  });

  it('DELETE removes log and returns 204', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const oldLog = await seedFuelLog(vehicle.id, '2026-05-01', 48000);
    await seedFuelLog(vehicle.id, '2026-06-01', 48500);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(oldLog.id), ctx(oldLog.id));

    expect(response.status).toBe(204);
    const remaining = await db.select().from(fuelLogs).where(eq(fuelLogs.id, oldLog.id));
    expect(remaining).toHaveLength(0);
  });

  it('DELETE latest log reverts currentMileage to second-to-last', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 48000);
    const latest = await seedFuelLog(vehicle.id, '2026-06-01', 49000);
    await db
      .update(vehicles)
      .set({ currentMileage: 49000 })
      .where(eq(vehicles.id, vehicle.id));

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(latest.id), ctx(latest.id));

    expect(response.status).toBe(204);
    const [refreshed] = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, vehicle.id));
    expect(refreshed.currentMileage).toBe(48000);
  });

  it('DELETE only log sets currentMileage to null', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const onlyLog = await seedFuelLog(vehicle.id, '2026-06-01', 50000);
    await db
      .update(vehicles)
      .set({ currentMileage: 50000 })
      .where(eq(vehicles.id, vehicle.id));

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(onlyLog.id), ctx(onlyLog.id));

    expect(response.status).toBe(204);
    const [refreshed] = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, vehicle.id));
    expect(refreshed.currentMileage).toBeNull();
  });

  it('DELETE returns 404 for other user fuel log', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other2@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherLog = await seedFuelLog(otherVehicle.id, '2026-06-02', 10000);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(otherLog.id), ctx(otherLog.id));

    expect(response.status).toBe(404);
  });
});
