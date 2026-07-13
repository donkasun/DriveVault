/**
 * Parity with Flutter `mobile/lib/shared/utils/distance_unit.dart`.
 *
 * Storage convention: odometer / mileage values are ALWAYS stored and sent over
 * the wire in **kilometres** (integer km). This module exists only at the UI edge
 * for display / input conversion.
 */

export type DistanceUnit = 'km' | 'mi';

/** Parse "km" or "mi" (case-insensitive). Throws for anything else. */
export function distanceUnitFromString(value: string): DistanceUnit {
  const v = value.toLowerCase();
  if (v === 'km') return 'km';
  if (v === 'mi') return 'mi';
  throw new RangeError(`Must be "km" or "mi", got "${value}"`);
}

/**
 * Effective display unit for a vehicle.
 * Rule: vehicleUnit ?? userUnit (vehicle override wins; null inherits default).
 */
export function effectiveUnit(vehicleUnit: string | null, userUnit: string): DistanceUnit {
  return distanceUnitFromString(vehicleUnit ?? userUnit);
}

const KM_TO_MI = 0.621371;
const MI_TO_KM = 1.609344;

/** Convert a stored integer km value to the display unit. */
export function kmToDisplay(km: number, unit: DistanceUnit): number {
  return unit === 'km' ? km : km * KM_TO_MI;
}

/** Convert a user-entered value in `unit` to integer km for storage. */
export function displayToKm(displayValue: number, unit: DistanceUnit): number {
  return unit === 'km' ? Math.round(displayValue) : Math.round(displayValue * MI_TO_KM);
}

const intFmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });

/**
 * Format a stored km value for display with a unit suffix.
 *   formatDistance(48200, 'km') → "48,200 km"
 *   formatDistance(48200, 'mi') → "29,950 mi"
 */
export function formatDistance(km: number, unit: DistanceUnit): string {
  return `${intFmt.format(Math.round(kmToDisplay(km, unit)))} ${unit}`;
}

/**
 * Fuel economy as distance-per-unit-of-fuel. Input is the backend's avg
 * consumption in L/100km.
 *   km → "X.X km/L" (100 / lPer100km)
 *   mi → "X.X mpg"  (235.215 / lPer100km, US gallon)
 * Returns "—" when null or <= 0.
 */
export function formatEconomy(lPer100km: number | null | undefined, unit: DistanceUnit): string {
  if (lPer100km == null || lPer100km <= 0) return '—';
  return unit === 'km'
    ? `${(100 / lPer100km).toFixed(1)} km/L`
    : `${(235.215 / lPer100km).toFixed(1)} mpg`;
}
