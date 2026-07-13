import { fuelLogToRow, rowToFuelLog, type FuelLogRow } from './local-mappers';

const baseRow: FuelLogRow = {
  id: 'fuel-1',
  vehicle_id: 'veh-1',
  date: '2024-05-01',
  liters: 42.5,
  price_cents: 12345,
  currency: 'LKR',
  odometer: 15000,
  is_full_tank: true,
  notes: 'topped up',
  created_at: '2024-05-01T00:00:00Z',
  updated_at: '2024-05-01T00:00:00Z',
  cached_at: 1700000000000,
};

describe('fuel-logs local-mappers', () => {
  it('maps a row to a domain FuelLog preserving integer cents/odometer', () => {
    const fuelLog = rowToFuelLog(baseRow);

    expect(fuelLog).toEqual({
      id: 'fuel-1',
      vehicleId: 'veh-1',
      date: '2024-05-01',
      liters: 42.5,
      priceCents: 12345,
      currency: 'LKR',
      odometer: 15000,
      isFullTank: true,
      notes: 'topped up',
      createdAt: '2024-05-01T00:00:00Z',
      updatedAt: '2024-05-01T00:00:00Z',
    });
    expect(Number.isInteger(fuelLog.priceCents)).toBe(true);
    expect(Number.isInteger(fuelLog.odometer)).toBe(true);
  });

  it('handles a null notes field', () => {
    const fuelLog = rowToFuelLog({ ...baseRow, notes: null });
    expect(fuelLog.notes).toBeNull();
  });

  it('maps false boolean (partial fill) correctly, not just truthy defaults', () => {
    const fuelLog = rowToFuelLog({ ...baseRow, is_full_tank: false });
    expect(fuelLog.isFullTank).toBe(false);
  });

  it('round-trips fuel log -> row -> fuel log', () => {
    const fuelLog = rowToFuelLog(baseRow);
    const row = fuelLogToRow(fuelLog, 1710000000000);

    expect(row.cached_at).toBe(1710000000000);
    expect(rowToFuelLog(row)).toEqual(fuelLog);
  });
});
