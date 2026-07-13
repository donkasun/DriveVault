/**
 * Vehicle detail screen. Parity with Flutter
 * `mobile/lib/features/vehicles/presentation/vehicle_detail_screen.dart`.
 *
 * Section order (top → bottom): hero photo header, 4-column stats card, Fuel,
 * Maintenance, Documents. Delete lives here (not on the edit form) per
 * `docs/ui-conventions.md`, behind a confirmation bottom sheet that matches the
 * Dart copy exactly.
 */

import { useCallback, useState } from 'react';
import { ActivityIndicator, Modal, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors, Radii } from '@/constants/theme';
import type { Document } from '@/features/documents/types';
import { QuickFuelEntrySheet } from '@/features/fuel-logs/components/quick-fuel-entry-sheet';
import type { MaintenanceRecord } from '@/features/maintenance/types';
import { useMe } from '@/features/profile/hooks';
import { effectiveUnit, formatDistance } from '@/lib/distance-unit';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { formatCents, formatEconomyFromStats } from '@/lib/formatting';
import { useFuelStats } from '@/features/fuel-logs/hooks';
import { useDeleteVehicle, useVehicle } from '../hooks';
import { DetailDocumentsSection } from './detail-documents-section';
import { DetailFuelSection } from './detail-fuel-section';
import { DetailHero } from './detail-hero';
import { DetailMaintenanceSection } from './detail-maintenance-section';
import { DetailStatsCard } from './detail-stats-card';

type Props = {
  vehicleId: string;
  onBack: () => void;
  onEditVehicle: (vehicleId: string) => void;
  onDeleted: () => void;
  onViewMoreFuel: (vehicleId: string) => void;
  onAddService: (vehicleId: string) => void;
  onOpenMaintenanceRecord: (vehicleId: string, record: MaintenanceRecord) => void;
  onUploadDocument: (vehicleId: string) => void;
  onOpenDocument: (vehicleId: string, doc: Document) => void;
};

export function VehicleDetailScreen({
  vehicleId,
  onBack,
  onEditVehicle,
  onDeleted,
  onViewMoreFuel,
  onAddService,
  onOpenMaintenanceRecord,
  onUploadDocument,
  onOpenDocument,
}: Props) {
  const { data: vehicle, isLoading, error } = useVehicle(vehicleId);
  const { data: me } = useMe();
  const { data: stats } = useFuelStats(vehicleId);
  const deleteVehicle = useDeleteVehicle();
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [fuelSheetOpen, setFuelSheetOpen] = useState(false);

  const handleDelete = useCallback(async () => {
    if (!vehicle) return;
    setDeleteError(null);
    try {
      await deleteVehicle.mutateAsync(vehicle.id);
      setConfirmingDelete(false);
      onDeleted();
    } catch (e) {
      setDeleteError(e instanceof Error ? e.message : 'Delete failed');
    }
  }, [deleteVehicle, vehicle, onDeleted]);

  if (isLoading) {
    return (
      <SafeAreaView style={styles.centerScreen} edges={['top']}>
        <ActivityIndicator size="large" color={Colors.textPrimary} />
      </SafeAreaView>
    );
  }

  if (error || !vehicle) {
    return (
      <SafeAreaView style={styles.centerScreen} edges={['top']}>
        <Text style={styles.errorText}>Failed to load vehicle: {String(error ?? 'not found')}</Text>
      </SafeAreaView>
    );
  }

  const unit = effectiveUnit(vehicle.distanceUnit, me?.distanceUnit ?? 'km');
  const currency = me?.currency ?? FALLBACK_CURRENCY;
  const mileage = vehicle.currentMileage != null ? formatDistance(vehicle.currentMileage, unit) : '—';
  const economy = formatEconomyFromStats(stats?.avgConsumptionLPer100Km, unit);
  const spent = formatCents(stats?.totalSpentCents ?? 0, currency);

  return (
    <View style={styles.screen}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <DetailHero
          vehicle={vehicle}
          onBack={onBack}
          onEdit={() => onEditVehicle(vehicle.id)}
          onDelete={() => setConfirmingDelete(true)}
        />

        <DetailStatsCard mileage={mileage} economy={economy} spent={spent} docsStatus={vehicle.docsStatus} />

        <DetailFuelSection
          vehicleId={vehicle.id}
          vehicleDistanceUnit={vehicle.distanceUnit}
          user={me}
          onAddFuel={() => setFuelSheetOpen(true)}
          onViewMore={() => onViewMoreFuel(vehicle.id)}
        />

        <DetailMaintenanceSection
          vehicleId={vehicle.id}
          user={me}
          onAddService={() => onAddService(vehicle.id)}
          onOpenRecord={(record) => onOpenMaintenanceRecord(vehicle.id, record)}
        />

        <DetailDocumentsSection
          vehicleId={vehicle.id}
          docsStatus={vehicle.docsStatus}
          onUpload={() => onUploadDocument(vehicle.id)}
          onOpenDocument={(doc) => onOpenDocument(vehicle.id, doc)}
        />
      </ScrollView>

      <DeleteConfirmSheet
        visible={confirmingDelete}
        vehicleLabel={`${vehicle.make} ${vehicle.model}`}
        deleting={deleteVehicle.isPending}
        error={deleteError}
        onConfirm={handleDelete}
        onCancel={() => {
          setConfirmingDelete(false);
          setDeleteError(null);
        }}
      />

      <QuickFuelEntrySheet
        visible={fuelSheetOpen}
        vehicleId={vehicle.id}
        onClose={() => setFuelSheetOpen(false)}
      />
    </View>
  );
}

