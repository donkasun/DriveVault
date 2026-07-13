import { DOCS_STATUS_NONE, type Vehicle } from './types';
import {
  buildCreatePayload,
  buildUpdatePayload,
  canSaveVehicleForm,
  fuelTypeFromDisplay,
  fuelTypeToDisplay,
  FUEL_TYPE_NONE,
  initialMileageDisplayValue,
  tryParseDouble,
  tryParseInt,
  validateRequired,
  validateYear,
  type VehicleFormState,
} from './vehicle-form';

function baseState(overrides: Partial<VehicleFormState> = {}): VehicleFormState {
  return {
    make: 'Toyota',
    model: 'Hilux',
    year: '',
    registrationNumber: '',
    mileageDisplay: '',
    vehicleType: 'car',
    fuelType: null,
    distanceUnit: null,
    photoUrl: null,
    photoPublicId: null,
    ...overrides,
  };
}

function baseVehicle(overrides: Partial<Vehicle> = {}): Vehicle {
  return {
    id: 'v1',
    make: 'Toyota',
    model: 'Hilux',
    year: 2020,
    registrationNumber: null,
    vin: null,
    purchaseDate: null,
    purchasePriceCents: null,
    currency: 'LKR',
    currentMileage: 48000,
    vehicleType: 'car',
    fuelType: 'diesel',
    distanceUnit: null,
    photoUrl: null,
    photoPublicId: null,
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
    docsStatus: DOCS_STATUS_NONE,
    ...overrides,
  };
}

describe('validateYear', () => {
  it('allows an empty value (optional field)', () => {
    expect(validateYear('')).toBeNull();
    expect(validateYear('   ')).toBeNull();
  });

  it('accepts years within 1886-2100', () => {
    expect(validateYear('1886')).toBeNull();
    expect(validateYear('2100')).toBeNull();
    expect(validateYear('2020')).toBeNull();
  });

  it('rejects years outside the range or non-numeric input', () => {
    expect(validateYear('1885')).toBe('Invalid year');
    expect(validateYear('2101')).toBe('Invalid year');
    expect(validateYear('abcd')).toBe('Invalid year');
  });
});

describe('validateRequired', () => {
  it('matches the Dart message exactly', () => {
    expect(validateRequired('Make', '')).toBe('Make is required');
    expect(validateRequired('Make', '   ')).toBe('Make is required');
  });

  it('passes for non-empty trimmed text', () => {
    expect(validateRequired('Make', ' Toyota ')).toBeNull();
  });
});

describe('canSaveVehicleForm', () => {
  it('requires both make and model', () => {
    expect(canSaveVehicleForm('', '')).toBe(false);
    expect(canSaveVehicleForm('Toyota', '')).toBe(false);
    expect(canSaveVehicleForm('', 'Hilux')).toBe(false);
    expect(canSaveVehicleForm('Toyota', 'Hilux')).toBe(true);
  });

  it('treats whitespace-only text as empty', () => {
    expect(canSaveVehicleForm('  ', 'Hilux')).toBe(false);
  });
});

describe('fuel type sentinel mapping', () => {
  it('maps null to the sentinel and back', () => {
    expect(fuelTypeToDisplay(null)).toBe(FUEL_TYPE_NONE);
    expect(fuelTypeFromDisplay(FUEL_TYPE_NONE)).toBeNull();
  });

  it('passes real fuel types through untouched', () => {
    expect(fuelTypeToDisplay('diesel')).toBe('diesel');
    expect(fuelTypeFromDisplay('diesel')).toBe('diesel');
  });
});

describe('initialMileageDisplayValue', () => {
  it('leaves km values unchanged', () => {
    expect(initialMileageDisplayValue('48000', 'km')).toBe('48000');
  });

  it('converts stored km to miles for display', () => {
    // 48000 km * 0.621371 ≈ 29825.808 -> rounds to 29826
    expect(initialMileageDisplayValue('48000', 'mi')).toBe('29826');
  });

  it('leaves empty/zero values unchanged (no-op like the Dart guard)', () => {
    expect(initialMileageDisplayValue('', 'mi')).toBe('');
    expect(initialMileageDisplayValue('0', 'mi')).toBe('0');
  });
});

