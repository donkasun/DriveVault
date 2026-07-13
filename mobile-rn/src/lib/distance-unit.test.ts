import {
  displayToKm,
  distanceUnitFromString,
  effectiveUnit,
  formatDistance,
  formatEconomy,
  kmToDisplay,
} from './distance-unit';

describe('distanceUnitFromString', () => {
  it('parses km and mi case-insensitively', () => {
    expect(distanceUnitFromString('km')).toBe('km');
    expect(distanceUnitFromString('MI')).toBe('mi');
  });

  it('throws for anything else', () => {
    expect(() => distanceUnitFromString('miles')).toThrow();
  });
});

describe('effectiveUnit', () => {
  it('lets the vehicle override win', () => {
    expect(effectiveUnit('mi', 'km')).toBe('mi');
  });

  it('inherits the user default when the vehicle has no override', () => {
    expect(effectiveUnit(null, 'km')).toBe('km');
  });
});

describe('conversions', () => {
  it('passes km through unchanged', () => {
    expect(kmToDisplay(100, 'km')).toBe(100);
    expect(displayToKm(100, 'km')).toBe(100);
  });

  it('converts km to miles', () => {
    expect(kmToDisplay(100, 'mi')).toBeCloseTo(62.1371, 4);
  });

  it('rounds miles back to integer km for storage', () => {
    expect(displayToKm(62.1371, 'mi')).toBe(100);
  });
});

describe('formatDistance', () => {
  it('formats km with grouping', () => {
    expect(formatDistance(48200, 'km')).toBe('48,200 km');
  });

  it('formats mi with grouping', () => {
    // 48200 km * 0.621371 = 29,950.08... → rounds to 29,950
    // Matches the worked example in Flutter's distance_unit.dart docstring.
    expect(formatDistance(48200, 'mi')).toBe('29,950 mi');
  });
});

describe('formatEconomy', () => {
  it('converts L/100km to km/L', () => {
    // 100 / 8.0 = 12.5
    expect(formatEconomy(8.0, 'km')).toBe('12.5 km/L');
  });

  it('converts L/100km to US mpg', () => {
    // 235.215 / 8.0 = 29.401... → 29.4
    expect(formatEconomy(8.0, 'mi')).toBe('29.4 mpg');
  });

  it('returns an em-dash for null or non-positive input', () => {
    expect(formatEconomy(null, 'km')).toBe('—');
    expect(formatEconomy(undefined, 'km')).toBe('—');
    expect(formatEconomy(0, 'km')).toBe('—');
    expect(formatEconomy(-1, 'km')).toBe('—');
  });
});
