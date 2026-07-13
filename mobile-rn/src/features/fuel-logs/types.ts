/**
 * Fuel domain types.
 *
 * Field names verified against BOTH `backend/app/schemas/fuel_logs.py` (the
 * authoritative wire contract) and Flutter's `features/fuel/domain/fuel_log.dart`.
 * They agree. Do not rename these — an earlier draft invented `filledAt` /
 * `totalCostCents` / `odometerKm` / `stationName`, none of which exist.
 *
 * Money is integer cents; `odometer` is integer kilometres; `liters` is a number.
 */

export type MonthlySpend = {
  month: string;
  spentCents: number;
};

export type FuelStats = {
  /** Backend's average consumption in L/100km. Null until there are enough logs. */
  avgConsumptionLPer100Km: number | null;
  avgCostPerKmCents: number | null;
  totalLiters: number;
  totalSpentCents: number;
  monthlySpend: MonthlySpend[];
};

export type FuelLog = {
  id: string;
  vehicleId: string;
  /** ISO date (YYYY-MM-DD), not a timestamp. */
  date: string;
  liters: number;
  priceCents: number;
  currency: string;
  /** Integer kilometres. */
  odometer: number;
  isFullTank: boolean;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
};

export type CreateFuelLogPayload = {
  date: string;
  liters: number;
  priceCents: number;
  odometer: number;
  currency?: string;
  isFullTank?: boolean;
  notes?: string | null;
};

export type UpdateFuelLogPayload = Partial<CreateFuelLogPayload>;
