/** Server state for the maintenance feature. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { maintenanceRepository } from './repository';
import type { CreateMaintenancePayload, UpdateMaintenancePayload } from './types';

export const maintenanceQueryKey = (vehicleId: string) =>
  ['vehicles', vehicleId, 'maintenance'] as const;

export function useMaintenanceRecords(vehicleId: string) {
  return useQuery({
    queryKey: maintenanceQueryKey(vehicleId),
    queryFn: () => maintenanceRepository.listForVehicle(vehicleId),
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
    onSuccess: () => invalidate(queryClient, vehicleId),
  });
}

export function useUpdateMaintenanceRecord(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateMaintenancePayload }) =>
      maintenanceRepository.update(id, payload),
    onSuccess: () => invalidate(queryClient, vehicleId),
  });
}

export function useDeleteMaintenanceRecord(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => maintenanceRepository.remove(id),
    onSuccess: () => invalidate(queryClient, vehicleId),
  });
}
