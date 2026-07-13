/**
 * Add/edit maintenance record form. Parity with Flutter
 * `maintenance_form_screen.dart`.
 *
 * Deviation from the Dart source: `docs/ui-conventions.md` is explicit that
 * destructive actions belong on detail/view screens, not edit forms (the Dart
 * form has a "Delete Service Record" button at the bottom). Per CLAUDE.md the
 * docs win on this point, so delete lives on the vehicle-detail maintenance
 * row instead (`detail-maintenance-section.tsx`) — this form has no delete
 * button.
 */

import { useState } from 'react';
import {
  Keyboard,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { FormScreenAppBar } from '@/components/form-screen-app-bar';
import { Colors, Radii, Spacing } from '@/constants/theme';
import { useMe } from '@/features/profile/hooks';
import { useVehicle } from '@/features/vehicles/hooks';
import { displayToKm, effectiveUnit, kmToDisplay } from '@/lib/distance-unit';
import { useCreateMaintenanceRecord, useUpdateMaintenanceRecord } from '../hooks';
import { kServiceTypeSuggestions } from '../service-type-suggestions';
import type { CreateMaintenancePayload, MaintenanceRecord } from '../types';
import { MaintenanceDateField, todayText } from './maintenance-date-field';

const CATEGORIES = ['maintenance', 'repair', 'inspection', 'other'] as const;

function titleCase(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

type Props = {
  vehicleId: string;
  existing?: MaintenanceRecord;
  initialServiceType?: string;
  initialCost?: string;
  initialOdometer?: string;
  initialDate?: string;
  onDone: () => void;
};

export function MaintenanceFormScreen({
  vehicleId,
  existing,
  initialServiceType,
  initialCost,
  initialOdometer,
  initialDate,
  onDone,
}: Props) {
  const isEdit = existing != null;
  const { data: vehicle } = useVehicle(vehicleId);
  const { data: me } = useMe();
  const createRecord = useCreateMaintenanceRecord(vehicleId);
  const updateRecord = useUpdateMaintenanceRecord(vehicleId);

  const unit = effectiveUnit(vehicle?.distanceUnit ?? null, me?.distanceUnit ?? 'km');

  const [dateText, setDateText] = useState(existing?.date ?? initialDate ?? todayText());
  const [serviceType, setServiceType] = useState(existing?.serviceType ?? initialServiceType ?? '');
  const [odometerText, setOdometerText] = useState(() => {
    if (existing?.odometer != null) return String(Math.round(kmToDisplay(existing.odometer, unit)));
    return initialOdometer ?? '';
  });
  const [category, setCategory] = useState<string | null>(existing?.category ?? null);
  const [costText, setCostText] = useState(
    existing?.costCents != null ? (existing.costCents / 100).toFixed(2) : (initialCost ?? ''),
  );
  const [workshop, setWorkshop] = useState(existing?.workshop ?? '');
  const [notes, setNotes] = useState(existing?.notes ?? '');
  const [saving, setSaving] = useState(false);
  const [dateError, setDateError] = useState<string | null>(null);
  const [serviceTypeError, setServiceTypeError] = useState<string | null>(null);
  const [odometerError, setOdometerError] = useState<string | null>(null);
  const [costError, setCostError] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  function validate(): boolean {
    let ok = true;
    if (!dateText) {
      setDateError('Required');
      ok = false;
    } else setDateError(null);

    if (!serviceType.trim()) {
      setServiceTypeError('Required');
      ok = false;
    } else setServiceTypeError(null);

    if (odometerText.trim() && !/^\d+$/.test(odometerText.trim())) {
      setOdometerError('Invalid integer');
      ok = false;
    } else setOdometerError(null);

    if (costText.trim() && Number.isNaN(Number(costText.trim()))) {
      setCostError('Invalid number');
      ok = false;
    } else setCostError(null);

    return ok;
  }

  async function save() {
    if (!validate()) return;
    Keyboard.dismiss();
    setSaving(true);
    setSaveError(null);
    try {
      const odomTrim = odometerText.trim();
      const costTrim = costText.trim();

      // currency intentionally omitted — backend forces it to LKR (Doc 3).
      const payload: CreateMaintenancePayload = {
        date: dateText,
        serviceType: serviceType.trim(),
        ...(odomTrim ? { odometer: displayToKm(Number(odomTrim), unit) } : {}),
        ...(category != null ? { category } : {}),
        ...(costTrim ? { costCents: Math.round(Number(costTrim) * 100) } : {}),
        ...(workshop.trim() ? { workshop: workshop.trim() } : {}),
        ...(notes.trim() ? { notes: notes.trim() } : {}),
      };

      if (existing) {
        await updateRecord.mutateAsync({ id: existing.id, payload });
      } else {
        await createRecord.mutateAsync(payload);
      }
      onDone();
    } catch (e) {
      setSaveError(e instanceof Error ? e.message : 'Could not save');
    } finally {
      setSaving(false);
    }
  }

  return (
    <View style={styles.screen}>
      <FormScreenAppBar
        title={isEdit ? 'Edit Service Record' : 'Add Service Record'}
        saving={saving}
        onCancel={onDone}
        onSave={save}
      />
      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <MaintenanceDateField label="Date *" value={dateText} onChange={setDateText} error={dateError} />

        <Field
          label="Service Type *"
          placeholder="e.g. Oil Change"
          value={serviceType}
          onChangeText={setServiceType}
          error={serviceTypeError}
        />

        <View style={styles.chips}>
          {kServiceTypeSuggestions.map((s) => (
            <Pressable key={s} onPress={() => setServiceType(s)} style={styles.chip}>
              <Text style={styles.chipText}>{s}</Text>
            </Pressable>
          ))}
        </View>

        <Field
          label={`Odometer (${unit})`}
          placeholder=""
          value={odometerText}
          onChangeText={setOdometerText}
          keyboardType="number-pad"
          error={odometerError}
        />

        <View style={styles.fieldGap}>
          <BottomSheetPickerField
            label="Category"
            sheetTitle="Select category"
            value={category}
            options={[...CATEGORIES]}
            getOptionLabel={titleCase}
            onSelect={setCategory}
          />
        </View>

        <Field
          label="Cost"
          placeholder="65.00"
          value={costText}
          onChangeText={setCostText}
          keyboardType="decimal-pad"
          error={costError}
        />

        <Field label="Workshop" placeholder="" value={workshop} onChangeText={setWorkshop} />

        <Field label="Notes" placeholder="" value={notes} onChangeText={setNotes} multiline />

        {saveError ? <Text style={styles.saveError}>{saveError}</Text> : null}
      </ScrollView>
    </View>
  );
}

type FieldProps = {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'number-pad' | 'decimal-pad';
  error?: string | null;
  multiline?: boolean;
};

function Field({ label, value, onChangeText, placeholder, keyboardType = 'default', error, multiline }: FieldProps) {
  return (
    <View style={styles.fieldGap}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <View style={[styles.fieldInputWrap, !!error && styles.fieldInputWrapError, multiline && styles.fieldMultiline]}>
        <TextInput
          style={[styles.fieldInput, multiline && styles.fieldInputMultiline]}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={Colors.textMuted}
          keyboardType={keyboardType}
          multiline={multiline}
          numberOfLines={multiline ? 3 : 1}
        />
      </View>
      {error ? <Text style={styles.fieldError}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.surface,
  },
  content: {
    padding: Spacing.three,
    paddingBottom: 100,
  },
  fieldGap: {
    marginBottom: Spacing.two + 8,
  },
  fieldLabel: {
    fontSize: 12,
    color: Colors.textMuted,
    marginBottom: 4,
  },
  fieldInputWrap: {
    minHeight: 52,
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
  },
  fieldInputWrapError: {
    borderColor: Colors.danger,
  },
  fieldMultiline: {
    minHeight: 80,
    paddingVertical: 10,
  },
  fieldInput: {
    fontSize: 16,
    color: Colors.textPrimary,
    paddingVertical: 14,
  },
  fieldInputMultiline: {
    paddingVertical: 0,
    textAlignVertical: 'top',
  },
  fieldError: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.danger,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: Spacing.two + 8,
    columnGap: 8,
    rowGap: 8,
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
  saveError: {
    marginTop: 4,
    color: Colors.danger,
  },
});
