/**
 * Maintenance domain types — Doc 3 `## Maintenance Records`.
 * Parity with Flutter `mobile/lib/features/maintenance/domain/maintenance_record.dart`.
 *
 * NOTE: the Dart `MaintenanceRecord` model does not parse `aiExtractionId` or
 * `updatedAt` even though Doc 3 lists them on the wire object. We trust Doc 3
 * (source of truth per CLAUDE.md) here and include both fields, typed nullable
 * so callers that never see them (mirroring Dart) still work.
 *
 * Money is integer cents; odometer is integer kilometres (CLAUDE.md).
 */

export type MaintenanceRecord = {
  id: string;
  vehicleId: string;
  date: string;
  odometer: number | null;
  serviceType: string;
  category: string | null;
  costCents: number | null;
  currency: string | null;
  workshop: string | null;
  notes: string | null;
  source: string;
  aiExtractionId: string | null;
  createdAt: string;
  updatedAt: string | null;
};

export type CreateMaintenancePayload = {
  date: string;
  serviceType: string;
  odometer?: number | null;
  category?: string | null;
  costCents?: number | null;
  currency?: string;
  workshop?: string | null;
  notes?: string | null;
};

export type UpdateMaintenancePayload = Partial<CreateMaintenancePayload>;
