/** Server state for the profile feature. Components never call the repository directly. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { profileRepository } from './repository';
import type { AppUser, UpdateMePayload } from './types';

export const meQueryKey = ['me'] as const;

export function useMe() {
  return useQuery({
    queryKey: meQueryKey,
    queryFn: () => profileRepository.getMe(),
  });
}

export function useUpdateMe() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdateMePayload) => profileRepository.updateMe(payload),
    onSuccess: (user: AppUser) => {
      // PATCH /me returns the updated user — seed the cache rather than refetch.
      queryClient.setQueryData(meQueryKey, user);
      // Currency/distance changes alter money and odometer strings app-wide.
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      queryClient.invalidateQueries({ queryKey: ['vehicles'] });
    },
  });
}
