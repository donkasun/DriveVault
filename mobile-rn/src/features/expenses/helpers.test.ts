import type { FuelLog } from '@/features/fuel-logs/types';
import type { MaintenanceRecord } from '@/features/maintenance/types';
import type { Vehicle } from '@/features/vehicles/types';
import {
  expenseCategoryLabel,
  expenseDateLabel,
  expenseSubLabel,
  filterByKind,
  filterByVehicle,
  filterToCurrentMonth,
  fuelCents,
  groupExpensesByMonth,
  maintenanceCents,
  mergeExpenses,
  totalCents,
} from './helpers';
import { expenseFromFuelLog, expenseFromMaintenance, type Expense } from './types';

function fuelLog(overrides: Partial<FuelLog> = {}): FuelLog {
  return {
    id: 'f1',
    vehicleId: 'v1',
    date: '2026-07-01',
    liters: 10,
    priceCents: 5000,
    currency: 'LKR',
    odometer: 1000,
    isFullTank: true,
    notes: null,
    createdAt: '2026-07-01T00:00:00Z',
    updatedAt: '2026-07-01T00:00:00Z',
    ...overrides,
  };
}

function maintenanceRecord(overrides: Partial<MaintenanceRecord> = {}): MaintenanceRecord {
  return {
    id: 'm1',
    vehicleId: 'v1',
    date: '2026-07-05',
    odometer: 1000,
    serviceType: 'Oil change',
    category: null,
    costCents: 3000,
    currency: 'LKR',
    workshop: null,
    notes: null,
    source: 'manual',
    aiExtractionId: null,
    createdAt: '2026-07-05T00:00:00Z',
    updatedAt: null,
    ...overrides,
  };
}

function vehicle(overrides: Partial<Vehicle> = {}): Vehicle {
  return {
    id: 'v1',
    make: 'Toyota',
    model: 'Hilux',
    year: 2015,
    registrationNumber: 'ABC-1234',
    vin: null,
    purchaseDate: null,
    purchasePriceCents: null,
    currency: 'LKR',
    currentMileage: null,
    vehicleType: null,
    fuelType: null,
    distanceUnit: null,
    photoUrl: null,
    photoPublicId: null,
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
    docsStatus: { state: 'none', needsActionCount: 0 },
    ...overrides,
  };
}

function expense(overrides: Partial<Expense> = {}): Expense {
  return {
    id: 'e1',
    vehicleId: 'v1',
    kind: 'fuel',
    date: '2026-07-01',
    costCents: 1000,
    currency: 'LKR',
    ...overrides,
  };
}

describe('mergeExpenses (fan-out)', () => {
  it('returns an empty list for no vehicles', () => {
    expect(mergeExpenses([], {}, {})).toEqual([]);
  });

  it('a vehicle with no logs/records contributes nothing', () => {
    const v1 = vehicle({ id: 'v1' });
    const v2 = vehicle({ id: 'v2' });
    // v2 omitted entirely from both maps — must not throw / must not appear.
    const result = mergeExpenses([v1, v2], { v1: [fuelLog({ vehicleId: 'v1' })] }, {});
    expect(result).toHaveLength(1);
    expect(result[0]!.vehicleId).toBe('v1');
  });

  it('merges fuel logs and maintenance records across multiple vehicles, newest first', () => {
    const v1 = vehicle({ id: 'v1' });
    const v2 = vehicle({ id: 'v2' });
    const oldFuel = fuelLog({ id: 'f-old', vehicleId: 'v1', date: '2026-06-01' });
    const newMaint = maintenanceRecord({ id: 'm-new', vehicleId: 'v2', date: '2026-07-10' });
    const midFuel = fuelLog({ id: 'f-mid', vehicleId: 'v2', date: '2026-07-05' });

    const result = mergeExpenses(
      [v1, v2],
      { v1: [oldFuel], v2: [midFuel] },
      { v2: [newMaint] },
    );

    expect(result.map((e) => e.id)).toEqual(['m-new', 'f-mid', 'f-old']);
  });

  it('normalises a null maintenance cost to 0 and falls back currency', () => {
    const v1 = vehicle({ id: 'v1' });
    const record = maintenanceRecord({ costCents: null, currency: null });
    const result = mergeExpenses([v1], {}, { v1: [record] });
    expect(result[0]!.costCents).toBe(0);
    expect(result[0]!.currency).toBe('LKR');
  });
});

