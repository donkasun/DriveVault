/** Server state for the documents feature. */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { documentsRepository } from './repository';
import type { CreateDocumentPayload, UpdateDocumentPayload } from './types';

export const documentsQueryKey = (vehicleId: string) =>
  ['vehicles', vehicleId, 'documents'] as const;

export function useDocuments(vehicleId: string, docType?: string) {
  return useQuery({
    queryKey: docType ? [...documentsQueryKey(vehicleId), docType] : documentsQueryKey(vehicleId),
    queryFn: () => documentsRepository.listForVehicle(vehicleId, docType),
    enabled: !!vehicleId,
  });
}

/** Anything that changes a document also changes docsStatus on the vehicle + dashboard. */
function invalidate(queryClient: ReturnType<typeof useQueryClient>, vehicleId: string) {
  queryClient.invalidateQueries({ queryKey: documentsQueryKey(vehicleId) });
  queryClient.invalidateQueries({ queryKey: ['vehicles', vehicleId] });
  queryClient.invalidateQueries({ queryKey: ['vehicles'] });
  queryClient.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateDocument(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateDocumentPayload) => documentsRepository.create(vehicleId, payload),
    onSuccess: () => invalidate(queryClient, vehicleId),
  });
}

export function useUpdateDocument(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateDocumentPayload }) =>
      documentsRepository.update(id, payload),
    onSuccess: () => invalidate(queryClient, vehicleId),
  });
}

export function useDeleteDocument(vehicleId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => documentsRepository.remove(id),
    onSuccess: () => invalidate(queryClient, vehicleId),
  });
}
