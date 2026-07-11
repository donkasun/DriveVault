import { describe, expect, it } from 'vitest';

import { vehicleLabel } from './vehicle-label';

describe('vehicleLabel', () => {
  it('returns year + make + model when all present', () => {
    expect(
      vehicleLabel({
        id: 'a',
        make: 'Toyota',
        model: 'Hilux',
        year: 2020,
        registrationNumber: null,
      }),
    ).toBe('2020 Toyota Hilux');
  });

  it('omits year when null', () => {
    expect(
      vehicleLabel({
        id: 'a',
        make: 'Honda',
        model: 'Civic',
        year: null,
        registrationNumber: 'ABC-123',
      }),
    ).toBe('Honda Civic');
  });

  it('falls back to registration when make/model missing', () => {
    expect(
      vehicleLabel({
        id: 'uuid-1',
        make: null,
        model: null,
        year: null,
        registrationNumber: 'WP-CAB-1234',
      }),
    ).toBe('WP-CAB-1234');
  });

  it('falls back to id when nothing else available', () => {
    expect(
      vehicleLabel({
        id: 'uuid-fallback',
        make: '',
        model: '',
        year: null,
        registrationNumber: null,
      }),
    ).toBe('uuid-fallback');
  });
});