describe('buildCreatePayload', () => {
  it('always includes trimmed make/model', () => {
    const payload = buildCreatePayload(baseState({ make: ' Toyota ', model: ' Hilux ' }), 'km');
    expect(payload.make).toBe('Toyota');
    expect(payload.model).toBe('Hilux');
  });

  it('omits year/registration/mileage when blank', () => {
    const payload = buildCreatePayload(baseState(), 'km');
    expect(payload.year).toBeUndefined();
    expect(payload.registrationNumber).toBeUndefined();
    expect(payload.currentMileage).toBeUndefined();
  });

  it('converts displayed mileage to integer km for storage', () => {
    const payload = buildCreatePayload(baseState({ mileageDisplay: '100' }), 'mi');
    // 100 mi * 1.609344 ≈ 160.9344 -> rounds to 161
    expect(payload.currentMileage).toBe(161);
  });

  it('never stores miles: km-unit mileage passes through as integer km', () => {
    const payload = buildCreatePayload(baseState({ mileageDisplay: '48000' }), 'km');
    expect(payload.currentMileage).toBe(48000);
  });

  it('only sends fuelType/distanceUnit/photo fields when non-null', () => {
    const payload = buildCreatePayload(
      baseState({ fuelType: 'diesel', distanceUnit: 'mi', photoUrl: 'https://x/y.jpg', photoPublicId: 'pid' }),
      'mi',
    );
    expect(payload.fuelType).toBe('diesel');
    expect(payload.distanceUnit).toBe('mi');
    expect(payload.photoUrl).toBe('https://x/y.jpg');
    expect(payload.photoPublicId).toBe('pid');
  });
});

describe('buildUpdatePayload', () => {
  it('only sends fuelType/distanceUnit when changed from the original vehicle', () => {
    const original = baseVehicle({ fuelType: 'diesel', distanceUnit: null });

    const unchanged = buildUpdatePayload(
      baseState({ fuelType: 'diesel', distanceUnit: null }),
      'km',
      original,
    );
    expect(unchanged.fuelType).toBeUndefined();
    expect(unchanged.distanceUnit).toBeUndefined();

    const changed = buildUpdatePayload(
      baseState({ fuelType: null, distanceUnit: 'mi' }),
      'mi',
      original,
    );
    expect(changed.fuelType).toBeNull();
    expect(changed.distanceUnit).toBe('mi');
  });

  it('converts mileage using the effective display unit', () => {
    const original = baseVehicle();
    const payload = buildUpdatePayload(baseState({ mileageDisplay: '29826' }), 'mi', original);
    // 29826 mi -> back to km, round-trips to the original 48000
    expect(payload.currentMileage).toBe(48000);
  });
});

// ---------------------------------------------------------------------------
// Strict parsing — Dart's int.tryParse / double.tryParse reject trailing junk,
// but JS's parseInt/parseFloat silently truncate it. These pin the difference.
// ---------------------------------------------------------------------------

describe('strict parsing parity with Dart', () => {
  it('rejects a year with trailing junk (parseInt would accept 2015)', () => {
    expect(tryParseInt('2015abc')).toBeNull();
    expect(validateYear('2015abc')).toBe('Invalid year');
  });

  it('rejects a mileage with trailing junk (parseFloat would accept 120)', () => {
    expect(tryParseDouble('120km')).toBeNull();
  });

  it('still accepts clean numeric input', () => {
    expect(tryParseInt('2015')).toBe(2015);
    expect(tryParseInt('  2015  ')).toBe(2015);
    expect(tryParseDouble('120.5')).toBe(120.5);
    expect(validateYear('2015')).toBeNull();
  });

  it('does not put a junk year into the create payload', () => {
    const payload = buildCreatePayload(
      {
        make: 'Toyota',
        model: 'Hilux',
        year: '2015abc',
        registrationNumber: '',
        mileageDisplay: '',
        vehicleType: 'car',
        fuelType: null,
        distanceUnit: null,
        photoUrl: null,
        photoPublicId: null,
      },
      'km',
    );
    expect(payload.year).toBeUndefined();
  });
});
