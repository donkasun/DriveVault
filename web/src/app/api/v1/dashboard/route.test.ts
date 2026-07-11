import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import {
  documents,
  fuelLogs,
  maintenanceRecords,
  userDocuments,
  users,
  vehicles,
} from '@/server/db/schema';
import { addUtcDays } from '@/server/services/dashboard-renewals';
import { utcMonthBounds, utcToday } from '@/server/services/dashboard';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-dashboard-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid =
    overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'dash@example.com',
      displayName: overrides.displayName ?? 'Dash',
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
      purchasePriceCents: overrides.purchasePriceCents ?? 3_500_000,
      currentMileage: overrides.currentMileage ?? 48000,
      vehicleType: overrides.vehicleType ?? 'pickup',
      ...overrides,
    })
    .returning();
  return row;
}

function dashboardRequest(): NextRequest {
  return new NextRequest('http://localhost/api/v1/dashboard', { method: 'GET' });
}

describe('GET /api/v1/dashboard', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('returns all-zero empty state when user has no vehicles', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);

    const { GET } = await import('./route');
    const response = await GET(dashboardRequest());

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({
      vehicleCount: 0,
      monthlyFuelSpendCents: 0,
      totalOwnershipCostCents: 0,
      costBreakdown: {
        fuelCents: 0,
        maintenanceCents: 0,
        purchaseCents: 0,
      },
      upcomingRenewals: [],
      recentActivity: [],
    });
  });

  it('aggregates costs across fuel, maintenance, and purchase', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { purchasePriceCents: 3_500_000 });
    const today = utcToday();

    await db.insert(fuelLogs).values({
      vehicleId: vehicle.id,
      date: today,
      liters: '45.000',
      priceCents: 7020,
      odometer: 48100,
      isFullTank: true,
    });
    await db.insert(maintenanceRecords).values({
      vehicleId: vehicle.id,
      date: addUtcDays(today, -10),
      serviceType: 'Oil Change',
      costCents: 320_000,
      odometer: 47800,
      workshop: 'City Auto',
    });
    await db.insert(documents).values({
      vehicleId: vehicle.id,
      docType: 'insurance',
      title: 'Insurance Policy',
      storageUrl: 'https://example.com/doc.pdf',
      expiryDate: addUtcDays(today, 30),
      issueDate: '2026-01-01',
    });

    const { GET } = await import('./route');
    const response = await GET(dashboardRequest());
    expect(response.status).toBe(200);
    const data = await response.json();

    expect(data.vehicleCount).toBe(1);
    expect(data.monthlyFuelSpendCents).toBe(7020);
    expect(data.totalOwnershipCostCents).toBe(7020 + 320_000 + 3_500_000);
    expect(data.costBreakdown).toEqual({
      fuelCents: 7020,
      maintenanceCents: 320_000,
      purchaseCents: 3_500_000,
    });
    expect(data.upcomingRenewals).toHaveLength(1);
    expect(data.upcomingRenewals[0].title).toBe('Insurance Policy');
    expect(data.upcomingRenewals[0].vehicleLabel).toBe('2020 Toyota Hilux');
  });

  it('counts monthly fuel only for the current UTC calendar month', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { purchasePriceCents: 0 });
    const today = utcToday();
    const { monthStart } = utcMonthBounds(today);
    const prevMonthLastDay = addUtcDays(monthStart, -1);

    await db.insert(fuelLogs).values([
      {
        vehicleId: vehicle.id,
        date: today,
        liters: '40.000',
        priceCents: 5000,
        odometer: 100,
        isFullTank: true,
      },
      {
        vehicleId: vehicle.id,
        date: prevMonthLastDay,
        liters: '40.000',
        priceCents: 9999,
        odometer: 50,
        isFullTank: true,
      },
    ]);

    const { GET } = await import('./route');
    const response = await GET(dashboardRequest());
    const data = await response.json();

    expect(data.monthlyFuelSpendCents).toBe(5000);
    expect(data.costBreakdown.fuelCents).toBe(5000 + 9999);
  });

  it('merges vehicle docs and driving credentials into upcomingRenewals', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { purchasePriceCents: 0 });
    const today = utcToday();

    await db.insert(documents).values({
      vehicleId: vehicle.id,
      docType: 'registration',
      title: 'Vehicle Registration',
      storageUrl: 'https://example.com/reg.pdf',
      expiryDate: addUtcDays(today, -15),
    });
    await db.insert(userDocuments).values({
      userId: owner.id,
      docType: 'license',
      expiryDate: addUtcDays(today, 15),
    });
    // Far-future doc must be excluded (>90d)
    await db.insert(documents).values({
      vehicleId: vehicle.id,
      docType: 'warranty',
      title: 'Warranty',
      storageUrl: 'https://example.com/w.pdf',
      expiryDate: addUtcDays(today, 120),
    });

    const { GET } = await import('./route');
    const response = await GET(dashboardRequest());
    const data = await response.json();

    expect(data.upcomingRenewals).toHaveLength(2);
    // Sorted ascending by expiryDate — overdue first
    expect(data.upcomingRenewals[0].status).toBe('overdue');
    expect(data.upcomingRenewals[0].docType).toBe('registration');
    expect(data.upcomingRenewals[0].vehicleId).toBe(vehicle.id);
    expect(data.upcomingRenewals[0].daysRemaining).toBeLessThan(0);

    expect(data.upcomingRenewals[1].vehicleId).toBeNull();
    expect(data.upcomingRenewals[1].vehicleLabel).toBeNull();
    expect(data.upcomingRenewals[1].docType).toBe('license');
    expect(data.upcomingRenewals[1].title).toBe("Driver's License");
    expect(data.upcomingRenewals[1].status).toBe('soon');
  });

  it('caps recentActivity at 10, newest first, with fuel/maintenance/document types', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id, { purchasePriceCents: 0 });
    const today = utcToday();

    for (let i = 0; i < 5; i++) {
      await db.insert(fuelLogs).values({
        vehicleId: vehicle.id,
        date: addUtcDays(today, -(i * 3)),
        liters: String(10 + i),
        priceCents: 1500 + i * 100,
        odometer: 1000 + i * 10,
        isFullTank: true,
      });
    }
    for (let i = 0; i < 4; i++) {
      await db.insert(maintenanceRecords).values({
        vehicleId: vehicle.id,
        date: addUtcDays(today, -(i * 2 + 1)),
        serviceType: `Service ${i}`,
        costCents: 5000 + i * 100,
      });
    }
    for (let i = 0; i < 3; i++) {
      await db.insert(documents).values({
        vehicleId: vehicle.id,
        docType: 'insurance',
        title: `Doc ${i}`,
        storageUrl: 'https://example.com/doc.pdf',
        issueDate: addUtcDays(today, -(i * 5 + 2)),
      });
    }

    const { GET } = await import('./route');
    const response = await GET(dashboardRequest());
    const data = await response.json();

    expect(data.recentActivity.length).toBeLessThanOrEqual(10);
    expect(data.recentActivity.length).toBeGreaterThan(0);
    const dates = data.recentActivity.map((a: { date: string }) => a.date);
    expect(dates).toEqual([...dates].sort().reverse());

    const types = new Set(data.recentActivity.map((a: { type: string }) => a.type));
    expect(types.has('fuel')).toBe(true);
    expect(types.has('maintenance')).toBe(true);

    for (const item of data.recentActivity) {
      for (const key of [
        'type',
        'vehicleId',
        'vehicleLabel',
        'date',
        'amountCents',
        'label',
      ]) {
        expect(item).toHaveProperty(key);
      }
    }
  });

  it('isolates data to the authenticated user', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other@example.com' });
    requireUser.mockResolvedValue(owner);

    const ownerVehicle = await seedVehicle(owner.id, {
      make: 'Toyota',
      purchasePriceCents: 0,
    });
    const otherVehicle = await seedVehicle(other.id, {
      make: 'Honda',
      purchasePriceCents: 0,
    });
    const today = utcToday();

    await db.insert(fuelLogs).values([
      {
        vehicleId: ownerVehicle.id,
        date: today,
        liters: '50.000',
        priceCents: 7500,
        odometer: 100,
        isFullTank: true,
      },
      {
        vehicleId: otherVehicle.id,
        date: today,
        liters: '40.000',
        priceCents: 6000,
        odometer: 100,
        isFullTank: true,
      },
    ]);

    const { GET } = await import('./route');
    const response = await GET(dashboardRequest());
    const data = await response.json();

    expect(data.vehicleCount).toBe(1);
    expect(data.monthlyFuelSpendCents).toBe(7500);
  });
});
