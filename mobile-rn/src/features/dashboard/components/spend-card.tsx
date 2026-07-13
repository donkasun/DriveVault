/**
 * "One honest spend card" — total ownership cost + breakdown bar + monthly
 * secondary figure. Parity with Flutter dashboard's `_SpendCard`.
 */

import { StyleSheet, Text, View } from 'react-native';

import { BreakdownBarWithLegend, type BreakdownSegment } from '@/components/breakdown-bar';
import { Colors, Radii, cardShadow } from '@/constants/theme';
import { formatCents } from '@/lib/formatting';
import type { DashboardData } from '../types';

type Props = {
  data: DashboardData;
  currency: string;
};

export function SpendCard({ data, currency }: Props) {
  const totalLabel = formatCents(data.totalOwnershipCostCents, currency);
  const monthlyLabel = formatCents(data.monthlyFuelSpendCents, currency);

  const segments: BreakdownSegment[] = [
    { label: 'Fuel', valueCents: data.costBreakdown.fuelCents, color: Colors.primary },
    { label: 'Maintenance', valueCents: data.costBreakdown.maintenanceCents, color: Colors.surfaceDark },
  ];

  return (
    <View style={[styles.card, cardShadow]}>
      <View style={styles.row}>
        <View style={styles.flex}>
          <Text style={styles.label}>TOTAL OWNERSHIP COST</Text>
          <Text style={styles.total}>{totalLabel}</Text>
          <Text style={styles.caption}>
            {`across ${data.vehicleCount} vehicle${data.vehicleCount === 1 ? '' : 's'}`}
          </Text>
        </View>
        <View style={styles.monthlyCol}>
          <Text style={styles.label}>THIS MONTH</Text>
          <Text style={styles.monthly}>{monthlyLabel}</Text>
        </View>
      </View>
      <View style={styles.barSlot}>
        <BreakdownBarWithLegend
          segments={segments}
          formatAmount={(cents) => formatCents(cents, currency)}
          barHeight={10}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: Radii.card + 2,
    padding: 18,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  flex: {
    flex: 1,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.0,
    color: Colors.textMuted,
  },
  total: {
    marginTop: 2,
    fontSize: 32,
    fontWeight: '800',
    letterSpacing: -1,
    color: Colors.textPrimary,
  },
  caption: {
    marginTop: 1,
    fontSize: 13,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  monthlyCol: {
    alignItems: 'flex-end',
  },
  monthly: {
    marginTop: 4,
    fontSize: 18,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  barSlot: {
    marginTop: 16,
  },
});
