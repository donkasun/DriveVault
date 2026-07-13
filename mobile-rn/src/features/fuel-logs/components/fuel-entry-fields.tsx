/**
 * Odometer row + Liters/Total/Price-per-L triple + Full/Partial toggle for the
 * quick fuel-entry sheet. Parity with Flutter `quick_fuel_entry_sheet.dart`
 * `_buildFields` / `_buildTappableField` / `_buildFullPartialToggle`
 * (lines 635-965). Presentational — the parent owns all field text/focus state.
 *
 * Per `docs/ui-conventions.md`, the Full tank toggle sits on the same row as
 * Liters (the Dart source places it on its own row below the triple; the docs
 * are the source of truth here, so this port moves it up).
 */

import { StyleSheet, Text, View, type ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withRepeat, withTiming } from 'react-native-reanimated';
import { Pressable } from 'react-native';

import { Colors } from '@/constants/theme';
import type { DistanceUnit } from '@/lib/distance-unit';
import type { FuelField } from '../fuel-entry-calc';

/** One-off literal, Dart line 653/796 (`0xFFF2F2F7`). */
const INACTIVE_BG = '#F2F2F7';

export type ActiveField = 'odometer' | FuelField;

type FieldsProps = {
  unit: DistanceUnit;
  odoText: string;
  odoHint: string | null;
  litersText: string;
  totalText: string;
  perLiterText: string;
  derivedField: FuelField | null;
  active: ActiveField;
  onFocusField: (field: ActiveField) => void;
  isFullTank: boolean;
  onToggleFullTank: (value: boolean) => void;
};

export function FuelEntryFields({
  unit,
  odoText,
  odoHint,
  litersText,
  totalText,
  perLiterText,
  derivedField,
  active,
  onFocusField,
  isFullTank,
  onToggleFullTank,
}: FieldsProps) {
  return (
    <View style={styles.container}>
      <OdometerField
        unit={unit}
        text={odoText}
        hint={odoHint}
        focused={active === 'odometer'}
        onPress={() => onFocusField('odometer')}
      />

      <View style={styles.gap} />

      {/* Liters + Full/Partial toggle share a row per docs/ui-conventions.md. */}
      <View style={styles.row}>
        <View style={styles.litersSlot}>
          <TappableField
            label="Liters"
            text={litersText}
            focused={active === 'liters'}
            isAuto={derivedField === 'liters'}
            onPress={() => onFocusField('liters')}
          />
        </View>
        <View style={styles.gapSmall} />
        <View style={styles.toggleSlot}>
          <FullPartialToggle isFullTank={isFullTank} onChange={onToggleFullTank} />
        </View>
      </View>

      <View style={styles.gap} />

      <View style={styles.row}>
        <View style={styles.flex3}>
          <TappableField
            label="Total paid"
            text={totalText}
            prefix="Rs "
            focused={active === 'total'}
            isAuto={derivedField === 'total'}
            onPress={() => onFocusField('total')}
          />
        </View>
        <View style={styles.gapSmall} />
        <View style={styles.flex3}>
          <TappableField
            label="Price/L"
            text={perLiterText}
            prefix="Rs "
            focused={active === 'perLiter'}
            isAuto={derivedField === 'perLiter'}
            onPress={() => onFocusField('perLiter')}
          />
        </View>
      </View>
    </View>
  );
}

function OdometerField({
  unit,
  text,
  hint,
  focused,
  onPress,
}: {
  unit: DistanceUnit;
  text: string;
  hint: string | null;
  focused: boolean;
  onPress: () => void;
}) {
  const isEmpty = text.length === 0;
  return (
    <Pressable
      accessibilityRole="button"
      testID="fuel_field_odometer"
      onPress={onPress}
      style={[fieldStyles.base, focused ? fieldStyles.focused : fieldStyles.unfocused]}
    >
      <Text style={fieldStyles.label}>ODOMETER</Text>
      <View style={fieldStyles.spacer} />
      <View style={styles.valueRow}>
        <Text style={[fieldStyles.value, isEmpty && fieldStyles.valuePlaceholder]}>
          {isEmpty ? (hint ?? '0') : text}
        </Text>
        {focused ? <BlinkingCursor /> : null}
      </View>
      <Text style={fieldStyles.unit}>{unit}</Text>
    </Pressable>
  );
}

