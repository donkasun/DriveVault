import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { fuelLogs, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-fuel-stats-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'fuel-stats@example.com',
      displayName: overrides.displayName ?? null,
      photoUrl: overrides.photoUrl ?? null,
      currency: overrides.currency ?? 'LKR',
      distanceUnit: overrides.distanceUnit ?? 'km',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
    })
    .returning();
  return row;
}

async function seedVehicle(userId: string) {
  const [row] = await db
    .insert(vehicles)
    .values({
      userId,
      make: 'Toyota',
      model: 'Hilux',
      year: 2020,
    })
    .returning();
  return row;
}

/**
 * Port of backend/tests/test_fuel_resources.py::_create_fuel_log — fixtures
 * VERBATIM so numbers match exactly.
 */
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

function statsRequest(vehicleId: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${vehicleId}/fuel-stats`, {
    method: 'GET',
  });
}

describe('GET /api/v1/vehicles/[id]/fuel-stats', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('computes exact metrics (test_b3_fuel_stats_computes_exact_metrics)', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 10000, '40.000', 6000);
    await seedFuelLog(vehicle.id, '2026-05-15', 10250, '10.000', 1500, false);
    await seedFuelLog(vehicle.id, '2026-06-01', 10500, '45.000', 7000);
    await seedFuelLog(vehicle.id, '2026-06-20', 11000, '43.000', 6900);

    const { GET } = await import('./route');
    const response = await GET(statsRequest(vehicle.id), ctx(vehicle.id));

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.avgConsumptionLPer100Km).toBe(9.8);
    expect(body.avgCostPerKmCents).toBe(15);
    expect(body.totalLiters).toBe(138.0);
    expect(body.totalSpentCents).toBe(21400);
    expect(body.monthlySpend).toEqual([
      { month: '2026-06', spentCents: 13900 },
      { month: '2026-05', spentCents: 7500 },
    ]);
  });

  it('ignores trailing partial fill (test_fuel_stats_ignores_trailing_partial_fill)', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 1000, '40.000', 6000);
    await seedFuelLog(vehicle.id, '2026-05-10', 1500, '30.000', 4500);
    await seedFuelLog(vehicle.id, '2026-05-20', 1800, '12.000', 1800, false);

    const { GET } = await import('./route');
    const body = await (
      await GET(statsRequest(vehicle.id), ctx(vehicle.id))
    ).json();

    expect(body.avgConsumptionLPer100Km).toBe(6.0);
    expect(body.avgCostPerKmCents).toBe(9);
    expect(body.totalLiters).toBe(82.0);
    expect(body.totalSpentCents).toBe(12300);
  });

  it('partial fill counts toward next full interval', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 1000, '40.000', 6000);
    await seedFuelLog(vehicle.id, '2026-05-10', 1300, '15.000', 2250, false);
    await seedFuelLog(vehicle.id, '2026-05-20', 1600, '25.000', 3750);

    const { GET } = await import('./route');
    const body = await (
      await GET(statsRequest(vehicle.id), ctx(vehicle.id))
    ).json();

    // 40/600*100 = 6.66.. -> 6.7
    expect(body.avgConsumptionLPer100Km).toBe(6.7);
    expect(body.avgCostPerKmCents).toBe(10);
  });

  it('single full log has no average', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 1000, '40.000', 6000);

    const { GET } = await import('./route');
    const body = await (
      await GET(statsRequest(vehicle.id), ctx(vehicle.id))
    ).json();

    expect(body.avgConsumptionLPer100Km).toBeNull();
    expect(body.avgCostPerKmCents).toBeNull();
    expect(body.totalLiters).toBe(40.0);
  });

  it('skips non-positive distance', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 1000, '40.000', 6000);
    await seedFuelLog(vehicle.id, '2026-05-10', 800, '20.000', 3000);

    const { GET } = await import('./route');
    const body = await (
      await GET(statsRequest(vehicle.id), ctx(vehicle.id))
    ).json();

    expect(body.avgConsumptionLPer100Km).toBeNull();
    expect(body.totalLiters).toBe(60.0);
  });

  it('ignores leading partial before first full tank', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    await seedFuelLog(vehicle.id, '2026-05-01', 1000, '20.000', 3000, false);
    await seedFuelLog(vehicle.id, '2026-05-10', 1450, '35.000', 5250);
    await seedFuelLog(vehicle.id, '2026-05-25', 1950, '40.000', 6000);

    const { GET } = await import('./route');
    const body = await (
      await GET(statsRequest(vehicle.id), ctx(vehicle.id))
    ).json();

    expect(body.avgConsumptionLPer100Km).toBe(8.0);
    expect(body.avgCostPerKmCents).toBe(12);
  });

  it('returns 404 for other user vehicle', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other-stats@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id);

    const { GET } = await import('./route');
    const response = await GET(statsRequest(otherVehicle.id), ctx(otherVehicle.id));

    expect(response.status).toBe(404);
  });
});
