/**
 * Quick fuel-entry bottom sheet. Parity with Flutter
 * `quick_fuel_entry_sheet.dart` (`QuickFuelEntrySheet` / `showQuickFuelEntrySheet`).
 *
 * Orchestrates vehicle selection, the Liters/Total/Price-per-L derive-triple
 * (`FuelEntryCalc`, already ported/tested — not reimplemented here), the
 * custom numeric keypad, and save/create-or-update. Presentational pieces
 * live in sibling files to keep this under ~250 lines.
 *
 * State-seeding follows this codebase's established "render-phase conditional
 * setState" idiom (see `vehicle-form-screen.tsx`'s `seededVehicleId` guard)
 * rather than `useEffect`, and keeps the current `FuelEntryCalc` snapshot in
 * plain state (not a ref) — both are required by this project's stricter
 * React Compiler ESLint rules (no `setState` inside effects, no ref reads
 * during render).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useQueries } from '@tanstack/react-query';
import { useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors, Radii } from '@/constants/theme';
import { useMe } from '@/features/profile/hooks';
import { useVehicles } from '@/features/vehicles/hooks';
import { displayToKm, effectiveUnit, kmToDisplay } from '@/lib/distance-unit';
import { formatCents } from '@/lib/formatting';
import { FuelEntryCalc, type FuelField } from '../fuel-entry-calc';
import { fuelLogsQueryKey, useCreateFuelLog, useFuelLogs, useUpdateFuelLog } from '../hooks';
import { fuelRepository } from '../repository';
import type { FuelLog } from '../types';
import { dateToText, FuelDateChip } from './fuel-date-picker';
import { type ActiveField, FuelEntryFields } from './fuel-entry-fields';
import { FuelNumericKeypad } from './fuel-numeric-keypad';
import { FuelVehiclePickerModal, FuelVehicleSelector } from './fuel-vehicle-picker';

function parseNum(text: string): number | null {
  const trimmed = text.trim();
  if (trimmed === '') return null;
  const n = Number(trimmed);
  return Number.isNaN(n) ? null : n;
}

/** Rebuilds the calc from the three current field texts (parity with Dart's
 * `_syncCalcFromControllers`: the active field is applied last so it stays
 * authoritative). */
function syncCalc(field: FuelField, liters: string, total: string, perLiter: string): FuelEntryCalc {
  const litersNum = parseNum(liters);
  const totalNum = parseNum(total);
  const perLiterNum = parseNum(perLiter);
  const values: Record<FuelField, number | null> = { liters: litersNum, total: totalNum, perLiter: perLiterNum };

  const calc = new FuelEntryCalc(perLiterNum != null && perLiterNum > 0 ? perLiterNum : null);
  for (const f of ['liters', 'total', 'perLiter'] as FuelField[]) {
    if (f === field) continue;
    calc.setField(f, values[f]);
  }
  calc.setField(field, values[field]);
  return calc;
}

type Props = {
  visible: boolean;
  /** Pre-selects a vehicle; omit to let the user pick when they own more than one. */
  vehicleId?: string;
  /** Pass an existing log to edit it instead of creating a new one. */
  existing?: FuelLog;
  onClose: () => void;
};

