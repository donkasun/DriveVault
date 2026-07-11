import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { maintenanceRecords, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-maint-list-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'maint@example.com',
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

/** Port of backend/tests/test_maintenance_resources.py::_create_maintenance_record */
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

function listRequest(vehicleId: string, query = ''): NextRequest {
  return new NextRequest(
    `http://localhost/api/v1/vehicles/${vehicleId}/maintenance${query}`,
    { method: 'GET' },
  );
}

function createRequest(vehicleId: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${vehicleId}/maintenance`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('GET/POST /api/v1/vehicles/[id]/maintenance', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET filters by category/from/to and returns newest first', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const oilChange = await seedMaintenance(
      vehicle.id,
      '2026-05-20',
      'Oil Change',
      'maintenance',
    );
    await seedMaintenance(vehicle.id, '2026-04-15', 'Tint', 'upgrade');

    const { GET } = await import('./route');
    const response = await GET(
      listRequest(vehicle.id, '?category=maintenance&from=2026-05-01&to=2026-05-31'),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.map((r: { id: string }) => r.id)).toEqual([oilChange.id]);
  });

  it('POST creates with LKR, source manual, aiExtractionId null', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-01',
        odometer: 49000,
        serviceType: 'Brake Pads',
        category: 'repair',
        costCents: 42000,
        currency: 'USD',
        workshop: 'City Auto',
        notes: 'Front pads',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    const created = await response.json();
    expect(created.vehicleId).toBe(vehicle.id);
    expect(created.serviceType).toBe('Brake Pads');
    expect(created.costCents).toBe(42000);
    expect(created.currency).toBe('LKR');
    expect(created.source).toBe('manual');
    expect(created.aiExtractionId).toBeNull();
  });

  it('POST defaults costCents to 0 when omitted', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-02',
        serviceType: 'Inspection',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    expect((await response.json()).costCents).toBe(0);
  });

  it('POST forces LKR even if client sends USD', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        date: '2026-06-10',
        serviceType: 'Oil Change',
        currency: 'USD',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    expect((await response.json()).currency).toBe('LKR');
  });

  it('POST forces LKR even when user preference is EUR', async () => {
    const owner = await seedUser({ currency: 'EUR' });
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const omitted = await POST(
      createRequest(vehicle.id, {
        date: '2026-05-20',
        serviceType: 'Oil Change',
        costCents: 6500,
      }),
      ctx(vehicle.id),
    );
    expect(omitted.status).toBe(201);
    expect((await omitted.json()).currency).toBe('LKR');

    const explicit = await POST(
      createRequest(vehicle.id, {
        date: '2026-05-21',
        serviceType: 'Brake Service',
        currency: 'GBP',
      }),
      ctx(vehicle.id),
    );
    expect(explicit.status).toBe(201);
    expect((await explicit.json()).currency).toBe('LKR');
  });

  it('POST uses client-supplied id', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const clientId = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        id: clientId,
        date: '2026-07-01',
        serviceType: 'Tire Rotation',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    expect((await response.json()).id).toBe(clientId);
  });

  it('POST rejects missing serviceType', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, { date: '2026-06-20' }),
      ctx(vehicle.id),
    );

    // Zod → 400 (Python/FastAPI returns 422 — intentional drift).
    expect(response.status).toBe(400);
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

  it('POST returns 404 for other user vehicle', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other2@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(otherVehicle.id, {
        date: '2026-06-01',
        serviceType: 'Oil Change',
      }),
      ctx(otherVehicle.id),
    );

    expect(response.status).toBe(404);
  });
});
