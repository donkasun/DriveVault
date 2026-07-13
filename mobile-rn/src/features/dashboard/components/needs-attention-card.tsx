/**
 * "Needs attention" card — a dark surface listing renewals in `soon`/`overdue`
 * status. Parity with Flutter dashboard's `_NeedsAttentionCard` /
 * `_RenewalAttentionRow`.
 */

import { useRouter } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { renewalStatusPill, StatusPill } from '@/components/status-pill';
import { Colors } from '@/constants/theme';
import { isPersonalCredential, type UpcomingRenewal } from '../types';

type Props = {
  renewals: UpcomingRenewal[];
};

export function NeedsAttentionCard({ renewals }: Props) {
  const router = useRouter();

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <View style={styles.dot} />
        <Text style={styles.headerTitle}>Needs attention</Text>
        <View style={styles.spacer} />
        <Text style={styles.headerCount}>
          {`${renewals.length} item${renewals.length === 1 ? '' : 's'}`}
        </Text>
      </View>
      {renewals.map((renewal, i) => (
        <View key={`${renewal.title}-${renewal.expiryDate}-${i}`}>
          <View style={styles.divider} />
          <RenewalRow
            renewal={renewal}
            onPress={
              renewal.vehicleId != null
                ? () => router.push(`/garage/vehicle/${renewal.vehicleId}`)
                : undefined
            }
          />
        </View>
      ))}
    </View>
  );
}

function RenewalRow({ renewal, onPress }: { renewal: UpcomingRenewal; onPress?: () => void }) {
  const personal = isPersonalCredential(renewal);
  const subLabel = personal
    ? (renewal.vehicleLabel ?? renewal.title)
    : renewal.vehicleLabel && renewal.vehicleLabel.length > 0
      ? renewal.vehicleLabel
      : `${renewal.vehicleId!.slice(0, 8)}…`;

  const status = renewal.status ?? 'soon';
  const pillProps = renewalStatusPill(status, renewal.daysRemaining ?? undefined);

  const content = (
    <View style={styles.row}>
      <View style={styles.icon}>
        <Text style={styles.iconGlyph}>{personal ? '🪪' : '🚗'}</Text>
      </View>
      <View style={styles.textCol}>
        <Text numberOfLines={1} style={styles.title}>
          {renewal.title}
        </Text>
        <Text numberOfLines={1} style={styles.subLabel}>
          {subLabel}
        </Text>
      </View>
      <StatusPill {...pillProps} onDark />
      {!personal ? <Text style={styles.chevron}>›</Text> : null}
    </View>
  );

  if (personal || !onPress) return content;
  return (
    <Pressable onPress={onPress} style={({ pressed }) => pressed && styles.pressed}>
      {content}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surfaceDark,
    borderRadius: 18,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 18,
    paddingTop: 16,
    paddingBottom: 12,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.danger,
  },
  headerTitle: {
    marginLeft: 10,
    fontSize: 16,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  spacer: {
    flex: 1,
  },
  headerCount: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textOnDarkMuted,
  },
  divider: {
    height: 1,
    backgroundColor: '#34333F',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  pressed: {
    opacity: 0.85,
  },
  icon: {
    width: 38,
    height: 38,
    borderRadius: 13,
    backgroundColor: 'rgba(255,214,0,0.16)', // Colors.primary @ 16%
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconGlyph: {
    fontSize: 16,
  },
  textCol: {
    flex: 1,
    marginLeft: 12,
  },
  title: {
    fontSize: 15,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  subLabel: {
    fontSize: 12.5,
    fontWeight: '500',
    color: Colors.textOnDarkMuted,
  },
  chevron: {
    marginLeft: 6,
    fontSize: 18,
    color: 'rgba(235,235,245,0.38)',
  },
});
