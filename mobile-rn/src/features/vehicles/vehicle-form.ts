/**
 * Pure helpers for the add/edit vehicle form. Parity with Flutter
 * `features/vehicles/presentation/vehicle_form_screen.dart` (`_save`, field
 * validators, and the km <-> display-unit mileage conversion on first render).
 *
 * Kept dependency-free (no React) so it can be unit tested directly.
 */

import { displayToKm, kmToDisplay, type DistanceUnit } from '@/lib/distance-unit';
import type { CreateVehiclePayload, UpdateVehiclePayload, Vehicle } from './types';

/** Vehicle types matching the backend enum (Doc 2). */
export const VEHICLE_TYPES = ['car', 'pickup', 'van', 'truck', 'motorcycle', 'other'] as const;

/** Fuel types matching the backend enum (fixed per vehicle). */
export const FUEL_TYPES = ['petrol', 'diesel', 'electric', 'hybrid', 'other'] as const;

/** Sentinel representing "no fuel type selected" (maps to `null` in state/API). */
export const FUEL_TYPE_NONE = '__none__';

export const FUEL_TYPE_OPTIONS = [FUEL_TYPE_NONE, ...FUEL_TYPES];

export const DISTANCE_UNIT_OPTIONS: DistanceUnit[] = ['km', 'mi'];

export const DEFAULT_VEHICLE_TYPE = 'car';

/** Maps a nullable fuel type to the sentinel string the picker displays. */
export function fuelTypeToDisplay(fuelType: string | null): string {
  return fuelType ?? FUEL_TYPE_NONE;
}

/** Maps a picker value (possibly the sentinel) back to a nullable fuel type. */
export function fuelTypeFromDisplay(picked: string): string | null {
  return picked === FUEL_TYPE_NONE ? null : picked;
}

/**
 * Strict integer parse — the equivalent of Dart's `int.tryParse`.
 *
 * `Number.parseInt` is NOT equivalent: it stops at the first non-digit, so
 * "2015abc" would yield 2015 where Dart yields null. Pasting into the numeric
 * field can produce exactly that.
 */
export function tryParseInt(value: string): number | null {
  const trimmed = value.trim();
  if (!/^[+-]?\d+$/.test(trimmed)) return null;
  const parsed = Number(trimmed);
  return Number.isSafeInteger(parsed) ? parsed : null;
}

/** Strict decimal parse — the equivalent of Dart's `double.tryParse`. */
export function tryParseDouble(value: string): number | null {
  const trimmed = value.trim();
  if (!/^[+-]?(\d+\.?\d*|\.\d+)$/.test(trimmed)) return null;
  const parsed = Number(trimmed);
  return Number.isFinite(parsed) ? parsed : null;
}

/** Year validator: empty is allowed (optional field); otherwise 1886-2100. */
export function validateYear(value: string): string | null {
  const trimmed = value.trim();
  if (trimmed === '') return null;
  const year = tryParseInt(trimmed);
  if (year === null || year < 1886 || year > 2100) {
    return 'Invalid year';
  }
  return null;
}

/** Required-text-field validator matching Flutter's `'$label is required'`. */
export function validateRequired(label: string, value: string): string | null {
  return value.trim() === '' ? `${label} is required` : null;
}

/** Mirrors `_canSave`: only make + model are required for the Save button to enable. */
export function canSaveVehicleForm(make: string, model: string): boolean {
  return make.trim() !== '' && model.trim() !== '';
}

/**
 * Convert a stored km odometer value to the display unit, once, for the
 * initial render of an edit-mode form. Returns the original string unchanged
 * when the unit is km or the value isn't a positive number (parity with
 * `_maybeConvertMileage`).
 */
export function initialMileageDisplayValue(storedKmText: string, unit: DistanceUnit): string {
  if (unit === 'km') return storedKmText;
  const raw = tryParseInt(storedKmText);
  if (raw === null || raw === 0) return storedKmText;
  return String(Math.round(kmToDisplay(raw, unit)));
}

export type VehicleFormState = {
  make: string;
  model: string;
  year: string;
  registrationNumber: string;
  mileageDisplay: string;
  vehicleType: string | null;
  fuelType: string | null;
  distanceUnit: DistanceUnit | null;
  photoUrl: string | null;
  photoPublicId: string | null;
};

/**
 * Builds the create payload from form state. `effectiveDistUnit` is the unit
 * the mileage text is currently displayed in (vehicle override, else user
 * default) — mileage is always converted back to integer km for storage.
 */
export function buildCreatePayload(
  state: VehicleFormState,
  effectiveDistUnit: DistanceUnit,
): CreateVehiclePayload {
  const payload: CreateVehiclePayload = {
    make: state.make.trim(),
    model: state.model.trim(),
  };

  const year = tryParseInt(state.year);
  if (year !== null) payload.year = year;

  const reg = state.registrationNumber.trim();
  if (reg !== '') payload.registrationNumber = reg;

  const mileageDisplay = tryParseDouble(state.mileageDisplay);
  if (mileageDisplay !== null) {
    payload.currentMileage = displayToKm(mileageDisplay, effectiveDistUnit);
  }

  if (state.vehicleType != null) payload.vehicleType = state.vehicleType;
  if (state.fuelType != null) payload.fuelType = state.fuelType;
  if (state.distanceUnit != null) payload.distanceUnit = state.distanceUnit;
  if (state.photoUrl != null) payload.photoUrl = state.photoUrl;
  if (state.photoPublicId != null) payload.photoPublicId = state.photoPublicId;

  return payload;
}

/**
 * Builds the update payload from form state, diffing fuel type / distance
 * unit against the original vehicle so only actual changes are sent (parity
 * with the Dart `_save`'s edit-mode branch, including the "reset to null"
 * case that add-mode's "only send if non-null" can't express).
 */
export function buildUpdatePayload(
  state: VehicleFormState,
  effectiveDistUnit: DistanceUnit,
  original: Vehicle,
): UpdateVehiclePayload {
  const payload: UpdateVehiclePayload = {
    make: state.make.trim(),
    model: state.model.trim(),
  };

  const year = tryParseInt(state.year);
  if (year !== null) payload.year = year;

  const reg = state.registrationNumber.trim();
  if (reg !== '') payload.registrationNumber = reg;

  const mileageDisplay = tryParseDouble(state.mileageDisplay);
  if (mileageDisplay !== null) {
    payload.currentMileage = displayToKm(mileageDisplay, effectiveDistUnit);
  }

  if (state.vehicleType != null) payload.vehicleType = state.vehicleType;

  if (state.fuelType !== original.fuelType) payload.fuelType = state.fuelType;
  if (state.distanceUnit !== original.distanceUnit) payload.distanceUnit = state.distanceUnit;

  if (state.photoUrl != null) payload.photoUrl = state.photoUrl;
  if (state.photoPublicId != null) payload.photoPublicId = state.photoPublicId;

  return payload;
}
