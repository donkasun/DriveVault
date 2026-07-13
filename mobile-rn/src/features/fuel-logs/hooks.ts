/** Server state for the fuel feature. */

import { useQuery } from '@tanstack/react-query';

import { fuelRepository } from './repository';

export const fuelLogsQueryKey = (vehicleId: string) =>
  ['vehicles', vehicleId, 'fuel-logs'] as const;
export const fuelStatsQueryKey = (vehicleId: string) => ['fuel-stats', vehicleId] as const;

export function useFuelLogs(vehicleId: string) {
  return useQuery({
    queryKey: fuelLogsQueryKey(vehicleId),
    queryFn: () => fuelRepository.listForVehicle(vehicleId),
    enabled: !!vehicleId,
  });
}

export function useFuelStats(vehicleId: string) {
  return useQuery({
    queryKey: fuelStatsQueryKey(vehicleId),
    queryFn: () => fuelRepository.stats(vehicleId),
    enabled: !!vehicleId,
  });
}
