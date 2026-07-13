/**
 * Form field that looks like a dropdown but opens a modal bottom sheet to pick a
 * value. Parity with Flutter `shared/widgets/bottom_sheet_picker_field.dart`.
 *
 * Generic over the option type `T`. Presentational — no data fetching.
 */

import { useState } from 'react';
import {
  FlatList,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  View,
  type ListRenderItemInfo,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors, Radii, Spacing, Typography } from '@/constants/theme';

type Props<T> = {
  label: string;
  value: T | null | undefined;
  options: T[];
  onSelect: (option: T) => void;
  /** Renders the display text for an option — used for the closed field and default rows. */
  getOptionLabel: (option: T) => string;
  /** Stable key for list rendering. Defaults to the option's label. */
  getOptionKey?: (option: T, index: number) => string;
  /** Custom row renderer. Falls back to a label + checkmark row. */
  renderRow?: (option: T, isSelected: boolean) => React.ReactNode;
  placeholder?: string;
  sheetTitle?: string;
  enabled?: boolean;
  error?: string | null;
};

export function BottomSheetPickerField<T>({
  label,
  value,
  options,
  onSelect,
  getOptionLabel,
  getOptionKey,
  renderRow,
  placeholder = '',
  sheetTitle,
  enabled = true,
  error = null,
}: Props<T>) {
  const [open, setOpen] = useState(false);

  const displayText = value != null ? getOptionLabel(value) : placeholder;

  const handleSelect = (option: T) => {
    setOpen(false);
    onSelect(option);
  };

  return (
    <View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        accessibilityState={{ disabled: !enabled }}
        disabled={!enabled}
        onPress={() => setOpen(true)}
        style={[styles.field, !enabled && styles.fieldDisabled, !!error && styles.fieldError]}
      >
        <View style={styles.fieldText}>
          <Text style={styles.label}>{label}</Text>
          <Text
            style={[styles.value, !enabled && styles.valueDisabled]}
            numberOfLines={1}
          >
            {displayText}
          </Text>
        </View>
        <Text style={[styles.chevron, !enabled && styles.valueDisabled]}>⌄</Text>
      </Pressable>
      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      <Modal visible={open} transparent animationType="slide" onRequestClose={() => setOpen(false)}>
        <Pressable
          style={styles.backdrop}
          onPress={() => setOpen(false)}
          accessibilityLabel="Dismiss"
        />
        <View style={styles.sheet}>
          <SafeAreaView edges={['bottom']}>
            <View style={styles.handle} />
            <Text style={styles.sheetTitle}>{sheetTitle ?? label}</Text>
            <FlatList
              data={options}
              style={styles.list}
              keyExtractor={(option, index) =>
                getOptionKey ? getOptionKey(option, index) : `${getOptionLabel(option)}-${index}`
              }
              ItemSeparatorComponent={() => <View style={styles.separator} />}
              renderItem={({ item }: ListRenderItemInfo<T>) => {
                const isSelected = item === value;
                if (renderRow) {
                  return (
                    <Pressable onPress={() => handleSelect(item)}>
                      {renderRow(item, isSelected)}
                    </Pressable>
                  );
                }
                return (
                  <Pressable
                    accessibilityRole="button"
                    accessibilityState={{ selected: isSelected }}
                    style={styles.row}
                    onPress={() => handleSelect(item)}
                  >
                    <Text style={styles.rowLabel}>{getOptionLabel(item)}</Text>
                    {isSelected ? <Text style={styles.check}>✓</Text> : null}
                  </Pressable>
                );
              }}
            />
          </SafeAreaView>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    minHeight: 56,
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
    borderRadius: Radii.field,
    borderWidth: 1,
    borderColor: Colors.divider,
    backgroundColor: Colors.surface,
  },
  fieldDisabled: {
    opacity: 0.6,
  },
  fieldError: {
    borderColor: Colors.danger,
  },
  fieldText: {
    flex: 1,
  },
  label: {
    fontSize: 12,
    color: Colors.textMuted,
    marginBottom: 2,
  },
  value: {
    fontSize: 16,
    color: Colors.textPrimary,
  },
  valueDisabled: {
    color: Colors.textMuted,
  },
  chevron: {
    fontSize: 18,
    color: Colors.textPrimary,
    marginLeft: Spacing.two,
  },
  errorText: {
    marginTop: Spacing.one,
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
    maxHeight: '70%',
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
    marginTop: 8,
    marginBottom: 4,
  },
  sheetTitle: {
    ...Typography.titleMedium,
    color: Colors.textPrimary,
    paddingHorizontal: Spacing.three,
    paddingBottom: Spacing.two,
  },
  list: {
    maxHeight: 320,
  },
  separator: {
    height: 1,
    marginHorizontal: Spacing.three,
    backgroundColor: Colors.divider,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.three,
    paddingVertical: 14,
  },
  rowLabel: {
    fontSize: 15,
    color: Colors.textPrimary,
  },
  check: {
    fontSize: 16,
    color: Colors.textPrimary,
  },
});
