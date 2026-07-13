/** Server state for the vehicles feature. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { vehiclesRepository } from './repository';
import type { CreateVehiclePayload, UpdateVehiclePayload, Vehicle } from './types';

export const vehiclesQueryKey = ['vehicles'] as const;
export const vehicleQueryKey = (id: string) => ['vehicles', id] as const;

export function useVehicles() {
  return useQuery({
    queryKey: vehiclesQueryKey,
    queryFn: () => vehiclesRepository.list(),
  });
}

export function useVehicle(id: string) {
  return useQuery({
    queryKey: vehicleQueryKey(id),
    queryFn: () => vehiclesRepository.get(id),
    enabled: !!id,
  });
}

/** Anything that changes a vehicle also changes the garage list and the dashboard. */
function invalidateVehicleViews(queryClient: ReturnType<typeof useQueryClient>) {
  queryClient.invalidateQueries({ queryKey: vehiclesQueryKey });
  queryClient.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateVehicle() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateVehiclePayload) => vehiclesRepository.create(payload),
    onSuccess: () => invalidateVehicleViews(queryClient),
  });
}

export function useUpdateVehicle(id: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdateVehiclePayload) => vehiclesRepository.update(id, payload),
    onSuccess: (vehicle: Vehicle) => {
      queryClient.setQueryData(vehicleQueryKey(id), vehicle);
      invalidateVehicleViews(queryClient);
    },
  });
}

export function useDeleteVehicle() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => vehiclesRepository.remove(id),
    onSuccess: (_data, id) => {
      queryClient.removeQueries({ queryKey: vehicleQueryKey(id) });
      invalidateVehicleViews(queryClient);
    },
  });
}