function DeleteConfirmSheet({
  visible,
  vehicleLabel,
  deleting,
  error,
  onConfirm,
  onCancel,
}: {
  visible: boolean;
  vehicleLabel: string;
  deleting: boolean;
  error: string | null;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onCancel}>
      <Pressable style={styles.backdrop} onPress={onCancel} accessibilityLabel="Dismiss" />
      <View style={styles.sheet}>
        <SafeAreaView edges={['bottom']}>
          <View style={styles.sheetBody}>
            <Text style={styles.sheetTitle}>Delete &quot;{vehicleLabel}&quot;?</Text>
            <Text style={styles.sheetBody2}>
              All fuel logs, maintenance records, and documents for this vehicle will be permanently
              deleted.
            </Text>
            {error ? <Text style={styles.sheetError}>Error: {error}</Text> : null}

            <Pressable
              accessibilityRole="button"
              disabled={deleting}
              onPress={onConfirm}
              style={[styles.deleteButton, deleting && styles.deleteButtonDisabled]}
            >
              {deleting ? (
                <ActivityIndicator size="small" color="#FFFFFF" />
              ) : (
                <Text style={styles.deleteButtonLabel}>Delete Vehicle</Text>
              )}
            </Pressable>

            <Pressable accessibilityRole="button" disabled={deleting} onPress={onCancel} style={styles.cancelButton}>
              <Text style={styles.cancelButtonLabel}>Cancel</Text>
            </Pressable>
          </View>
        </SafeAreaView>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scrollContent: {
    paddingBottom: 120,
  },
  centerScreen: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background,
    paddingHorizontal: 32,
  },
  errorText: {
    color: Colors.danger,
    textAlign: 'center',
  },
  backdrop: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    marginTop: 'auto',
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
  },
  sheetBody: {
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 16,
  },
  sheetTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  sheetBody2: {
    marginTop: 8,
    color: Colors.textMuted,
  },
  sheetError: {
    marginTop: 12,
    color: Colors.danger,
  },
  deleteButton: {
    marginTop: 24,
    height: 48,
    borderRadius: Radii.pill,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.danger,
  },
  deleteButtonDisabled: {
    opacity: 0.7,
  },
  deleteButtonLabel: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 15,
  },
  cancelButton: {
    marginTop: 8,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cancelButtonLabel: {
    color: Colors.textPrimary,
    fontWeight: '500',
    fontSize: 15,
  },
});
