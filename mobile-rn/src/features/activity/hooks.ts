/** Server state for the activity feature. */

import { useQuery } from '@tanstack/react-query';

import { activityRepository } from './repository';

export const activityQueryKey = (limit = 50) => ['activity', limit] as const;

export function useActivity(limit = 50) {
  return useQuery({
    queryKey: activityQueryKey(limit),
    queryFn: () => activityRepository.list(limit),
  });
}
