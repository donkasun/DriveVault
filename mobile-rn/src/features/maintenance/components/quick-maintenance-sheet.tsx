/**
 * Lightweight quick maintenance-entry sheet. Parity with Flutter
 * `quick_maintenance_sheet.dart`. "Full details" opens the full
 * `MaintenanceFormScreen` (as a full-screen modal here — RN has no
 * `Navigator.push(fullscreenDialog: true)` outside a route stack) seeded with
 * whatever the user already typed.
 */

import { useState } from 'react';
import { ActivityIndicator, Modal, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { Colors, Radii, Spacing } from '@/constants/theme';
import { useMe } from '@/features/profile/hooks';
import { useVehicles } from '@/features/vehicles/hooks';
import { displayToKm, effectiveUnit, kmToDisplay } from '@/lib/distance-unit';
import { useCreateMaintenanceRecord } from '../hooks';
import { kServiceTypeSuggestions } from '../service-type-suggestions';
import type { CreateMaintenancePayload } from '../types';
import { MaintenanceDateField, todayText } from './maintenance-date-field';
import { MaintenanceFormScreen } from './maintenance-form-screen';

type Props = {
  visible: boolean;
  /** Pre-selects a vehicle; omit to let the user pick when they own more than one. */
  vehicleId?: string;
  onClose: () => void;
};

export function QuickMaintenanceSheet({ visible, vehicleId, onClose }: Props) {
  const vehiclesQuery = useVehicles();
  const meQuery = useMe();

  const [selectedVehicleId, setSelectedVehicleId] = useState<string | null>(vehicleId ?? null);
  const [serviceType, setServiceType] = useState('');
  const [costText, setCostText] = useState('');
  const [odometerText, setOdometerText] = useState('');
  const [dateText, setDateText] = useState(todayText());
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fullDetailsOpen, setFullDetailsOpen] = useState(false);
  const [wasVisible, setWasVisible] = useState(visible);

  const createRecord = useCreateMaintenanceRecord(selectedVehicleId ?? '');

  const vehicles = vehiclesQuery.data ?? [];
  const selected = vehicles.find((v) => v.id === selectedVehicleId);
  const unit = effectiveUnit(selected?.distanceUnit ?? null, meQuery.data?.distanceUnit ?? 'km');
  const odoHint =
    selected?.currentMileage != null ? String(Math.round(kmToDisplay(selected.currentMileage, unit))) : undefined;

  // Reset to a clean slate each time the sheet opens (Dart builds a fresh widget instance).
  if (visible !== wasVisible) {
    setWasVisible(visible);
    if (visible) {
      setSelectedVehicleId(vehicleId ?? null);
      setServiceType('');
      setCostText('');
      setOdometerText('');
      setDateText(todayText());
      setError(null);
    }
  }

  if (!selectedVehicleId && vehicles.length === 1) {
    setSelectedVehicleId(vehicles[0].id);
  }

  function buildPayload(): CreateMaintenancePayload {
    const costTrim = costText.trim();
    const odoTrim = odometerText.trim();
    return {
      date: dateText,
      serviceType: serviceType.trim(),
      ...(costTrim ? { costCents: Math.round(Number(costTrim) * 100) } : {}),
      ...(odoTrim ? { odometer: displayToKm(Number(odoTrim), unit) } : {}),
    };
  }

  async function save() {
    if (!selectedVehicleId) {
      setError('Please select a vehicle');
      return;
    }
    if (!serviceType.trim()) {
      setError('Enter a service type');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await createRecord.mutateAsync(buildPayload());
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not save');
      setSaving(false);
    }
  }

  function openFullDetails() {
    if (!selectedVehicleId) {
      setError('Please select a vehicle');
      return;
    }
    setFullDetailsOpen(true);
  }

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} accessibilityLabel="Dismiss" />
      <View style={styles.sheet}>
        <SafeAreaView edges={['bottom']}>
          <ScrollView contentContainerStyle={styles.body} keyboardShouldPersistTaps="handled">
            <Text style={styles.title}>Log service</Text>

            {vehicleId == null && vehicles.length > 1 ? (
              <View style={styles.fieldGap}>
                <BottomSheetPickerField
                  label="Vehicle"
                  value={selected}
                  options={vehicles}
                  getOptionLabel={(v) => `${v.make} ${v.model}`}
                  getOptionKey={(v) => v.id}
                  onSelect={(v) => setSelectedVehicleId(v.id)}
                />
              </View>
            ) : null}

            <View style={styles.chips}>
              {kServiceTypeSuggestions.map((s) => (
                <Pressable key={s} onPress={() => setServiceType(s)} style={styles.chip}>
                  <Text style={styles.chipText}>{s}</Text>
                </Pressable>
              ))}
            </View>

            <TextInput
              testID="qm-service-type"
              style={styles.input}
              value={serviceType}
              onChangeText={setServiceType}
              placeholder="Service type *"
              placeholderTextColor={Colors.textMuted}
            />

            <TextInput
              testID="qm-cost"
              style={[styles.input, styles.fieldGap]}
              value={costText}
              onChangeText={setCostText}
              placeholder="Cost"
              placeholderTextColor={Colors.textMuted}
              keyboardType="decimal-pad"
            />

            <TextInput
              testID="qm-odometer"
              style={[styles.input, styles.fieldGap]}
              value={odometerText}
              onChangeText={setOdometerText}
              placeholder={odoHint ? `Odometer (${unit}) — ${odoHint}` : `Odometer (${unit})`}
              placeholderTextColor={Colors.textMuted}
              keyboardType="number-pad"
            />

            <MaintenanceDateField label="Date" value={dateText} onChange={setDateText} />

            {error ? <Text style={styles.error}>{error}</Text> : null}

            <AppButton label="Save" onPress={save} loading={saving} disabled={saving} style={styles.saveButton} />
            <Pressable accessibilityRole="button" disabled={saving} onPress={openFullDetails} style={styles.fullDetails}>
              <Text style={styles.fullDetailsText}>Full details</Text>
            </Pressable>
          </ScrollView>
        </SafeAreaView>
      </View>

      <Modal visible={fullDetailsOpen} animationType="slide" onRequestClose={() => setFullDetailsOpen(false)}>
        {selectedVehicleId ? (
          <MaintenanceFormScreen
            vehicleId={selectedVehicleId}
            initialServiceType={serviceType.trim() || undefined}
            initialCost={costText.trim() || undefined}
            initialOdometer={odometerText.trim() || undefined}
            initialDate={dateText}
            onDone={() => {
              setFullDetailsOpen(false);
              onClose();
            }}
          />
        ) : (
          <ActivityIndicator size="large" color={Colors.textPrimary} />
        )}
      </Modal>
    </Modal>
  );
}

const styles = StyleSheet.create({
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
    maxHeight: '90%',
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
  },
  body: {
    padding: Spacing.three,
    paddingBottom: 24,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: 16,
  },
  fieldGap: {
    marginTop: 12,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    columnGap: 8,
    rowGap: 8,
    marginBottom: 12,
  },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: Radii.pill,
    borderWidth: 1,
    borderColor: Colors.divider,
    backgroundColor: Colors.background,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  input: {
    minHeight: 52,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
    fontSize: 16,
    color: Colors.textPrimary,
  },
  error: {
    marginTop: 12,
    color: Colors.danger,
  },
  saveButton: {
    marginTop: 16,
  },
  fullDetails: {
    marginTop: 8,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  fullDetailsText: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
});
