/** Server state for the driving-credentials feature. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { drivingCredentialsRepository } from './repository';
import type { CreateCredentialPayload, UpdateCredentialPayload } from './types';

export const drivingCredentialsQueryKey = ['driving-credentials'] as const;

export function useDrivingCredentials() {
  return useQuery({
    queryKey: drivingCredentialsQueryKey,
    queryFn: () => drivingCredentialsRepository.list(),
  });
}

export function useCreateCredential() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateCredentialPayload) => drivingCredentialsRepository.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: drivingCredentialsQueryKey });
    },
  });
}

export function useUpdateCredential(id: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdateCredentialPayload) => drivingCredentialsRepository.update(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: drivingCredentialsQueryKey });
    },
  });
}

export function useDeleteCredential() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => drivingCredentialsRepository.remove(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: drivingCredentialsQueryKey });
    },
  });
}
