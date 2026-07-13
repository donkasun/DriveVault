/** Server state for the dashboard feature. */

import { useQuery } from '@tanstack/react-query';

import { dashboardRepository } from './repository';

export const dashboardQueryKey = ['dashboard'] as const;

export function useDashboard() {
  return useQuery({
    queryKey: dashboardQueryKey,
    queryFn: () => dashboardRepository.get(),
  });
}
