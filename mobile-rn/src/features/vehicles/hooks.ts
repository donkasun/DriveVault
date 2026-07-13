/** Server state for the vehicles feature, backed by a local SQLite read-cache. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import {
  deleteCachedVehicle,
  getCachedVehicle,
  getCachedVehicles,
  upsertVehicle,
  upsertVehicles,
} from './local';
import { vehiclesRepository } from './repository';
import type { CreateVehiclePayload, UpdateVehiclePayload, Vehicle } from './types';

export const vehiclesQueryKey = ['vehicles'] as const;
export const vehicleQueryKey = (id: string) => ['vehicles', id] as const;

/**
 * Seeds a query's cache entry from local SQLite the first time it's
 * observed, so a cold/offline launch renders the last-known data instantly
 * instead of a blank/loading screen. Only seeds if nothing is there yet —
 * never clobbers data the network has already delivered.
 */
function useCacheSeed<TQueryKey extends readonly unknown[], TData>(
  queryKey: TQueryKey,
  readCache: () => Promise<TData | null>,
) {
  const queryClient = useQueryClient();

  useEffect(() => {
    let cancelled = false;
    readCache().then((cached) => {
      if (cancelled || cached == null) return;
      if (queryClient.getQueryData(queryKey) === undefined) {
        queryClient.setQueryData<TData>(queryKey, cached);
      }
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [queryClient, JSON.stringify(queryKey)]);
}

export function useVehicles() {
  useCacheSeed(vehiclesQueryKey, async () => {
    const cached = await getCachedVehicles();
    return cached.length > 0 ? cached : null;
  });

  return useQuery({
    queryKey: vehiclesQueryKey,
    queryFn: async () => {
      const vehicles = await vehiclesRepository.list();
      void upsertVehicles(vehicles);
      return vehicles;
    },
  });
}

export function useVehicle(id: string) {
  useCacheSeed(vehicleQueryKey(id), () => getCachedVehicle(id));

  return useQuery({
    queryKey: vehicleQueryKey(id),
    queryFn: async () => {
      const vehicle = await vehiclesRepository.get(id);
      void upsertVehicle(vehicle);
      return vehicle;
    },
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
    onSuccess: (vehicle: Vehicle) => {
      void upsertVehicle(vehicle);
      invalidateVehicleViews(queryClient);
    },
  });
}

export function useUpdateVehicle(id: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdateVehiclePayload) => vehiclesRepository.update(id, payload),
    onSuccess: (vehicle: Vehicle) => {
      queryClient.setQueryData(vehicleQueryKey(id), vehicle);
      void upsertVehicle(vehicle);
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
      void deleteCachedVehicle(id);
      invalidateVehicleViews(queryClient);
    },
  });
}
