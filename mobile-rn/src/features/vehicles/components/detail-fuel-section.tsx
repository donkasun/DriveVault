/**
 * Fuel section: mini stats row, up to 3 most recent logs, "View more" link.
 * Parity with Flutter `vehicle_detail_screen.dart` `_FuelSection` /
 * `_FuelStatsCard` / `_FuelStatItem` (lines 738-912). Individual fuel-log rows
 * are read-only here (no swipe-to-delete / tap-to-edit sheet — the Flutter
 * `QuickFuelEntrySheet` has no RN port yet); see the final report.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';
import type { FuelLog } from '@/features/fuel-logs/types';
import { useFuelLogs, useFuelStats } from '@/features/fuel-logs/hooks';
import type { AppUser } from '@/features/profile/types';
import { effectiveUnit, formatDistance, type DistanceUnit } from '@/lib/distance-unit';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { formatCents, formatEconomyFromStats } from '@/lib/formatting';
import { relativeDateLabel, sortByDateDesc } from '../vehicle-detail-helpers';
import { DetailEmptyCard } from './detail-empty-card';
import { DetailSectionHeader } from './detail-section-header';

const RECENT_COUNT = 3;

const dayMonthFmt = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short' });

type Props = {
  vehicleId: string;
  vehicleDistanceUnit: string | null;
  user: AppUser | undefined;
  onAddFuel: () => void;
  onViewMore: () => void;
};

export function DetailFuelSection({
  vehicleId,
  vehicleDistanceUnit,
  user,
  onAddFuel,
  onViewMore,
}: Props) {
  const { data: logs, isLoading: logsLoading, error: logsError } = useFuelLogs(vehicleId);
  const { data: stats } = useFuelStats(vehicleId);

  const currency = user?.currency ?? FALLBACK_CURRENCY;
  const unit = effectiveUnit(vehicleDistanceUnit, user?.distanceUnit ?? 'km');

  const sorted = logs ? sortByDateDesc(logs, (l) => l.date) : [];
  const recent = sorted.slice(0, RECENT_COUNT);

  return (
    <View>
      <DetailSectionHeader
        title="Fuel"
        count={logs ? logs.length : null}
        buttonLabel="Add fuel"
        onAdd={onAddFuel}
      />

      {stats ? <FuelStatsCard stats={stats} currency={currency} unit={unit} /> : null}

      {logsLoading ? null : logsError ? (
        <Text style={styles.error}>Error: {String(logsError)}</Text>
      ) : sorted.length === 0 ? (
        <DetailEmptyCard label="No fuel logs yet." />
      ) : (
        <View>
          {recent.map((log) => (
            <FuelLogRow key={log.id} log={log} currency={currency} unit={unit} />
          ))}
          {sorted.length > recent.length ? (
            <View style={styles.viewMoreWrap}>
              <ViewMoreButton onPress={onViewMore} />
            </View>
          ) : null}
        </View>
      )}
    </View>
  );
}

function FuelStatsCard({
  stats,
  currency,
  unit,
}: {
  stats: { avgConsumptionLPer100Km: number | null; avgCostPerKmCents: number | null; totalSpentCents: number };
  currency: string;
  unit: DistanceUnit;
}) {
  const economyLabel = unit === 'km' ? 'KM / L' : 'MPG';
  const costLabel = unit === 'km' ? 'COST / KM' : 'COST / MI';

  return (
    <View style={styles.statsCard}>
      <FuelStatItem label={economyLabel} value={formatEconomyFromStats(stats.avgConsumptionLPer100Km, unit)} />
      <FuelStatItem
        label={costLabel}
        value={stats.avgCostPerKmCents != null ? formatCents(stats.avgCostPerKmCents, currency) : '—'}
      />
      <FuelStatItem label="TOTAL FUEL" value={formatCents(stats.totalSpentCents, currency)} />
    </View>
  );
}

function FuelStatItem({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statItem}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function FuelLogRow({ log, currency, unit }: { log: FuelLog; currency: string; unit: DistanceUnit }) {
  const title = relativeDateLabel(log.date, (d) => dayMonthFmt.format(d));
  const odometer = log.odometer != null ? formatDistance(log.odometer, unit) : '—';
  const subLabel = `${log.liters.toFixed(1)} L · ${odometer} · ${log.isFullTank ? 'Full' : 'Partial'}`;

  return (
    <View style={styles.row}>
      <View style={[styles.rowIcon, { backgroundColor: log.isFullTank ? Colors.successBg : 'rgba(255,214,0,0.12)' }]}>
        <Ionicons name="water" size={20} color={log.isFullTank ? Colors.success : Colors.onPrimary} />
      </View>
      <View style={styles.rowBody}>
        <Text style={styles.rowTitle} numberOfLines={1}>
          {title}
        </Text>
        <Text style={styles.rowSubtitle} numberOfLines={1}>
          {subLabel}
        </Text>
      </View>
      <Text style={styles.rowAmount}>{formatCents(log.priceCents, currency)}</Text>
    </View>
  );
}

function ViewMoreButton({ onPress }: { onPress: () => void }) {
  return (
    <Text accessibilityRole="button" onPress={onPress} style={styles.viewMore}>
      View more
    </Text>
  );
}

const styles = StyleSheet.create({
  error: {
    marginHorizontal: 16,
    color: Colors.danger,
  },
  statsCard: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginHorizontal: 16,
    marginVertical: 4,
    paddingVertical: 16,
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    ...cardShadow,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  statLabel: {
    marginTop: 4,
    fontSize: 10,
    fontWeight: '600',
    color: Colors.textMuted,
    letterSpacing: 0.5,
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
  rowIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowBody: {
    flex: 1,
    marginLeft: 13,
  },
  rowTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  rowSubtitle: {
    marginTop: 1,
    fontSize: 12.5,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  rowAmount: {
    marginLeft: 8,
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  viewMoreWrap: {
    marginHorizontal: 16,
    marginTop: 8,
    alignItems: 'center',
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.pill,
  },
  viewMore: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
});
