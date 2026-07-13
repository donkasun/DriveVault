/** Server state for the fuel feature, backed by a local SQLite read-cache. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { deleteCachedFuelLog, getCachedFuelLogs, upsertFuelLog, upsertFuelLogs } from './local';
import { fuelRepository } from './repository';
import type { CreateFuelLogPayload, UpdateFuelLogPayload } from './types';

export const fuelLogsQueryKey = (vehicleId: string) =>
  ['vehicles', vehicleId, 'fuel-logs'] as const;
export const fuelStatsQueryKey = (vehicleId: string) => ['fuel-stats', vehicleId] as const;

/** Seeds the fuel-logs query cache from SQLite on first mount, if the query has no data yet. */
function useFuelLogsCacheSeed(vehicleId: string) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!vehicleId) return;
    let cancelled = false;
    getCachedFuelLogs(vehicleId).then((cached) => {
      if (cancelled || cached.length === 0) return;
      const key = fuelLogsQueryKey(vehicleId);
      if (queryClient.getQueryData(key) === undefined) {
        queryClient.setQueryData(key, cached);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [queryClient, vehicleId]);
}

export function useFuelLogs(vehicleId: string) {
  useFuelLogsCacheSeed(vehicleId);

  return useQuery({
    queryKey: fuelLogsQueryKey(vehicleId),
    queryFn: async () => {
      const logs = await fuelRepository.listForVehicle(vehicleId);
      void upsertFuelLogs(logs);
      return logs;
    },
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
    onSuccess: (fuelLog) => {
      void upsertFuelLog(fuelLog);
      invalidateFuelViews(queryClient, vehicleId);
    },
  });
}

export function useUpdateFuelLog(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateFuelLogPayload }) =>
      fuelRepository.update(id, payload),
    onSuccess: (fuelLog) => {
      void upsertFuelLog(fuelLog);
      invalidateFuelViews(queryClient, vehicleId);
    },
  });
}

export function useDeleteFuelLog(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => fuelRepository.remove(id),
    onSuccess: (_data, id) => {
      void deleteCachedFuelLog(id);
      invalidateFuelViews(queryClient, vehicleId);
    },
  });
}
