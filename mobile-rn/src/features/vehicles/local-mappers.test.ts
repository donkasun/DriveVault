import { DOCS_STATUS_NONE } from './types';
import { parseDocsStatus, rowToVehicle, vehicleToRow, type VehicleRow } from './local-mappers';

const baseRow: VehicleRow = {
  id: 'veh-1',
  make: 'Toyota',
  model: 'Hilux',
  year: 2015,
  registration_number: 'CAB-1234',
  vin: 'VIN123',
  purchase_date: '2020-01-01',
  purchase_price_cents: 500000,
  currency: 'LKR',
  current_mileage: 12000,
  vehicle_type: 'truck',
  fuel_type: 'diesel',
  distance_unit: 'km',
  photo_url: 'https://example.com/p.jpg',
  photo_public_id: 'pub-1',
  docs_status_json: '{"state":"needs_action","needsActionCount":2}',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-02T00:00:00Z',
  cached_at: 1700000000000,
};

describe('vehicles local-mappers', () => {
  it('maps a full row to a domain Vehicle preserving integer money/mileage', () => {
    const vehicle = rowToVehicle(baseRow);

    expect(vehicle).toEqual({
      id: 'veh-1',
      make: 'Toyota',
      model: 'Hilux',
      year: 2015,
      registrationNumber: 'CAB-1234',
      vin: 'VIN123',
      purchaseDate: '2020-01-01',
      purchasePriceCents: 500000,
      currency: 'LKR',
      currentMileage: 12000,
      vehicleType: 'truck',
      fuelType: 'diesel',
      distanceUnit: 'km',
      photoUrl: 'https://example.com/p.jpg',
      photoPublicId: 'pub-1',
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-02T00:00:00Z',
      docsStatus: { state: 'needs_action', needsActionCount: 2 },
    });
    expect(Number.isInteger(vehicle.purchasePriceCents)).toBe(true);
    expect(Number.isInteger(vehicle.currentMileage)).toBe(true);
  });

  it('maps null-able columns to null fields', () => {
    const row: VehicleRow = {
      ...baseRow,
      year: null,
      registration_number: null,
      vin: null,
      purchase_date: null,
      purchase_price_cents: null,
      current_mileage: null,
      vehicle_type: null,
      fuel_type: null,
      distance_unit: null,
      photo_url: null,
      photo_public_id: null,
    };

    const vehicle = rowToVehicle(row);

    expect(vehicle.year).toBeNull();
    expect(vehicle.registrationNumber).toBeNull();
    expect(vehicle.purchasePriceCents).toBeNull();
    expect(vehicle.currentMileage).toBeNull();
    expect(vehicle.distanceUnit).toBeNull();
  });

  it('falls back to DOCS_STATUS_NONE for malformed docs_status_json', () => {
    expect(parseDocsStatus('not json')).toEqual(DOCS_STATUS_NONE);
  });

  it('fills in missing docs status fields with defaults', () => {
    expect(parseDocsStatus('{}')).toEqual({ state: 'none', needsActionCount: 0 });
  });

  it('round-trips vehicle -> row -> vehicle', () => {
    const vehicle = rowToVehicle(baseRow);
    const row = vehicleToRow(vehicle, 1710000000000);

    expect(row.cached_at).toBe(1710000000000);
    expect(rowToVehicle(row)).toEqual(vehicle);
  });
});
