/**
 * Human-readable vehicle label — port of dashboard._vehicle_label.
 * Shared by dashboard renewals/activity and GET /activity.
 */

export type VehicleLabelSource = {
  id: string;
  make: string | null;
  model: string | null;
  year: number | null;
  registrationNumber: string | null;
};

/**
 * Return make+model (+ year prefix) when both make and model are set;
 * else registrationNumber; else the vehicle id string.
 */
export function vehicleLabel(vehicle: VehicleLabelSource): string {
  if (vehicle.make && vehicle.model) {
    let label = `${vehicle.make} ${vehicle.model}`;
    if (vehicle.year) {
      label = `${vehicle.year} ${label}`;
    }
    return label;
  }
  if (vehicle.registrationNumber) {
    return vehicle.registrationNumber;
  }
  return String(vehicle.id);
}
