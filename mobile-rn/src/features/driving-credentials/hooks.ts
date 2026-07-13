/** Server state for the driving-credentials feature. */

import { useQuery } from '@tanstack/react-query';

import { drivingCredentialsRepository } from './repository';

export const drivingCredentialsQueryKey = ['driving-credentials'] as const;

export function useDrivingCredentials() {
  return useQuery({
    queryKey: drivingCredentialsQueryKey,
    queryFn: () => drivingCredentialsRepository.list(),
  });
}
