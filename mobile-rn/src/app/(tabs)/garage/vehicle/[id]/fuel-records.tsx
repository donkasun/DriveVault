/**
 * Full fuel-log list for a vehicle. Reached from the detail screen's
 * "Add fuel" button and "View more" link — the Flutter app opens
 * `QuickFuelEntrySheet` for "Add fuel" instead of navigating, but that sheet
 * has no RN port yet, so both actions land here for now (see the migration
 * report). Read-only: no add/edit/delete form yet.
 */

import { useLocalSearchParams } from 'expo-router';
import { ActivityIndicator, FlatList, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors, Radii, cardShadow } from '@/constants/theme';
import { useFuelLogs } from '@/features/fuel-logs/hooks';
import type { FuelLog } from '@/features/fuel-logs/types';
import { useMe } from '@/features/profile/hooks';
import { useVehicle } from '@/features/vehicles/hooks';
import { sortByDateDesc } from '@/features/vehicles/vehicle-detail-helpers';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { effectiveUnit, formatDistance } from '@/lib/distance-unit';
import { formatCents } from '@/lib/formatting';

export default function FuelRecordsRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data: logs, isLoading } = useFuelLogs(id);
  const { data: vehicle } = useVehicle(id);
  const { data: me } = useMe();

  const currency = me?.currency ?? FALLBACK_CURRENCY;
  const unit = effectiveUnit(vehicle?.distanceUnit ?? null, me?.distanceUnit ?? 'km');
  const sorted = logs ? sortByDateDesc(logs, (l) => l.date) : [];

  if (isLoading) {
    return (
      <SafeAreaView style={styles.center} edges={['top']}>
        <ActivityIndicator size="large" color={Colors.textPrimary} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <Text style={styles.title}>Fuel logs</Text>
      <FlatList
        data={sorted}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={<Text style={styles.empty}>No fuel logs yet.</Text>}
        renderItem={({ item }) => <Row log={item} currency={currency} unit={unit} />}
      />
    </SafeAreaView>
  );
}

function Row({ log, currency, unit }: { log: FuelLog; currency: string; unit: 'km' | 'mi' }) {
  const odometer = log.odometer != null ? formatDistance(log.odometer, unit) : '—';
  return (
    <View style={styles.row}>
      <View style={styles.rowBody}>
        <Text style={styles.rowTitle}>{log.date}</Text>
        <Text style={styles.rowSubtitle}>
          {log.liters.toFixed(1)} L · {odometer} · {log.isFullTank ? 'Full' : 'Partial'}
        </Text>
      </View>
      <Text style={styles.rowAmount}>{formatCents(log.priceCents, currency)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.textPrimary,
    paddingHorizontal: 16,
    paddingVertical: 16,
  },
  listContent: {
    paddingBottom: 32,
  },
  empty: {
    marginHorizontal: 16,
    color: Colors.textMuted,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 16,
    marginBottom: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    ...cardShadow,
  },
  rowBody: {
    flex: 1,
  },
  rowTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  rowSubtitle: {
    marginTop: 2,
    fontSize: 12.5,
    color: Colors.textMuted,
  },
  rowAmount: {
    marginLeft: 8,
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
});
