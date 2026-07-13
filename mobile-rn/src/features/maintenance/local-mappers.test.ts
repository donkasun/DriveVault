import { maintenanceRecordToRow, rowToMaintenanceRecord, type MaintenanceRow } from './local-mappers';

const baseRow: MaintenanceRow = {
  id: 'maint-1',
  vehicle_id: 'veh-1',
  date: '2024-03-15',
  service_type: 'Oil change',
  category: 'routine',
  cost_cents: 850000,
  currency: 'LKR',
  odometer: 20000,
  workshop: 'ACE Motors',
  notes: 'full synthetic',
  source: 'manual',
  ai_extraction_id: null,
  updated_at: '2024-03-16T00:00:00Z',
  created_at: '2024-03-15T00:00:00Z',
  cached_at: 1700000000000,
};

describe('maintenance local-mappers', () => {
  it('maps a full row to a domain MaintenanceRecord preserving integer cents/odometer', () => {
    const record = rowToMaintenanceRecord(baseRow);

    expect(record).toEqual({
      id: 'maint-1',
      vehicleId: 'veh-1',
      date: '2024-03-15',
      odometer: 20000,
      serviceType: 'Oil change',
      category: 'routine',
      costCents: 850000,
      currency: 'LKR',
      workshop: 'ACE Motors',
      notes: 'full synthetic',
      source: 'manual',
      aiExtractionId: null,
      createdAt: '2024-03-15T00:00:00Z',
      updatedAt: '2024-03-16T00:00:00Z',
    });
    expect(Number.isInteger(record.costCents)).toBe(true);
    expect(Number.isInteger(record.odometer as number)).toBe(true);
  });

  it('handles nullable columns (cost, currency, odometer, workshop, updatedAt)', () => {
    const record = rowToMaintenanceRecord({
      ...baseRow,
      cost_cents: null,
      currency: null,
      odometer: null,
      workshop: null,
      updated_at: null,
    });

    expect(record.costCents).toBeNull();
    expect(record.currency).toBeNull();
    expect(record.odometer).toBeNull();
    expect(record.workshop).toBeNull();
    expect(record.updatedAt).toBeNull();
  });

  it('round-trips maintenance record -> row -> record', () => {
    const record = rowToMaintenanceRecord(baseRow);
    const row = maintenanceRecordToRow(record, 1710000000000);

    expect(row.cached_at).toBe(1710000000000);
    expect(rowToMaintenanceRecord(row)).toEqual(record);
  });
});
