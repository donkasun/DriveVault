/**
 * Date chip + picker modal for the quick fuel-entry sheet's header.
 * Flutter uses the native Material date picker (`showDatePicker`); RN has no
 * equivalent without a new dependency (CLAUDE.md: no new deps without
 * flagging), so this reuses the existing `BottomSheetPickerField` primitive
 * for year/month/day — same visual language as the rest of the app.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useState } from 'react';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { AppButton } from '@/components/app-button';
import { Colors } from '@/constants/theme';

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

function pad2(n: number): string {
  return n.toString().padStart(2, '0');
}

export function dateToText(d: Date): string {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function daysInMonth(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate();
}

type Props = {
  value: Date;
  onChange: (date: Date) => void;
};

export function FuelDateChip({ value, onChange }: Props) {
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState(value);

  const openPicker = () => {
    setDraft(value);
    setOpen(true);
  };

  const confirm = () => {
    onChange(draft);
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
    <>
      <Pressable accessibilityRole="button" testID="fuel_date_chip" onPress={openPicker} style={styles.chip}>
        <Ionicons name="calendar-outline" size={14} color={Colors.textMuted} />
        <Text style={styles.chipText}>{dateToText(value)}</Text>
      </Pressable>

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
    </>
  );
}

const styles = StyleSheet.create({
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: Colors.background,
  },
  chipText: {
    marginLeft: 4,
    fontSize: 13,
    color: Colors.textMuted,
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
