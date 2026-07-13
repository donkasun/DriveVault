/**
 * All / Fuel / Maintenance segmented filter. Parity with Flutter
 * `expense_history_screen.dart`'s `_KindFilterBar` (minus the sliding-thumb
 * animation — a static selected-segment highlight is used instead, matching
 * this codebase's existing `activity/components/kind-filter-bar.tsx`).
 */

import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import type { ExpenseKind } from '../types';

type Segment = { label: string; value: ExpenseKind | null };

const SEGMENTS: Segment[] = [
  { label: 'All', value: null },
  { label: 'Fuel', value: 'fuel' },
  { label: 'Maintenance', value: 'maintenance' },
];

type Props = {
  value: ExpenseKind | null;
  onChange: (value: ExpenseKind | null) => void;
};

export function ExpenseKindFilterBar({ value, onChange }: Props) {
  return (
    <View style={styles.bar}>
      {SEGMENTS.map((segment) => {
        const selected = segment.value === value;
        return (
          <Pressable
            key={segment.label}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(selected ? null : segment.value)}
            style={[styles.segment, selected && styles.segmentSelected]}
          >
            <Text style={[styles.label, selected && styles.labelSelected]} numberOfLines={1}>
              {segment.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    height: 48,
    padding: 4,
    borderRadius: 999,
    backgroundColor: '#F4F5FA',
  },
  segment: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 999,
  },
  segmentSelected: {
    backgroundColor: Colors.textPrimary,
  },
  label: {
    fontSize: 12,
    fontWeight: '700',
    color: '#8A8AA3',
  },
  labelSelected: {
    color: '#FFFFFF',
  },
});
