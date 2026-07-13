/**
 * Server state for the expenses screen.
 *
 * There is no `/expenses` backend endpoint (Doc 3). Parity with Flutter's
 * `allExpensesProvider`: fan out over every vehicle's fuel logs +
 * maintenance records (both already-existing, independently cached queries)
 * and merge client-side. Re-uses the exact query keys the fuel-logs and
 * maintenance features already invalidate on mutation, so editing/deleting
 * a fuel log or maintenance record elsewhere in the app keeps this list
 * fresh for free — no bespoke invalidation needed here.
 */

import { useQueries, useQueryClient } from '@tanstack/react-query';
import { useMemo } from 'react';

import { fuelLogsQueryKey } from '@/features/fuel-logs/hooks';
import { fuelRepository } from '@/features/fuel-logs/repository';
import type { FuelLog } from '@/features/fuel-logs/types';
import { maintenanceQueryKey } from '@/features/maintenance/hooks';
import { maintenanceRepository } from '@/features/maintenance/repository';
import type { MaintenanceRecord } from '@/features/maintenance/types';
import { useVehicles } from '@/features/vehicles/hooks';
import type { Vehicle } from '@/features/vehicles/types';
import { mergeExpenses } from './helpers';
import type { Expense } from './types';

export type ExpensesResult = {
  data: Expense[] | undefined;
  vehicles: Vehicle[] | undefined;
  isLoading: boolean;
  isError: boolean;
  refetch: () => void;
};

const EMPTY_VEHICLES: Vehicle[] = [];

export function useExpenses(): ExpensesResult {
  const vehiclesQuery = useVehicles();
  const vehicles = vehiclesQuery.data ?? EMPTY_VEHICLES;

  const fuelResults = useQueries({
    queries: vehicles.map((v) => ({
      queryKey: fuelLogsQueryKey(v.id),
      queryFn: () => fuelRepository.listForVehicle(v.id),
    })),
  });

  const maintenanceResults = useQueries({
    queries: vehicles.map((v) => ({
      queryKey: maintenanceQueryKey(v.id),
      queryFn: () => maintenanceRepository.listForVehicle(v.id),
    })),
  });

  const fuelLoading = fuelResults.some((r) => r.isLoading);
  const maintenanceLoading = maintenanceResults.some((r) => r.isLoading);
  const fuelError = fuelResults.some((r) => r.isError);
  const maintenanceError = maintenanceResults.some((r) => r.isError);

  const isLoading = vehiclesQuery.isLoading || (vehicles.length > 0 && (fuelLoading || maintenanceLoading));
  const isError = vehiclesQuery.isError || fuelError || maintenanceError;

  const data = useMemo<Expense[] | undefined>(() => {
    if (vehiclesQuery.isLoading || isError) return undefined;
    if (fuelLoading || maintenanceLoading) return undefined;

    const fuelByVehicle: Record<string, FuelLog[] | undefined> = {};
    const maintenanceByVehicle: Record<string, MaintenanceRecord[] | undefined> = {};
    vehicles.forEach((v, i) => {
      fuelByVehicle[v.id] = fuelResults[i]?.data;
      maintenanceByVehicle[v.id] = maintenanceResults[i]?.data;
    });

    return mergeExpenses(vehicles, fuelByVehicle, maintenanceByVehicle);
  }, [vehicles, fuelResults, maintenanceResults, isError, fuelLoading, maintenanceLoading, vehiclesQuery.isLoading]);

  const queryClient = useQueryClient();

  const refetch = () => {
    queryClient.invalidateQueries({ queryKey: ['vehicles'] });
    vehicles.forEach((v) => {
      queryClient.invalidateQueries({ queryKey: fuelLogsQueryKey(v.id) });
      queryClient.invalidateQueries({ queryKey: maintenanceQueryKey(v.id) });
    });
  };

  return { data, vehicles: vehiclesQuery.data, isLoading, isError, refetch };
}

/** Invalidates every query the expenses fan-out reads from, for a single vehicle. */
export function invalidateExpensesFor(
  queryClient: ReturnType<typeof useQueryClient>,
  vehicleId: string,
): void {
  queryClient.invalidateQueries({ queryKey: fuelLogsQueryKey(vehicleId) });
  queryClient.invalidateQueries({ queryKey: maintenanceQueryKey(vehicleId) });
}
