import { parseDashboard, serializeDashboard } from './local-mappers';
import type { DashboardData } from './types';

const payload: DashboardData = {
  vehicleCount: 2,
  monthlyFuelSpendCents: 15000,
  totalOwnershipCostCents: 200000,
  costBreakdown: { fuelCents: 15000, maintenanceCents: 5000, purchaseCents: 180000 },
  upcomingRenewals: [
    {
      vehicleId: 'veh-1',
      title: 'Insurance',
      expiryDate: '2024-12-01',
      docType: 'insurance',
      vehicleLabel: 'Hilux',
      daysRemaining: 30,
      status: 'soon',
    },
  ],
  recentActivity: [
    {
      type: 'fuel',
      vehicleId: 'veh-1',
      vehicleLabel: 'Hilux',
      date: '2024-05-01',
      amountCents: 12345,
      label: 'Fuel',
      liters: 42.5,
      isFullTank: true,
    },
  ],
};

describe('dashboard local-mappers', () => {
  it('round-trips a full dashboard payload through JSON, preserving integer cents', () => {
    const serialized = serializeDashboard(payload);
    const parsed = parseDashboard(serialized);

    expect(parsed).toEqual(payload);
    expect(Number.isInteger(parsed?.monthlyFuelSpendCents)).toBe(true);
    expect(Number.isInteger(parsed?.costBreakdown.fuelCents)).toBe(true);
  });

  it('returns null for malformed JSON instead of throwing', () => {
    expect(parseDashboard('{not valid json')).toBeNull();
  });
});