describe('expenseFromFuelLog / expenseFromMaintenance', () => {
  it('maps a fuel log to an Expense', () => {
    const log = fuelLog();
    const e = expenseFromFuelLog(log);
    expect(e).toMatchObject({
      id: log.id,
      vehicleId: log.vehicleId,
      kind: 'fuel',
      date: log.date,
      costCents: log.priceCents,
      currency: log.currency,
      fuelLog: log,
    });
  });

  it('maps a maintenance record to an Expense', () => {
    const record = maintenanceRecord();
    const e = expenseFromMaintenance(record);
    expect(e).toMatchObject({
      id: record.id,
      vehicleId: record.vehicleId,
      kind: 'maintenance',
      date: record.date,
      costCents: record.costCents,
      currency: record.currency,
      maintenanceRecord: record,
    });
  });
});

describe('filterByKind', () => {
  it('returns everything when kind is null', () => {
    const expenses = [expense({ kind: 'fuel' }), expense({ kind: 'maintenance' })];
    expect(filterByKind(expenses, null)).toEqual(expenses);
  });

  it('filters to the given kind', () => {
    const fuel = expense({ kind: 'fuel' });
    const maint = expense({ kind: 'maintenance' });
    expect(filterByKind([fuel, maint], 'maintenance')).toEqual([maint]);
  });

  it('returns an empty array when nothing matches', () => {
    const fuel = expense({ kind: 'fuel' });
    expect(filterByKind([fuel], 'maintenance')).toEqual([]);
  });

  it('handles an empty input list', () => {
    expect(filterByKind([], 'fuel')).toEqual([]);
  });
});

describe('filterByVehicle', () => {
  it('returns everything when vehicleId is null', () => {
    const expenses = [expense({ vehicleId: 'v1' }), expense({ vehicleId: 'v2' })];
    expect(filterByVehicle(expenses, null)).toEqual(expenses);
  });

  it('filters to the given vehicle', () => {
    const v1 = expense({ vehicleId: 'v1' });
    const v2 = expense({ vehicleId: 'v2' });
    expect(filterByVehicle([v1, v2], 'v2')).toEqual([v2]);
  });

  it('returns an empty array when nothing matches', () => {
    const v1 = expense({ vehicleId: 'v1' });
    expect(filterByVehicle([v1], 'v9')).toEqual([]);
  });
});

describe('filterToCurrentMonth', () => {
  const now = new Date(2026, 6, 13); // 13 Jul 2026

  it('keeps only expenses within the current calendar month', () => {
    const inMonth = expense({ date: '2026-07-01' });
    const lastDayOfMonth = expense({ date: '2026-07-31' });
    const prevMonth = expense({ date: '2026-06-30' });
    const nextMonth = expense({ date: '2026-08-01' });

    const result = filterToCurrentMonth([inMonth, lastDayOfMonth, prevMonth, nextMonth], now);
    expect(result).toEqual([inMonth, lastDayOfMonth]);
  });

  it('handles year boundaries (December vs January)', () => {
    const dec = expense({ date: '2025-12-31' });
    const jan = expense({ date: '2026-01-01' });
    expect(filterToCurrentMonth([dec, jan], new Date(2026, 0, 15))).toEqual([jan]);
  });

  it('returns an empty array for an empty input', () => {
    expect(filterToCurrentMonth([], now)).toEqual([]);
  });

  it('returns an empty array when nothing falls in the month', () => {
    const other = expense({ date: '2020-01-01' });
    expect(filterToCurrentMonth([other], now)).toEqual([]);
  });
});

