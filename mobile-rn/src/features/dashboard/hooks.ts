/** Server state for the dashboard feature, backed by a local SQLite read-cache. */

import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { getCachedDashboard, upsertDashboard } from './local';
import { dashboardRepository } from './repository';

export const dashboardQueryKey = ['dashboard'] as const;

export function useDashboard() {
  const queryClient = useQueryClient();

  useEffect(() => {
    let cancelled = false;
    getCachedDashboard().then((cached) => {
      if (cancelled || cached == null) return;
      if (queryClient.getQueryData(dashboardQueryKey) === undefined) {
        queryClient.setQueryData(dashboardQueryKey, cached);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [queryClient]);

  return useQuery({
    queryKey: dashboardQueryKey,
    queryFn: async () => {
      const data = await dashboardRepository.get();
      void upsertDashboard(data);
      return data;
    },
  });
}
