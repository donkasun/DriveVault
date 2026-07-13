/**
 * Maintenance section: header + record list. Parity with Flutter
 * `vehicle_detail_screen.dart` `_MaintenanceSection` / `_MaintenanceTile`
 * (lines 918-1109). Tapping a row navigates to the maintenance edit route.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';
import { useMaintenanceRecords } from '@/features/maintenance/hooks';
import type { MaintenanceRecord } from '@/features/maintenance/types';
import type { AppUser } from '@/features/profile/types';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { formatCents } from '@/lib/formatting';
import {
  maintenanceIconKey,
  maintenanceSubtitle,
  sortByDateDesc,
  type MaintenanceIconKey,
} from '../vehicle-detail-helpers';
import { DetailEmptyCard } from './detail-empty-card';
import { DetailSectionHeader } from './detail-section-header';

/** category → (icon, bg, fg). One-off literals, Dart `_MaintenanceTile._iconStyle` (lines 1074-1097). */
const ICON_STYLE: Record<MaintenanceIconKey, { icon: React.ComponentProps<typeof Ionicons>['name']; bg: string; fg: string }> = {
  repair: { icon: 'hammer-outline', bg: '#FCEBEB', fg: '#DC2626' },
  upgrade: { icon: 'sparkles-outline', bg: '#E8F1FD', fg: '#2563EB' },
  inspection: { icon: 'checkmark-done-outline', bg: '#EAF7EE', fg: '#16A34A' },
  default: { icon: 'build-outline', bg: '#FCF1DC', fg: '#B45309' },
};

/** Cost-pill background, Dart line 1053 (`0xFFF5F3FF`). */
const COST_PILL_BG = '#F5F3FF';

type Props = {
  vehicleId: string;
  user: AppUser | undefined;
  onAddService: () => void;
  onOpenRecord: (record: MaintenanceRecord) => void;
};

export function DetailMaintenanceSection({ vehicleId, user, onAddService, onOpenRecord }: Props) {
  const { data: records, isLoading, error } = useMaintenanceRecords(vehicleId);
  const currency = user?.currency ?? FALLBACK_CURRENCY;

  const sorted = records ? sortByDateDesc(records, (r) => r.date) : [];

  return (
    <View>
      <DetailSectionHeader title="Maintenance" buttonLabel="Add service" onAdd={onAddService} />

      {isLoading ? null : error ? (
        <Text style={styles.error}>Error: {String(error)}</Text>
      ) : sorted.length === 0 ? (
        <DetailEmptyCard label="No maintenance records yet." />
      ) : (
        sorted.map((record) => (
          <MaintenanceRow
            key={record.id}
            record={record}
            currency={currency}
            onPress={() => onOpenRecord(record)}
          />
        ))
      )}
    </View>
  );
}

function MaintenanceRow({
  record,
  currency,
  onPress,
}: {
  record: MaintenanceRecord;
  currency: string;
  onPress: () => void;
}) {
  const style = ICON_STYLE[maintenanceIconKey(record.category)];
  const costLabel = record.costCents != null ? formatCents(record.costCents, currency) : null;

  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.row}>
      <View style={[styles.rowIcon, { backgroundColor: style.bg }]}>
        <Ionicons name={style.icon} size={20} color={style.fg} />
      </View>
      <View style={styles.rowBody}>
        <Text style={styles.rowTitle} numberOfLines={1}>
          {record.serviceType}
        </Text>
        <Text style={styles.rowSubtitle} numberOfLines={2}>
          {maintenanceSubtitle(record)}
        </Text>
      </View>
      {costLabel ? (
        <View style={styles.costPill}>
          <Text style={styles.costLabel}>{costLabel}</Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  error: {
    marginHorizontal: 16,
    color: Colors.danger,
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
  costPill: {
    marginLeft: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: COST_PILL_BG,
  },
  costLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
});
