/**
 * Labeled date field (value + calendar icon) for the maintenance form/sheet.
 * Same year/month/day `BottomSheetPickerField` picker as
 * `features/fuel-logs/components/fuel-date-picker.tsx` (no native date-picker
 * dependency — CLAUDE.md: no new deps without flagging), styled as a full
 * form field instead of a chip.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useState } from 'react';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { Colors, Radii, Spacing } from '@/constants/theme';

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

function pad2(n: number): string {
  return n.toString().padStart(2, '0');
}

export function todayText(): string {
  const now = new Date();
  return `${now.getFullYear()}-${pad2(now.getMonth() + 1)}-${pad2(now.getDate())}`;
}

function daysInMonth(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate();
}

function parseDateText(text: string): Date {
  const parsed = new Date(text);
  return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
}

type Props = {
  label: string;
  value: string;
  onChange: (dateText: string) => void;
  error?: string | null;
};

export function MaintenanceDateField({ label, value, onChange, error }: Props) {
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState<Date>(() => parseDateText(value));

  const openPicker = () => {
    setDraft(parseDateText(value));
    setOpen(true);
  };

  const confirm = () => {
    onChange(`${draft.getFullYear()}-${pad2(draft.getMonth() + 1)}-${pad2(draft.getDate())}`);
    setOpen(false);
  };

  const years = Array.from({ length: new Date().getFullYear() - 2000 + 1 }, (_, i) => 2000 + i);
  const maxDay = daysInMonth(draft.getFullYear(), draft.getMonth());
  const days = Array.from({ length: maxDay }, (_, i) => i + 1);

  const setYear = (year: number) => {
    const clampedDay = Math.min(draft.getDate(), daysInMonth(year, draft.getMonth()));
    setDraft(new Date(year, draft.getMonth(), clampedDay));
  };
  const setMonth = (monthIndex: number) => {
    const clampedDay = Math.min(draft.getDate(), daysInMonth(draft.getFullYear(), monthIndex));
    setDraft(new Date(draft.getFullYear(), monthIndex, clampedDay));
  };
  const setDay = (day: number) => setDraft(new Date(draft.getFullYear(), draft.getMonth(), day));

  return (
    <View style={styles.fieldGap}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <Pressable
        accessibilityRole="button"
        onPress={openPicker}
        style={[styles.fieldInputWrap, !!error && styles.fieldInputWrapError]}
      >
        <Text style={styles.value}>{value}</Text>
        <Ionicons name="calendar-outline" size={18} color={Colors.textMuted} />
      </Pressable>
      {error ? <Text style={styles.fieldError}>{error}</Text> : null}

      <Modal visible={open} transparent animationType="slide" onRequestClose={() => setOpen(false)}>
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)} accessibilityLabel="Dismiss" />
        <View style={styles.sheet}>
          <SafeAreaView edges={['bottom']}>
            <View style={styles.body}>
              <Text style={styles.title}>Select date</Text>
              <View style={styles.row}>
                <View style={styles.col2}>
                  <BottomSheetPickerField
                    label="Day"
                    value={draft.getDate()}
                    options={days}
                    getOptionLabel={(d) => String(d)}
                    onSelect={setDay}
                  />
                </View>
                <View style={styles.col3}>
                  <BottomSheetPickerField
                    label="Month"
                    value={draft.getMonth()}
                    options={MONTHS.map((_, i) => i)}
                    getOptionLabel={(i) => MONTHS[i]}
                    onSelect={setMonth}
                  />
                </View>
                <View style={styles.col2}>
                  <BottomSheetPickerField
                    label="Year"
                    value={draft.getFullYear()}
                    options={years}
                    getOptionLabel={(y) => String(y)}
                    onSelect={setYear}
                  />
                </View>
              </View>
              <AppButton label="Done" onPress={confirm} style={styles.confirm} />
            </View>
          </SafeAreaView>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  fieldGap: {
    marginBottom: Spacing.two + 8,
  },
  fieldLabel: {
    fontSize: 12,
    color: Colors.textMuted,
    marginBottom: 4,
  },
  fieldInputWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    minHeight: 52,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
  },
  fieldInputWrapError: {
    borderColor: Colors.danger,
  },
  value: {
    fontSize: 16,
    color: Colors.textPrimary,
  },
  fieldError: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.danger,
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
  body: {
    padding: 16,
  },
  title: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 12,
  },
  row: {
    flexDirection: 'row',
    columnGap: 8,
  },
  col2: {
    flex: 2,
  },
  col3: {
    flex: 3,
  },
  confirm: {
    marginTop: 16,
  },
});
