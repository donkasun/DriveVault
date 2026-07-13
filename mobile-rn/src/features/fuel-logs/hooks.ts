/** Server state for the fuel feature. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { fuelRepository } from './repository';
import type { CreateFuelLogPayload, UpdateFuelLogPayload } from './types';

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

/** Every fuel-log mutation touches this same set of views (task spec). */
function invalidateFuelViews(queryClient: ReturnType<typeof useQueryClient>, vehicleId: string) {
  queryClient.invalidateQueries({ queryKey: fuelLogsQueryKey(vehicleId) });
  queryClient.invalidateQueries({ queryKey: fuelStatsQueryKey(vehicleId) });
  queryClient.invalidateQueries({ queryKey: ['vehicles'] });
  queryClient.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateFuelLog(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateFuelLogPayload) => fuelRepository.create(vehicleId, payload),
    onSuccess: () => invalidateFuelViews(queryClient, vehicleId),
  });
}

export function useUpdateFuelLog(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateFuelLogPayload }) =>
      fuelRepository.update(id, payload),
    onSuccess: () => invalidateFuelViews(queryClient, vehicleId),
  });
}

export function useDeleteFuelLog(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => fuelRepository.remove(id),
    onSuccess: () => invalidateFuelViews(queryClient, vehicleId),
  });
}
