import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { fuelLogs, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-fuel-logs-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'fuel@example.com',
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

/** Port of backend/tests/test_fuel_resources.py::_create_fuel_log */
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

function listRequest(vehicleId: string, query = ''): NextRequest {
  return new NextRequest(
    `http://localhost/api/v1/vehicles/${vehicleId}/fuel-logs${query}`,
    { method: 'GET' },
  );
}

function createRequest(vehicleId: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${vehicleId}/fuel-logs`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('GET/POST /api/v1/vehicles/[id]/fuel-logs', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET filters by from/to and returns newest first', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 48000);
    const newLog = await seedFuelLog(vehicle.id, '2026-06-01', 48500);

    const { GET } = await import('./route');
    const response = await GET(
      listRequest(vehicle.id, '?from=2026-06-01&to=2026-06-30'),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.map((l: { id: string }) => l.id)).toEqual([newLog.id]);
  });

  it('POST creates a fuel log with LKR and syncs currentMileage', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 48000);
    await seedFuelLog(vehicle.id, '2026-06-01', 48500);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-15',
        liters: 45.5,
        priceCents: 7800,
        odometer: 49000,
        isFullTank: true,
        notes: 'Highway trip',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    const created = await response.json();
    expect(created.vehicleId).toBe(vehicle.id);
    expect(created.priceCents).toBe(7800);
    expect(created.currency).toBe('LKR');

    const [refreshed] = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, vehicle.id));
    expect(refreshed.currentMileage).toBe(49000);
  });

  it('POST rejects liters <= 0', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-20',
        liters: 0,
        priceCents: 1000,
        odometer: 49100,
      }),
      ctx(vehicle.id),
    );

    // Zod → 400 (Python/FastAPI returns 422 — intentional drift).
    expect(response.status).toBe(400);
  });

  it('POST first log accepts any odometer and syncs mileage', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-01',
        liters: 40.0,
        priceCents: 6000,
        odometer: 50000,
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    const [refreshed] = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, vehicle.id));
    expect(refreshed.currentMileage).toBe(50000);
  });

  it('POST odometer above max is accepted', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 48000);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-01',
        liters: 45.0,
        priceCents: 7000,
        odometer: 48001,
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    const [refreshed] = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, vehicle.id));
    expect(refreshed.currentMileage).toBe(48001);
  });

  it('POST odometer equal to max returns 400 with exact message', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 48500);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-01',
        liters: 45.0,
        priceCents: 7000,
        odometer: 48500,
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(400);
    await expect(response.json()).resolves.toEqual({
      detail: 'Odometer must be greater than the latest reading (48500 km)',
    });
  });

  it('POST odometer below max returns 400 with exact message', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 48500);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-01',
        liters: 45.0,
        priceCents: 7000,
        odometer: 48000,
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(400);
    await expect(response.json()).resolves.toEqual({
      detail: 'Odometer must be greater than the latest reading (48500 km)',
    });
  });

  it('POST forces LKR even if client sends USD', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-10',
        liters: 40.0,
        priceCents: 7500,
        odometer: 51000,
        currency: 'USD',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    expect((await response.json()).currency).toBe('LKR');
  });

  it('POST uses client-supplied id', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const clientId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        id: clientId,
        date: '2026-07-01',
        liters: 42.0,
        priceCents: 6300,
        odometer: 52000,
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    expect((await response.json()).id).toBe(clientId);
  });

  it('GET returns 404 for other user vehicle', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });

    const { GET } = await import('./route');
    const response = await GET(listRequest(otherVehicle.id), ctx(otherVehicle.id));

    expect(response.status).toBe(404);
  });
});