export function QuickFuelEntrySheet({ visible, vehicleId, existing, onClose }: Props) {
  const vehiclesQuery = useVehicles();
  const meQuery = useMe();

  const [selectedVehicleId, setSelectedVehicleId] = useState<string | null>(
    vehicleId ?? existing?.vehicleId ?? null,
  );
  const [pickerOpen, setPickerOpen] = useState(false);
  const [date, setDate] = useState<Date>(() => {
    const parsed = existing ? new Date(existing.date) : new Date();
    return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
  });
  const [odoText, setOdoText] = useState('');
  const [litersText, setLitersText] = useState('');
  const [totalText, setTotalText] = useState('');
  const [perLiterText, setPerLiterText] = useState('');
  const [active, setActive] = useState<ActiveField>('odometer');
  const [isFullTank, setIsFullTank] = useState(existing?.isFullTank ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [latestOdometerKm, setLatestOdometerKm] = useState<number | null>(null);
  const [calc, setCalc] = useState<FuelEntryCalc>(() => new FuelEntryCalc());

  const [existingSeeded, setExistingSeeded] = useState(false);
  const [calcSeededForId, setCalcSeededForId] = useState<string | null>(null);
  const [ownSeedAttemptedForId, setOwnSeedAttemptedForId] = useState<string | null>(null);
  const [fallbackAttemptedForId, setFallbackAttemptedForId] = useState<string | null>(null);

  const createFuelLog = useCreateFuelLog(selectedVehicleId ?? '');
  const updateFuelLog = useUpdateFuelLog(selectedVehicleId ?? '');

  const vehicles = vehiclesQuery.data ?? [];
  const selected = vehicles.find((v) => v.id === selectedVehicleId);
  const selectedFuelType = selected?.fuelType ?? null;
  const unit = effectiveUnit(selected?.distanceUnit ?? null, meQuery.data?.distanceUnit ?? 'km');

  const fuelLogsQuery = useFuelLogs(selectedVehicleId ?? '');

  // Default to the vehicle with the most recent activity once vehicles load.
  if (!selectedVehicleId && vehicles.length > 0) {
    const sorted = [...vehicles].sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
    setSelectedVehicleId(sorted[0].id);
  }

  // Seed all fields from an existing log (edit mode) — runs once.
  if (existing && !existingSeeded) {
    setExistingSeeded(true);
    setCalcSeededForId(existing.vehicleId);

    const parsed = new Date(existing.date);
    if (!Number.isNaN(parsed.getTime())) setDate(parsed);

    setOdoText(String(Math.round(kmToDisplay(existing.odometer, unit))));
    const liters = existing.liters;
    const total = existing.priceCents / 100;
    const perLiter = liters > 0 ? total / liters : null;
    setLitersText(liters.toFixed(2));
    setTotalText(total.toFixed(2));
    if (perLiter != null) setPerLiterText(perLiter.toFixed(2));

    const seeded = new FuelEntryCalc(perLiter);
    seeded.setField('liters', liters);
    seeded.setField('total', total);
    setCalc(seeded);
  }

  // Seed price-per-liter + odometer hint from the selected vehicle's own latest log — once.
  if (
    !existing &&
    selectedVehicleId &&
    ownSeedAttemptedForId !== selectedVehicleId &&
    fuelLogsQuery.isSuccess
  ) {
    setOwnSeedAttemptedForId(selectedVehicleId);
    const logs = fuelLogsQuery.data;
    const latest = logs.length > 0 ? logs[0] : null;
    setLatestOdometerKm(latest?.odometer ?? selected?.currentMileage ?? null);

    if (latest && latest.liters > 0) {
      const perLiter = latest.priceCents / 100 / latest.liters;
      setPerLiterText(perLiter.toFixed(2));
      setCalc(new FuelEntryCalc(perLiter));
      setCalcSeededForId(selectedVehicleId);
    }
  }

  // Fallback: seed price from the latest same-fuel-type log across other vehicles.
  const otherVehicleIds = vehicles
    .filter((v) => v.id !== selectedVehicleId && (selectedFuelType == null || v.fuelType === selectedFuelType))
    .map((v) => v.id);
  const fallbackResults = useQueries({
    queries: otherVehicleIds.map((id) => ({
      queryKey: fuelLogsQueryKey(id),
      queryFn: () => fuelRepository.listForVehicle(id),
      enabled:
        !existing &&
        selectedVehicleId != null &&
        calcSeededForId !== selectedVehicleId &&
        ownSeedAttemptedForId === selectedVehicleId,
    })),
  });
  const fallbackSettled = fallbackResults.every((r) => !r.isLoading);

  if (
    !existing &&
    selectedVehicleId &&
    calcSeededForId !== selectedVehicleId &&
    ownSeedAttemptedForId === selectedVehicleId &&
    fallbackAttemptedForId !== selectedVehicleId &&
    fallbackSettled
  ) {
    setFallbackAttemptedForId(selectedVehicleId);
    for (let i = 0; i < otherVehicleIds.length; i++) {
      const logs = fallbackResults[i]?.data;
      if (!logs || logs.length === 0) continue;
      const latest = logs[0];
      if (latest.liters <= 0) continue;
      const perLiter = latest.priceCents / 100 / latest.liters;
      setPerLiterText(perLiter.toFixed(2));
      setCalc(new FuelEntryCalc(perLiter));
      setCalcSeededForId(selectedVehicleId);
      break;
    }
  }

  function selectVehicle(id: string) {
    setSelectedVehicleId(id);
    setCalcSeededForId(null);
    setOwnSeedAttemptedForId(null);
    setFallbackAttemptedForId(null);
    setLatestOdometerKm(null);
    setOdoText('');
    setLitersText('');
    setTotalText('');
    setPerLiterText('');
    setCalc(new FuelEntryCalc());
  }

  function onKeypadChange(newValue: string) {
    if (active === 'odometer') {
      setOdoText(newValue);
      return;
    }
    const field = active;
    let liters = litersText;
    let total = totalText;
    let perLiter = perLiterText;
    if (field === 'liters') {
      liters = newValue;
      setLitersText(newValue);
    } else if (field === 'total') {
      total = newValue;
      setTotalText(newValue);
    } else {
      perLiter = newValue;
      setPerLiterText(newValue);
    }
    const nextCalc = syncCalc(field, liters, total, perLiter);
    if (nextCalc.liters != null && field !== 'liters') setLitersText(nextCalc.liters.toFixed(2));
    else if (nextCalc.derivedField === 'liters' && field !== 'liters') setLitersText('');
    if (nextCalc.total != null && field !== 'total') setTotalText(nextCalc.total.toFixed(2));
    else if (nextCalc.derivedField === 'total' && field !== 'total') setTotalText('');
    if (nextCalc.pricePerLiter != null && field !== 'perLiter') setPerLiterText(nextCalc.pricePerLiter.toFixed(2));
    else if (nextCalc.derivedField === 'perLiter' && field !== 'perLiter') setPerLiterText('');
    setCalc(nextCalc);
  }

  const odoHintKm = latestOdometerKm ?? selected?.currentMileage ?? null;
  const odoHint = odoHintKm != null ? String(Math.round(kmToDisplay(odoHintKm, unit))) : null;

  const odoTrim = odoText.trim();
  const odoValid = odoTrim === '' ? latestOdometerKm != null : /^\d+$/.test(odoTrim);
  const canSave = !saving && selectedVehicleId != null && odoValid && calc.isComplete;

  const totalCents = calc.total != null ? Math.round(calc.total * 100) : null;
  const saveLabel = totalCents == null ? 'Save' : `Save · ${formatCents(totalCents, 'LKR')}`;

  const activeValue =
    active === 'odometer'
      ? odoText
      : active === 'liters'
        ? litersText
        : active === 'total'
          ? totalText
          : perLiterText;

  async function handleSave() {
    if (!canSave || !selectedVehicleId) return;
    setSaving(true);
    setError(null);
    try {
      const odometerKm = odoTrim !== '' ? displayToKm(Number(odoTrim), unit) : (latestOdometerKm as number);
      const liters = calc.liters as number;
      const priceCents = Math.round((calc.total as number) * 100);

      const payload = {
        date: dateToText(date),
        liters,
        priceCents,
        odometer: odometerKm,
        isFullTank,
        notes: existing?.notes ?? null,
      };

      if (existing) {
        await updateFuelLog.mutateAsync({ id: existing.id, payload });
      } else {
        await createFuelLog.mutateAsync(payload);
      }
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not save');
    } finally {
      setSaving(false);
    }
  }

  const loading = vehiclesQuery.isLoading || meQuery.isLoading;

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} accessibilityLabel="Dismiss" />
      <View style={styles.sheet}>
        <View style={styles.handle} />
        {loading ? (
          <SafeAreaView edges={['bottom']} style={styles.loadingBox}>
            <ActivityIndicator size="large" color={Colors.textPrimary} />
          </SafeAreaView>
        ) : vehiclesQuery.error || meQuery.error ? (
          <SafeAreaView edges={['bottom']} style={styles.loadingBox}>
            <Text style={styles.error}>Failed to load data</Text>
          </SafeAreaView>
        ) : (
          <SafeAreaView edges={['bottom']}>
            <ScrollView keyboardShouldPersistTaps="handled">
              <View style={styles.header}>
                <Text style={styles.title}>{existing ? 'Edit fill-up' : 'Log a fill-up'}</Text>
                <FuelDateChip value={date} onChange={setDate} />
                <View style={styles.headerGap} />
                <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={onClose} style={styles.closeButton}>
                  <Ionicons name="close" size={18} color={Colors.textPrimary} />
                </Pressable>
              </View>

              {vehicles.length > 0 ? (
                <FuelVehicleSelector vehicles={vehicles} selected={selected} onPress={() => setPickerOpen(true)} />
              ) : null}

              <FuelEntryFields
                unit={unit}
                odoText={odoText}
                odoHint={odoHint}
                litersText={litersText}
                totalText={totalText}
                perLiterText={perLiterText}
                derivedField={calc.derivedField}
                active={active}
                onFocusField={setActive}
                isFullTank={isFullTank}
                onToggleFullTank={setIsFullTank}
              />

              {error ? <Text style={styles.saveError}>{error}</Text> : null}

              <View style={styles.keypadGap} />
              <FuelNumericKeypad value={activeValue} onChange={onKeypadChange} />

              <View style={styles.actions}>
                <Pressable
                  accessibilityRole="button"
                  disabled={!canSave}
                  onPress={handleSave}
                  style={[styles.saveButton, !canSave && styles.saveButtonDisabled]}
                >
                  {saving ? (
                    <ActivityIndicator size="small" color={Colors.onPrimary} />
                  ) : (
                    <Text style={styles.saveLabel}>{saveLabel}</Text>
                  )}
                </Pressable>
              </View>
            </ScrollView>
          </SafeAreaView>
        )}
      </View>

      <FuelVehiclePickerModal
        visible={pickerOpen}
        vehicles={vehicles}
        selectedId={selectedVehicleId}
        onSelect={(id) => {
          setPickerOpen(false);
          selectVehicle(id);
        }}
        onClose={() => setPickerOpen(false)}
      />
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
    maxHeight: '92%',
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
  },
  handle: {
    alignSelf: 'center',
    width: 36,
    height: 4,
    borderRadius: 2,
    backgroundColor: Colors.divider,
    marginTop: 10,
    marginBottom: 2,
  },
  loadingBox: {
    paddingVertical: 60,
    alignItems: 'center',
  },
  error: {
    color: Colors.danger,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 12,
  },
  title: {
    flex: 1,
    fontSize: 16,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  headerGap: {
    width: 8,
  },
  closeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background,
  },
  saveError: {
    marginHorizontal: 16,
    marginTop: 4,
    fontSize: 13,
    color: Colors.danger,
  },
  keypadGap: {
    height: 10,
  },
  actions: {
    paddingHorizontal: 16,
    paddingTop: 6,
    paddingBottom: 8,
  },
  saveButton: {
    height: 50,
    borderRadius: Radii.field + 2,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.primary,
  },
  saveButtonDisabled: {
    opacity: 0.5,
  },
  saveLabel: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.onPrimary,
  },
});
