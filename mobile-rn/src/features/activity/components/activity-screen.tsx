/**
 * Standalone Activity screen ("See all activity" from the dashboard).
 * Parity with Flutter `features/activity/presentation/activity_screen.dart`.
 *
 * Calls `GET /activity` directly (via `useActivity`) — NOT the dashboard's
 * embedded `recentActivity` (see `features/activity/types.ts` module note).
 */

import { useMemo, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { Colors } from '@/constants/theme';
import { QuickFuelEntrySheet } from '@/features/fuel-logs/components/quick-fuel-entry-sheet';
import type { FuelLog } from '@/features/fuel-logs/types';
import { useMe } from '@/features/profile/hooks';
import { useVehicles } from '@/features/vehicles/hooks';
import { vehicleDisplayName } from '@/features/vehicles/types';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { filterActivityByKind, filterActivityByVehicle, groupActivityByMonth } from '../helpers';
import { useActivity } from '../hooks';
import type { ActivityEntry, ActivityKind } from '../types';
import { ActivityTile } from './activity-tile';
import { KindFilterBar } from './kind-filter-bar';
import { MonthHeader } from './month-header';
import { VehicleFilterSheet } from './vehicle-filter-sheet';

type ListRow =
  | { kind: 'header'; key: string; month: Date; subtotalCents: number }
  | { kind: 'entry'; key: string; entry: ActivityEntry };

/** Converts an activity fuel entry into the `FuelLog` shape the edit sheet expects. */
function toFuelLog(entry: ActivityEntry): FuelLog {
  return {
    id: entry.id,
    vehicleId: entry.vehicleId,
    date: entry.date,
    liters: entry.liters ?? 0,
    priceCents: entry.amountCents ?? 0,
    currency: entry.currency,
    odometer: entry.odometer ?? 0,
    isFullTank: entry.isFullTank ?? false,
    notes: entry.notes,
    createdAt: entry.createdAt,
    updatedAt: entry.createdAt,
  };
}

export function ActivityScreen() {
  const { data: entries, isLoading, isError, refetch } = useActivity();
  const { data: vehicles } = useVehicles();
  const { data: me } = useMe();
  const currency = me?.currency ?? FALLBACK_CURRENCY;

  const [kindFilter, setKindFilter] = useState<ActivityKind | null>(null);
  const [vehicleIdFilter, setVehicleIdFilter] = useState<string | null>(null);
  const [filterSheetOpen, setFilterSheetOpen] = useState(false);
  const [editingFuelEntry, setEditingFuelEntry] = useState<ActivityEntry | null>(null);

  const isFiltered = vehicleIdFilter != null || kindFilter != null;

  const vehicleMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const v of vehicles ?? []) map.set(v.id, vehicleDisplayName(v));
    return map;
  }, [vehicles]);

  const filtered = useMemo(() => {
    if (!entries) return [];
    return filterActivityByVehicle(filterActivityByKind(entries, kindFilter), vehicleIdFilter);
  }, [entries, kindFilter, vehicleIdFilter]);

  const rows = useMemo<ListRow[]>(() => {
    const groups = groupActivityByMonth(filtered);
    const result: ListRow[] = [];
    for (const group of groups) {
      result.push({
        kind: 'header',
        key: `h-${group.month.toISOString()}`,
        month: group.month,
        subtotalCents: group.subtotalCents,
      });
      for (const entry of group.entries) {
        result.push({ kind: 'entry', key: entry.id, entry });
      }
    }
    return result;
  }, [filtered]);

  return (
    <SafeAreaView style={styles.safeArea} edges={['top']}>
      <View style={styles.headerRow}>
        <Text style={styles.headerTitle}>Activity</Text>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Filter"
          onPress={() => setFilterSheetOpen(true)}
          style={[styles.filterButton, isFiltered && styles.filterButtonActive]}
        >
          <Text style={[styles.filterGlyph, isFiltered && styles.filterGlyphActive]}>⚙</Text>
          {isFiltered ? <View style={styles.filterDot} /> : null}
        </Pressable>
      </View>

      {isLoading ? (
        <View style={styles.center}>
          <Text style={styles.mutedText}>Loading…</Text>
        </View>
      ) : isError ? (
        <View style={styles.center}>
          <Text style={styles.errorText}>Could not load activity.</Text>
          <AppButton label="Retry" onPress={refetch} style={styles.retryButton} />
        </View>
      ) : (
        <View style={styles.body}>
          <View style={styles.filterBarSlot}>
            <KindFilterBar value={kindFilter} onChange={setKindFilter} />
          </View>
          {rows.length === 0 ? (
            <View style={styles.center}>
              <Text style={styles.emptyTitle}>No activity yet</Text>
              <Text style={styles.mutedText}>
                Fuel fill-ups, service records and documents will appear here.
              </Text>
            </View>
          ) : (
            <FlatList
              data={rows}
              keyExtractor={(row) => row.key}
              contentContainerStyle={styles.listContent}
              renderItem={({ item }) =>
                item.kind === 'header' ? (
                  <MonthHeader month={item.month} subtotalCents={item.subtotalCents} currency={currency} />
                ) : (
                  <ActivityTile
                    entry={item.entry}
                    vehicleName={vehicleMap.get(item.entry.vehicleId) ?? 'Unknown vehicle'}
                    showVehicleName={(vehicles?.length ?? 0) > 1}
                    onEditFuel={setEditingFuelEntry}
                  />
                )
              }
            />
          )}
        </View>
      )}

      <VehicleFilterSheet
        visible={filterSheetOpen}
        vehicles={vehicles ?? []}
        selectedVehicleId={vehicleIdFilter}
        onSelect={setVehicleIdFilter}
        onClose={() => setFilterSheetOpen(false)}
      />

      <QuickFuelEntrySheet
        visible={editingFuelEntry != null}
        vehicleId={editingFuelEntry?.vehicleId}
        existing={editingFuelEntry ? toFuelLog(editingFuelEntry) : undefined}
        onClose={() => setEditingFuelEntry(null)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 8,
  },
  headerTitle: {
    flex: 1,
    fontSize: 29,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  filterButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  filterButtonActive: {
    backgroundColor: Colors.textPrimary,
  },
  filterGlyph: {
    fontSize: 18,
    color: Colors.textPrimary,
  },
  filterGlyphActive: {
    color: '#FFFFFF',
  },
  filterDot: {
    position: 'absolute',
    top: -2,
    right: -2,
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: Colors.primary,
  },
  body: {
    flex: 1,
  },
  filterBarSlot: {
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 120,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  mutedText: {
    fontSize: 14,
    color: Colors.textMuted,
    textAlign: 'center',
  },
  errorText: {
    fontSize: 15,
    color: Colors.textMuted,
    textAlign: 'center',
    marginBottom: 16,
  },
  retryButton: {
    width: '100%',
  },
  emptyTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 8,
    textAlign: 'center',
  },
});