describe('groupExpensesByMonth', () => {
  it('groups by calendar month, newest month first, sorted newest-date first within a month', () => {
    const july1 = expense({ id: 'a', date: '2026-07-01', costCents: 500 });
    const july15 = expense({ id: 'b', date: '2026-07-15', costCents: 700 });
    const june = expense({ id: 'c', date: '2026-06-20', costCents: 300 });

    const groups = groupExpensesByMonth([july1, july15, june]);

    expect(groups).toHaveLength(2);
    expect(groups[0]!.month).toEqual(new Date(2026, 6, 1));
    expect(groups[0]!.expenses.map((e) => e.id)).toEqual(['b', 'a']);
    expect(groups[0]!.subtotalCents).toBe(1200);
    expect(groups[1]!.month).toEqual(new Date(2026, 5, 1));
    expect(groups[1]!.subtotalCents).toBe(300);
  });

  it('returns an empty array for no expenses', () => {
    expect(groupExpensesByMonth([])).toEqual([]);
  });

  it('handles a single expense', () => {
    const only = expense({ date: '2026-07-01', costCents: 100 });
    const groups = groupExpensesByMonth([only]);
    expect(groups).toHaveLength(1);
    expect(groups[0]!.subtotalCents).toBe(100);
    expect(groups[0]!.expenses).toEqual([only]);
  });
});

describe('totalCents / fuelCents / maintenanceCents', () => {
  it('sums to 0 for an empty list', () => {
    expect(totalCents([])).toBe(0);
    expect(fuelCents([])).toBe(0);
    expect(maintenanceCents([])).toBe(0);
  });

  it('sums mixed-kind expenses correctly', () => {
    const expenses = [
      expense({ kind: 'fuel', costCents: 1000 }),
      expense({ kind: 'fuel', costCents: 500 }),
      expense({ kind: 'maintenance', costCents: 2000 }),
    ];
    expect(totalCents(expenses)).toBe(3500);
    expect(fuelCents(expenses)).toBe(1500);
    expect(maintenanceCents(expenses)).toBe(2000);
  });

  it('all-filtered-out (single kind present) leaves the other kind at 0', () => {
    const expenses = [expense({ kind: 'fuel', costCents: 1000 })];
    expect(maintenanceCents(expenses)).toBe(0);
    expect(fuelCents(expenses)).toBe(1000);
  });
});

describe('expenseDateLabel', () => {
  const now = new Date(2026, 6, 13);

  it('labels today and yesterday', () => {
    expect(expenseDateLabel('2026-07-13', now)).toBe('Today');
    expect(expenseDateLabel('2026-07-12', now)).toBe('Yesterday');
  });

  it('formats older dates as "d MMM"', () => {
    expect(expenseDateLabel('2026-06-20', now)).toBe('20 Jun');
  });
});

describe('expenseCategoryLabel / expenseSubLabel', () => {
  const now = new Date(2026, 6, 13);

  it('fuel: category "Fuel", sub label includes liters + tank state', () => {
    const log = fuelLog({ date: '2026-07-13', liters: 12.345, isFullTank: false });
    const e = expenseFromFuelLog(log);
    expect(expenseCategoryLabel(e)).toBe('Fuel');
    expect(expenseSubLabel(e, now)).toBe('Today · 12.3 L · Partial');
  });

  it('maintenance: category falls back to "Maintenance" when serviceType is blank', () => {
    const withType = expenseFromMaintenance(
      maintenanceRecord({ serviceType: 'Brake pads', date: '2026-07-13' }),
    );
    const blank = expenseFromMaintenance(maintenanceRecord({ serviceType: '', date: '2026-07-13' }));
    expect(expenseCategoryLabel(withType)).toBe('Brake pads');
    expect(expenseCategoryLabel(blank)).toBe('Maintenance');
    expect(expenseSubLabel(blank, now)).toBe('Today');
  });
});
