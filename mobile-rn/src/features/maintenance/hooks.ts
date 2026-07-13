/** Server state for the maintenance feature, backed by a local SQLite read-cache. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import {
  deleteCachedMaintenanceRecord,
  getCachedMaintenanceRecords,
  upsertMaintenanceRecord,
  upsertMaintenanceRecords,
} from './local';
import { maintenanceRepository } from './repository';
import type { CreateMaintenancePayload, UpdateMaintenancePayload } from './types';

export const maintenanceQueryKey = (vehicleId: string) =>
  ['vehicles', vehicleId, 'maintenance'] as const;

/** Seeds the maintenance query cache from SQLite on first mount, if the query has no data yet. */
function useMaintenanceCacheSeed(vehicleId: string) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!vehicleId) return;
    let cancelled = false;
    getCachedMaintenanceRecords(vehicleId).then((cached) => {
      if (cancelled || cached.length === 0) return;
      const key = maintenanceQueryKey(vehicleId);
      if (queryClient.getQueryData(key) === undefined) {
        queryClient.setQueryData(key, cached);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [queryClient, vehicleId]);
}

export function useMaintenanceRecords(vehicleId: string) {
  useMaintenanceCacheSeed(vehicleId);

  return useQuery({
    queryKey: maintenanceQueryKey(vehicleId),
    queryFn: async () => {
      const records = await maintenanceRepository.listForVehicle(vehicleId);
      void upsertMaintenanceRecords(records);
      return records;
    },
    enabled: !!vehicleId,
  });
}

function invalidate(queryClient: ReturnType<typeof useQueryClient>, vehicleId: string) {
  queryClient.invalidateQueries({ queryKey: maintenanceQueryKey(vehicleId) });
  queryClient.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateMaintenanceRecord(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateMaintenancePayload) =>
      maintenanceRepository.create(vehicleId, payload),
    onSuccess: (record) => {
      void upsertMaintenanceRecord(record);
      invalidate(queryClient, vehicleId);
    },
  });
}

export function useUpdateMaintenanceRecord(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateMaintenancePayload }) =>
      maintenanceRepository.update(id, payload),
    onSuccess: (record) => {
      void upsertMaintenanceRecord(record);
      invalidate(queryClient, vehicleId);
    },
  });
}

export function useDeleteMaintenanceRecord(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => maintenanceRepository.remove(id),
    onSuccess: (_data, id) => {
      void deleteCachedMaintenanceRecord(id);
      invalidate(queryClient, vehicleId);
    },
  });
}
