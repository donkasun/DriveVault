/**
 * Expenses tab screen. Parity with Flutter
 * `mobile/lib/features/expenses/presentation/expense_history_screen.dart`.
 *
 * There is no `/expenses` endpoint — `useExpenses` fans out over every
 * vehicle's fuel logs + maintenance records and merges them client-side
 * (see `../hooks.ts`). Filtering/grouping/totals are pure functions from
 * `../helpers.ts`, memoized here since the fan-out is the expensive part.
 */

import { useMemo, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { Colors } from '@/constants/theme';
import { QuickFuelEntrySheet } from '@/features/fuel-logs/components/quick-fuel-entry-sheet';
import { useMe } from '@/features/profile/hooks';
import { vehicleDisplayName } from '@/features/vehicles/types';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { ExpenseEmptyState } from './expense-empty-state';
import { ExpenseKindFilterBar } from './expense-kind-filter-bar';
import { ExpenseMonthHeader } from './expense-month-header';
import { ExpenseSummaryCard, type SummaryRange } from './expense-summary-card';
import { ExpenseTile } from './expense-tile';
import { ExpenseVehicleFilterSheet } from './expense-vehicle-filter-sheet';
import { filterByKind, filterByVehicle, filterToCurrentMonth, groupExpensesByMonth } from '../helpers';
import { useExpenses } from '../hooks';
import type { Expense, ExpenseKind } from '../types';

type ListRow =
  | { row: 'header'; key: string; month: Date; subtotalCents: number }
  | { row: 'entry'; key: string; expense: Expense };

export function ExpenseHistoryScreen() {
  const { data: expenses, vehicles, isLoading, isError, refetch } = useExpenses();
  const { data: me } = useMe();
  const userCurrency = me?.currency ?? FALLBACK_CURRENCY;

  const [kindFilter, setKindFilter] = useState<ExpenseKind | null>(null);
  const [vehicleIdFilter, setVehicleIdFilter] = useState<string | null>(null);
  const [summaryRange, setSummaryRange] = useState<SummaryRange>('allTime');
  const [filterSheetOpen, setFilterSheetOpen] = useState(false);
  const [loggingFillUp, setLoggingFillUp] = useState(false);

  const hasMultipleVehicles = (vehicles?.length ?? 0) > 1;

  const vehicleMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const v of vehicles ?? []) map.set(v.id, vehicleDisplayName(v));
    return map;
  }, [vehicles]);

  // Kind + vehicle filters applied first (client-side, no new network call).
  const filtered = useMemo(() => {
    if (!expenses) return [];
    return filterByVehicle(filterByKind(expenses, kindFilter), vehicleIdFilter);
  }, [expenses, kindFilter, vehicleIdFilter]);

  // Summary card and list both use the time-scoped subset when Month is active.
  const timeScoped = useMemo(
    () => (summaryRange === 'month' ? filterToCurrentMonth(filtered) : filtered),
    [filtered, summaryRange],
  );

  const rows = useMemo<ListRow[]>(() => {
    const groups = groupExpensesByMonth(timeScoped);
    const result: ListRow[] = [];
    for (const group of groups) {
      result.push({
        row: 'header',
        key: `h-${group.month.toISOString()}`,
        month: group.month,
        subtotalCents: group.subtotalCents,
      });
      for (const expense of group.expenses) {
        result.push({ row: 'entry', key: expense.id, expense });
      }
    }
    return result;
  }, [timeScoped]);

  return (
    <SafeAreaView style={styles.safeArea} edges={['top']}>
      <View style={styles.headerRow}>
        <Text style={styles.headerTitle}>Expenses</Text>
        {hasMultipleVehicles ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Filter"
            onPress={() => setFilterSheetOpen(true)}
            style={[styles.filterButton, vehicleIdFilter != null && styles.filterButtonActive]}
          >
            <Text style={[styles.filterGlyph, vehicleIdFilter != null && styles.filterGlyphActive]}>
              ⚙
            </Text>
            {vehicleIdFilter != null ? <View style={styles.filterDot} /> : null}
          </Pressable>
        ) : null}
      </View>

      {isLoading ? (
        <View style={styles.center}>
          <Text style={styles.mutedText}>Loading…</Text>
        </View>
      ) : isError ? (
        <View style={styles.center}>
          <Text style={styles.errorText}>Could not load expenses.</Text>
          <AppButton label="Retry" onPress={refetch} style={styles.retryButton} />
        </View>
      ) : (
        <View style={styles.body}>
          <ExpenseSummaryCard
            expenses={timeScoped}
            userCurrency={userCurrency}
            kindFilter={kindFilter}
            summaryRange={summaryRange}
            onSummaryRangeChange={setSummaryRange}
          />
          <View style={styles.filterBarSlot}>
            <ExpenseKindFilterBar value={kindFilter} onChange={setKindFilter} />
          </View>
          {rows.length === 0 ? (
            <ExpenseEmptyState
              isMonthFilter={summaryRange === 'month'}
              onLogFillUp={() => setLoggingFillUp(true)}
            />
          ) : (
            <FlatList
              data={rows}
              keyExtractor={(row) => row.key}
              contentContainerStyle={styles.listContent}
              renderItem={({ item }) =>
                item.row === 'header' ? (
                  <ExpenseMonthHeader month={item.month} subtotalCents={item.subtotalCents} currency={userCurrency} />
                ) : (
                  <ExpenseTile
                    expense={item.expense}
                    vehicleName={vehicleMap.get(item.expense.vehicleId) ?? 'Unknown vehicle'}
                    showVehicleName={hasMultipleVehicles}
                  />
                )
              }
            />
          )}
        </View>
      )}

      <ExpenseVehicleFilterSheet
        visible={filterSheetOpen}
        vehicles={vehicles ?? []}
        selectedVehicleId={vehicleIdFilter}
        onSelect={setVehicleIdFilter}
        onClose={() => setFilterSheetOpen(false)}
      />

      <QuickFuelEntrySheet visible={loggingFillUp} onClose={() => setLoggingFillUp(false)} />
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
    paddingTop: 4,
    paddingBottom: 8,
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
});
