/**
 * Summary card: "TOTAL SPENT" + All-time/Month toggle + BreakdownBar legend
 * (hidden when a kind filter is active). Parity with Flutter
 * `expense_history_screen.dart`'s `_SummaryCard` / `_SummaryRangeToggle`.
 */

import { Pressable, StyleSheet, Text, View } from 'react-native';

import { BreakdownBarWithLegend } from '@/components/breakdown-bar';
import { Colors, Radii, cardShadow } from '@/constants/theme';
import { formatCents } from '@/lib/formatting';
import { fuelCents, maintenanceCents, totalCents } from '../helpers';
import type { Expense, ExpenseKind } from '../types';

export type SummaryRange = 'allTime' | 'month';

type Props = {
  expenses: Expense[];
  userCurrency: string;
  kindFilter: ExpenseKind | null;
  summaryRange: SummaryRange;
  onSummaryRangeChange: (range: SummaryRange) => void;
};

export function ExpenseSummaryCard({
  expenses,
  userCurrency,
  kindFilter,
  summaryRange,
  onSummaryRangeChange,
}: Props) {
  const total = totalCents(expenses);
  const fuel = fuelCents(expenses);
  const maintenance = maintenanceCents(expenses);

  return (
    <View style={[styles.card, cardShadow]}>
      <View style={styles.headerRow}>
        <Text style={styles.label}>TOTAL SPENT</Text>
        <SummaryRangeToggle value={summaryRange} onChange={onSummaryRangeChange} />
      </View>
      <Text style={styles.total} numberOfLines={1}>
        {formatCents(total, userCurrency)}
      </Text>
      {kindFilter == null ? (
        <View style={styles.breakdown}>
          <BreakdownBarWithLegend
            segments={[
              { label: 'Fuel', valueCents: fuel, color: Colors.primary },
              { label: 'Maintenance', valueCents: maintenance, color: Colors.surfaceDark },
            ]}
            formatAmount={(c) => formatCents(c, userCurrency)}
          />
        </View>
      ) : null}
    </View>
  );
}

function SummaryRangeToggle({
  value,
  onChange,
}: {
  value: SummaryRange;
  onChange: (range: SummaryRange) => void;
}) {
  return (
    <View style={styles.toggle}>
      <RangeSegment label="All time" selected={value === 'allTime'} onPress={() => onChange('allTime')} />
      <RangeSegment label="Month" selected={value === 'month'} onPress={() => onChange('month')} />
    </View>
  );
}

function RangeSegment({
  label,
  selected,
  onPress,
}: {
  label: string;
  selected: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[styles.rangeSegment, selected && styles.rangeSegmentSelected]}
    >
      <Text style={[styles.rangeLabel, selected && styles.rangeLabelSelected]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    padding: 16,
    marginHorizontal: 16,
    marginBottom: 8,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  label: {
    flex: 1,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.6,
    color: Colors.textMuted,
  },
  total: {
    marginTop: 8,
    fontSize: 30,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  breakdown: {
    marginTop: 14,
  },
  toggle: {
    flexDirection: 'row',
    width: 160,
    height: 40,
    padding: 3,
    borderRadius: 999,
    backgroundColor: '#F4F5FA',
  },
  rangeSegment: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 999,
  },
  rangeSegmentSelected: {
    backgroundColor: Colors.textPrimary,
  },
  rangeLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textMuted,
  },
  rangeLabelSelected: {
    color: '#FFFFFF',
  },
});
