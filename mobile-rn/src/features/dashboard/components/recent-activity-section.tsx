/**
 * "Recent activity" section (top 5 of the dashboard's embedded feed) + a
 * "See all activity" link to the standalone Activity screen. Parity with
 * Flutter dashboard's `_RecentActivitySection` / `_ActivityCard`.
 */

import { useRouter } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { ActivityEntryCard } from '@/components/activity-entry-card';
import { FuelPumpIcon } from '@/components/fuel-pump-icon';
import { Colors } from '@/constants/theme';
import { friendlyDate } from '../helpers';
import type { ActivityItem, ActivityType } from '../types';

type Props = {
  items: ActivityItem[];
  currency: string;
};

export function RecentActivitySection({ items, currency }: Props) {
  const router = useRouter();

  return (
    <View>
      <Text style={styles.heading}>Recent activity</Text>
      {items.map((item, i) => (
        <View key={`${item.type}-${item.vehicleId}-${item.date}-${i}`} style={styles.itemSpacing}>
          <ActivityCard item={item} currency={currency} />
        </View>
      ))}
      <Pressable
        accessibilityRole="button"
        onPress={() => router.push('/home/activity')}
        style={styles.seeAll}
      >
        <Text style={styles.seeAllLabel}>See all activity</Text>
        <Text style={styles.chevron}>›</Text>
      </Pressable>
    </View>
  );
}

function ActivityCard({ item, currency }: { item: ActivityItem; currency: string }) {
  const dateLabel = friendlyDate(item.date);
  const subLabel =
    item.type === 'fuel' && item.liters != null
      ? `${dateLabel} · ${item.liters.toFixed(1)} L · ${item.isFullTank ? 'Full tank' : 'Partial'}`
      : `${dateLabel} · ${item.label}`;

  return (
    <ActivityEntryCard
      icon={<TypeIcon type={item.type} isFullTank={item.isFullTank} />}
      title={item.vehicleLabel}
      subLabel={subLabel}
      amountCents={item.amountCents}
      currency={currency}
    />
  );
}

function TypeIcon({ type, isFullTank }: { type: ActivityType; isFullTank: boolean | null }) {
  if (type === 'fuel') {
    const isFull = isFullTank ?? true;
    return (
      <View
        style={[
          styles.iconTile,
          { backgroundColor: isFull ? Colors.successBg : 'rgba(255,214,0,0.12)' },
        ]}
      >
        <FuelPumpIcon isFullTank={isFull} size={20} darkInk={!isFull} />
      </View>
    );
  }

  const glyph = type === 'maintenance' ? '🔧' : '📄';
  const bg = type === 'maintenance' ? 'rgba(30,29,43,0.08)' : Colors.successBg;
  return (
    <View style={[styles.iconTile, { backgroundColor: bg }]}>
      <Text style={styles.iconGlyph}>{glyph}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  heading: {
    marginBottom: 12,
    fontSize: 19,
    fontWeight: '800',
    letterSpacing: -0.4,
    color: Colors.textPrimary,
  },
  itemSpacing: {
    marginBottom: 10,
  },
  seeAll: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
  },
  seeAllLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textMuted,
  },
  chevron: {
    marginLeft: 4,
    fontSize: 16,
    color: Colors.textMuted,
  },
  iconTile: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconGlyph: {
    fontSize: 18,
  },
});