function TappableField({
  label,
  text,
  prefix,
  focused,
  isAuto,
  onPress,
}: {
  label: string;
  text: string;
  prefix?: string;
  focused: boolean;
  isAuto: boolean;
  onPress: () => void;
}) {
  const isEmpty = text.length === 0;
  // Strip a trailing ".00" for display only, matching Dart.
  const displayText = text.endsWith('.00') ? text.slice(0, -3) : text;

  return (
    <Pressable
      accessibilityRole="button"
      testID={`fuel_field_${label}`}
      onPress={onPress}
      style={[fieldStyles.tappable, focused ? fieldStyles.focused : fieldStyles.unfocused]}
    >
      <View style={styles.labelRow}>
        <Text style={fieldStyles.label} numberOfLines={1}>
          {label.toUpperCase()}
        </Text>
        {isAuto ? (
          <View style={fieldStyles.autoBadge}>
            <Text style={fieldStyles.autoBadgeText}>AUTO</Text>
          </View>
        ) : null}
      </View>
      <View style={styles.valueRow}>
        {prefix && !isEmpty ? <Text style={fieldStyles.prefix}>{prefix}</Text> : null}
        <Text
          style={[
            fieldStyles.value,
            isEmpty && fieldStyles.valuePlaceholder,
            isAuto && !isEmpty && fieldStyles.valueAuto,
          ]}
          numberOfLines={1}
        >
          {isEmpty ? '0' : displayText}
        </Text>
        {focused ? <BlinkingCursor /> : null}
      </View>
    </Pressable>
  );
}

function BlinkingCursor() {
  const opacity = useSharedValue(1);
  opacity.value = withRepeat(withTiming(0, { duration: 530 }), -1, true);
  const style = useAnimatedStyle(() => ({ opacity: opacity.value }));
  return <Animated.View style={[fieldStyles.cursor, style]} />;
}

function FullPartialToggle({
  isFullTank,
  onChange,
}: {
  isFullTank: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <View style={toggleStyles.row}>
      <ToggleOption label="Full tank" selected={isFullTank} onPress={() => onChange(true)} />
      <View style={styles.gapSmall} />
      <ToggleOption label="Partial" selected={!isFullTank} onPress={() => onChange(false)} />
    </View>
  );
}

function ToggleOption({
  label,
  selected,
  onPress,
}: {
  label: string;
  selected: boolean;
  onPress: () => void;
}) {
  const style: ViewStyle = selected
    ? { backgroundColor: Colors.textPrimary, borderColor: Colors.textPrimary }
    : { backgroundColor: Colors.surface, borderColor: Colors.divider };
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={[toggleStyles.option, style]}>
      <Text style={[toggleStyles.label, { color: selected ? '#FFFFFF' : Colors.textMuted }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
  },
  gap: {
    height: 10,
  },
  gapSmall: {
    width: 8,
  },
  row: {
    flexDirection: 'row',
  },
  litersSlot: {
    flex: 2,
  },
  toggleSlot: {
    flex: 3,
  },
  flex3: {
    flex: 3,
  },
  valueRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  labelRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
});

const fieldStyles = StyleSheet.create({
  base: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 11,
    borderRadius: 13,
    borderWidth: 1.5,
  },
  tappable: {
    paddingHorizontal: 11,
    paddingVertical: 9,
    borderRadius: 13,
    borderWidth: 1.5,
  },
  focused: {
    backgroundColor: Colors.surface,
    borderColor: Colors.textPrimary,
    shadowColor: '#000000',
    shadowOpacity: 0.06,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 1 },
    elevation: 2,
  },
  unfocused: {
    backgroundColor: INACTIVE_BG,
    borderColor: 'transparent',
  },
  label: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 0.5,
    color: Colors.textPrimary,
  },
  spacer: {
    flex: 1,
  },
  value: {
    fontSize: 18,
    fontWeight: '800',
    letterSpacing: -0.4,
    color: Colors.textPrimary,
  },
  valuePlaceholder: {
    color: Colors.divider,
  },
  valueAuto: {
    color: Colors.textMuted,
  },
  prefix: {
    fontSize: 11,
    fontWeight: '600',
    color: Colors.textMuted,
  },
  unit: {
    marginLeft: 3,
    fontSize: 12,
    fontWeight: '600',
    color: Colors.textMuted,
  },
  autoBadge: {
    marginLeft: 4,
    paddingHorizontal: 5,
    paddingVertical: 1,
    borderRadius: 5,
    backgroundColor: Colors.primary,
  },
  autoBadgeText: {
    fontSize: 8,
    fontWeight: '700',
    color: Colors.onPrimary,
    letterSpacing: 0.3,
  },
  cursor: {
    width: 2,
    height: 20,
    marginLeft: 2,
    borderRadius: 1,
    backgroundColor: Colors.textPrimary,
  },
});

const toggleStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
  },
  option: {
    flex: 1,
    height: 36,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    fontSize: 13,
    fontWeight: '700',
  },
});
