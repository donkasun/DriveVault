/**
 * Full fuel-log list for a vehicle. Reached from the detail screen's
 * "View more" link. Rows support swipe-to-delete and tap-to-edit via
 * `FuelRecordCard` (the quick-entry sheet in edit mode).
 */

import { useLocalSearchParams } from 'expo-router';
import { ActivityIndicator, FlatList, StyleSheet, Text } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import { FuelRecordCard } from '@/features/fuel-logs/components/fuel-record-card';
import { useFuelLogs } from '@/features/fuel-logs/hooks';
import type { FuelLog } from '@/features/fuel-logs/types';
import { sortByDateDesc } from '@/features/vehicles/vehicle-detail-helpers';

export default function FuelRecordsRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data: logs, isLoading } = useFuelLogs(id);

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
        renderItem={({ item }: { item: FuelLog }) => <FuelRecordCard log={item} vehicleId={id} />}
      />
    </SafeAreaView>
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
});
