/**
 * 4-column stats card (mileage / economy / spent / docs). Parity with Flutter
 * `vehicle_detail_screen.dart` `_StatsCard` / `_StatCol` / `_DocsStatCol` (lines 468-667).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';
import type { DocsStatus } from '../types';
import { splitStatPrefix, splitStatSuffix } from '../vehicle-detail-helpers';

type Props = {
  mileage: string;
  economy: string;
  spent: string;
  docsStatus: DocsStatus;
};

export function DetailStatsCard({ mileage, economy, spent, docsStatus }: Props) {
  const [mileageNum, mileageUnit] = splitStatSuffix(mileage);
  const [economyNum, economyUnit] = splitStatSuffix(economy);
  const [spentPrefix, spentNum] = splitStatPrefix(spent);

  return (
    <View style={styles.card}>
      <StatCol number={mileageNum} unitSuffix={mileageUnit} label="MILEAGE" />
      <VDivider />
      <StatCol number={economyNum} unitSuffix={economyUnit} label="ECONOMY" />
      <VDivider />
      <StatCol number={spentNum} unitPrefix={spentPrefix} label="SPENT" />
      <VDivider />
      <DocsStatCol docsStatus={docsStatus} />
    </View>
  );
}

function StatCol({
  number,
  label,
  unitPrefix,
  unitSuffix,
}: {
  number: string;
  label: string;
  unitPrefix?: string | null;
  unitSuffix?: string | null;
}) {
  return (
    <View style={[styles.col, styles.colWide]}>
      <Text style={styles.number} numberOfLines={1}>
        {unitPrefix ? <Text style={styles.unit}>{unitPrefix} </Text> : null}
        {number}
        {unitSuffix ? <Text style={styles.unit}> {unitSuffix}</Text> : null}
      </Text>
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

function DocsStatCol({ docsStatus }: { docsStatus: DocsStatus }) {
  const isOk = docsStatus.state === 'valid';
  const color = isOk ? Colors.success : Colors.danger;
  const label = isOk ? 'Done' : `${docsStatus.needsActionCount}`;

  return (
    <View style={styles.col}>
      <View style={styles.docsRow}>
        <Ionicons
          name={isOk ? 'checkmark-circle-outline' : 'warning-outline'}
          size={15}
          color={color}
        />
        <Text style={[styles.docsNumber, { color }]}>{label}</Text>
      </View>
      <Text style={styles.docsLabel}>DOCS</Text>
    </View>
  );
}

function VDivider() {
  return <View style={styles.divider} />;
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'stretch',
    marginHorizontal: 16,
    marginTop: 16,
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    ...cardShadow,
  },
  col: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 10,
    paddingVertical: 14,
  },
  colWide: {
    flex: 2,
  },
  divider: {
    width: 1,
    marginVertical: 12,
    backgroundColor: Colors.divider,
  },
  number: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  unit: {
    fontSize: 11,
    fontWeight: '400',
    color: Colors.textMuted,
  },
  label: {
    marginTop: 3,
    fontSize: 11,
    fontWeight: '500',
    color: Colors.textMuted,
    letterSpacing: 0.5,
  },
  docsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  docsNumber: {
    marginLeft: 4,
    fontSize: 14,
    fontWeight: '700',
  },
  docsLabel: {
    marginTop: 3,
    fontSize: 9,
    fontWeight: '600',
    color: Colors.textMuted,
    letterSpacing: 0.5,
  },
});
