import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { documents, fuelLogs, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-veh-id-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'veh-id@example.com',
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

function ctx(id: string) {
  return { params: Promise.resolve({ id }) };
}

function getRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${id}`, { method: 'GET' });
}

function patchRequest(id: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function deleteRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${id}`, { method: 'DELETE' });
}

function daysFromToday(delta: number): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + delta);
  return d.toISOString().slice(0, 10);
}

describe('GET/PATCH/DELETE /api/v1/vehicles/[id]', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET returns vehicle with docsStatus', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { make: 'Mazda', model: '3' });
    await db.insert(documents).values({
      vehicleId: vehicle.id,
      docType: 'insurance',
      title: 'Insurance',
      storageUrl: 'https://example.com/doc.pdf',
      expiryDate: daysFromToday(20),
    });

    const { GET } = await import('./route');
    const response = await GET(getRequest(vehicle.id), ctx(vehicle.id));

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.make).toBe('Mazda');
    expect(body.docsStatus).toEqual({ state: 'needs_action', needsActionCount: 1 });
  });

  it('PATCH applies partial update', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { currentMileage: 48000 });

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(vehicle.id, {
        currentMileage: 49000,
        photoPublicId: 'vehicles/photo-1',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.currentMileage).toBe(49000);
    expect(body.photoPublicId).toBe('vehicles/photo-1');
    expect(body.make).toBe('Toyota');
  });

  it('PATCH coerces currency to LKR', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(vehicle.id, { currency: 'EUR' }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.currency).toBe('LKR');
  });

  it('DELETE returns 204 and removes the vehicle', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(vehicle.id), ctx(vehicle.id));

    expect(response.status).toBe(204);
    expect(await response.text()).toBe('');

    const remaining = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, vehicle.id));
    expect(remaining).toHaveLength(0);
  });

  it('DELETE cascades nested fuel_logs and documents', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const [fuelLog] = await db
      .insert(fuelLogs)
      .values({
        vehicleId: vehicle.id,
        date: '2026-06-01',
        liters: '40.000',
        priceCents: 7000,
        odometer: 48200,
      })
      .returning();

    const [doc] = await db
      .insert(documents)
      .values({
        vehicleId: vehicle.id,
        docType: 'insurance',
        title: 'Insurance',
        storageUrl: 'https://example.com/doc.pdf',
        expiryDate: daysFromToday(60),
      })
      .returning();

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(vehicle.id), ctx(vehicle.id));
    expect(response.status).toBe(204);

    const logs = await db.select().from(fuelLogs).where(eq(fuelLogs.id, fuelLog.id));
    const docs = await db.select().from(documents).where(eq(documents.id, doc.id));
    expect(logs).toHaveLength(0);
    expect(docs).toHaveLength(0);
  });

  it('GET returns 404 for another users vehicle', async () => {
    const owner = await seedUser({ email: 'owner@example.com' });
    const other = await seedUser({ email: 'other@example.com' });
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const response = await GET(getRequest(otherVehicle.id), ctx(otherVehicle.id));

    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({ detail: 'Vehicle not found' });
  });

  it('PATCH returns 404 for another users vehicle', async () => {
    const owner = await seedUser({ email: 'owner2@example.com' });
    const other = await seedUser({ email: 'other2@example.com' });
    const otherVehicle = await seedVehicle(other.id);
    requireUser.mockResolvedValue(owner);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(otherVehicle.id, { currentMileage: 1 }),
      ctx(otherVehicle.id),
    );

    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({ detail: 'Vehicle not found' });
  });

  it('DELETE returns 404 for another users vehicle', async () => {
    const owner = await seedUser({ email: 'owner3@example.com' });
    const other = await seedUser({ email: 'other3@example.com' });
    const otherVehicle = await seedVehicle(other.id);
    requireUser.mockResolvedValue(owner);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(otherVehicle.id), ctx(otherVehicle.id));

    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({ detail: 'Vehicle not found' });

    const stillThere = await db
      .select()
      .from(vehicles)
      .where(eq(vehicles.id, otherVehicle.id));
    expect(stillThere).toHaveLength(1);
  });
});
