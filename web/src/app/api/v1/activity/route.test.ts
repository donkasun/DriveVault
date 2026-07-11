import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import {
  documents,
  fuelLogs,
  maintenanceRecords,
  users,
  vehicles,
} from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-activity-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid =
    overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'activity@example.com',
      displayName: overrides.displayName ?? 'Activity',
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
      make: overrides.make ?? 'Honda',
      model: overrides.model ?? 'Civic',
      year: overrides.year ?? 2022,
      ...overrides,
    })
    .returning();
  return row;
}

function activityRequest(query = ''): NextRequest {
  return new NextRequest(`http://localhost/api/v1/activity${query}`, {
    method: 'GET',
  });
}

describe('GET /api/v1/activity', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('returns an empty list when user has no vehicles', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const response = await GET(activityRequest());

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual([]);
  });

  it('respects limit and returns richer activity shape', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    for (let i = 0; i < 3; i++) {
      await db.insert(fuelLogs).values({
        vehicleId: vehicle.id,
        date: `2024-01-0${i + 1}`,
        liters: '40.000',
        priceCents: 5000,
        odometer: 10000 + i * 100,
        isFullTank: true,
      });
      await db.insert(maintenanceRecords).values({
        vehicleId: vehicle.id,
        date: `2024-02-0${i + 1}`,
        serviceType: 'Oil Change',
        costCents: 3000,
      });
    }

    const { GET } = await import('./route');
    const response = await GET(activityRequest('?limit=2'));
    expect(response.status).toBe(200);
    const items = await response.json();
    expect(items.length).toBeLessThanOrEqual(2);
  });

  it('returns 400 for invalid limit', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const tooLow = await GET(activityRequest('?limit=0'));
    expect(tooLow.status).toBe(400);

    const tooHigh = await GET(activityRequest('?limit=201'));
    expect(tooHigh.status).toBe(400);

    const notInt = await GET(activityRequest('?limit=abc'));
    expect(notInt.status).toBe(400);
  });

  it('merges fuel, maintenance, and documents with type-specific fields', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    await db.insert(fuelLogs).values({
      vehicleId: vehicle.id,
      date: '2024-03-15',
      liters: '35.500',
      priceCents: 4200,
      odometer: 20000,
      isFullTank: false,
    });
    await db.insert(maintenanceRecords).values({
      vehicleId: vehicle.id,
      date: '2024-03-10',
      serviceType: 'Tyre Rotation',
      costCents: 1500,
    });
    await db.insert(documents).values({
      vehicleId: vehicle.id,
      docType: 'insurance',
      title: 'Insurance Policy',
      storageUrl: 'https://example.com/doc.pdf',
      storagePublicId: 'vehicles/documents/doc-1',
      mimeType: 'application/pdf',
      fileSizeBytes: 12345,
      issueDate: '2024-03-12',
      expiryDate: '2024-03-12',
    });

    const { GET } = await import('./route');
    const response = await GET(activityRequest());
    expect(response.status).toBe(200);
    const items = await response.json();

    expect(items.map((i: { type: string }) => i.type)).toEqual([
      'fuel',
      'document',
      'maintenance',
    ]);

    for (const item of items) {
      for (const key of [
        'type',
        'id',
        'vehicleId',
        'vehicleLabel',
        'date',
        'amountCents',
        'label',
        'createdAt',
        'currency',
      ]) {
        expect(item).toHaveProperty(key);
      }
      expect(['fuel', 'maintenance', 'document']).toContain(item.type);
    }

    const fuel = items.find((i: { type: string }) => i.type === 'fuel');
    expect(fuel.amountCents).toBe(4200);
    expect(fuel).toHaveProperty('isFullTank', false);
    expect(fuel).toHaveProperty('odometer', 20000);
    expect(fuel.liters).toBe(35.5);
    expect(fuel.vehicleLabel).toBe('2022 Honda Civic');

    const maint = items.find((i: { type: string }) => i.type === 'maintenance');
    expect(maint.amountCents).toBe(1500);
    expect(maint.label).toBe('Tyre Rotation');
    expect(maint).toHaveProperty('source');

    const doc = items.find((i: { type: string }) => i.type === 'document');
    expect(doc.amountCents).toBeNull();
    expect(doc.label).toBe('Insurance Policy');
    expect(doc.docType).toBe('insurance');
    expect(doc.title).toBe('Insurance Policy');
    expect(doc.storageUrl).toBe('https://example.com/doc.pdf');
    expect(doc.date).toBe('2024-03-12');
  });

  it('does not leak other users activity', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other-act@example.com' });
    requireUser.mockResolvedValue(owner);

    const otherVehicle = await seedVehicle(other.id, {
      make: 'BMW',
      model: 'X5',
      year: 2021,
    });
    await db.insert(fuelLogs).values({
      vehicleId: otherVehicle.id,
      date: '2024-04-01',
      liters: '50.000',
      priceCents: 9000,
      odometer: 5000,
      isFullTank: true,
    });

    const { GET } = await import('./route');
    const response = await GET(activityRequest());
    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual([]);
  });
});
