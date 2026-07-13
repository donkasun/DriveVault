/**
 * Dark vehicle card used in the Garage list.
 * Parity with Flutter `features/vehicles/presentation/widgets/vehicle_card.dart`.
 *
 * Layout: name + year·reg + docs pill on the left, 88×64 thumbnail on the right,
 * then three stats (Mileage · Economy · Spent), then a split action row.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';
import { memo } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { StatusPill, docsStatusPill } from '@/components/status-pill';
import { Colors } from '@/constants/theme';
import { useFuelStats } from '@/features/fuel-logs/hooks';
import type { AppUser } from '@/features/profile/types';
import { formatCents, formatEconomyFromStats } from '@/lib/formatting';
import { effectiveUnit, formatDistance } from '@/lib/distance-unit';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { vehicleDisplayName, type Vehicle } from '../types';

/** Card-internal dividers — one-off literal in vehicle_card.dart:145. */
const CARD_DIVIDER = '#34333F';

type Props = {
  vehicle: Vehicle;
  user: AppUser | undefined;
  onOpen: (id: string) => void;
  onLogFuel: (id: string) => void;
};

export const VehicleCard = memo(function VehicleCard({
  vehicle,
  user,
  onOpen,
  onLogFuel,
}: Props) {
  const { data: stats } = useFuelStats(vehicle.id);

  const unit = effectiveUnit(vehicle.distanceUnit, user?.distanceUnit ?? 'km');
  const currency = user?.currency ?? FALLBACK_CURRENCY;

  const mileage =
    vehicle.currentMileage != null ? formatDistance(vehicle.currentMileage, unit) : '—';
  const economy = formatEconomyFromStats(stats?.avgConsumptionLPer100Km, unit);
  const spent = formatCents(stats?.totalSpentCents ?? 0, currency);

  const year = vehicle.year?.toString() ?? null;
  const reg = vehicle.registrationNumber;
  const pill = docsStatusPill(vehicle.docsStatus);

  return (
    <LinearGradient
      colors={[Colors.cardGradientStart, Colors.cardGradientEnd]}
      start={{ x: 0.5, y: 0 }}
      end={{ x: 0.5, y: 1 }}
      style={styles.card}
    >
      <View style={styles.top}>
        <View style={styles.identity}>
          <Text style={styles.name}>{vehicleDisplayName(vehicle)}</Text>

          {year || reg ? (
            <View style={styles.metaRow}>
              {year ? <Text style={styles.year}>{year}</Text> : null}
              {year && reg ? <View style={styles.dot} /> : null}
              {reg ? <Text style={styles.reg}>{reg}</Text> : null}
            </View>
          ) : null}

          <View style={styles.pill}>
            <StatusPill {...pill} onDark />
          </View>
        </View>

        <Thumbnail photoUrl={vehicle.photoUrl} />
      </View>

      <View style={styles.divider} />

      <View style={styles.stats}>
        <Stat value={mileage} label="MILEAGE" />
        <Stat value={economy} label="ECONOMY" />
        <Stat value={spent} label="SPENT" />
      </View>

      <View style={styles.divider} />

      <View style={styles.actions}>
        <Pressable
          accessibilityRole="button"
          onPress={() => onLogFuel(vehicle.id)}
          style={styles.action}
        >
          <Ionicons name="water" size={18} color={Colors.primary} />
          <Text style={styles.actionText}>Log fuel</Text>
        </Pressable>

        <View style={styles.actionDivider} />

        <Pressable
          accessibilityRole="button"
          onPress={() => onOpen(vehicle.id)}
          style={styles.action}
        >
          <Ionicons name="arrow-forward" size={18} color={Colors.primary} />
          <Text style={styles.actionText}>Open</Text>
        </Pressable>
      </View>
    </LinearGradient>
  );
});

function Thumbnail({ photoUrl }: { photoUrl: string | null }) {
  return (
    <View style={styles.thumb}>
      {photoUrl ? (
        <Image source={{ uri: photoUrl }} style={styles.thumbImage} contentFit="cover" />
      ) : (
        <Ionicons name="car-outline" size={32} color="rgba(255,255,255,0.24)" />
      )}
    </View>
  );
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <View style={styles.stat}>
      <Text style={styles.statValue} numberOfLines={1}>
        {value}
      </Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: 20,
    marginBottom: 16,
    borderRadius: 18,
    overflow: 'hidden',
  },
  top: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  identity: {
    flex: 1,
  },
  name: {
    color: Colors.textOnDark,
    fontSize: 18,
    fontWeight: '700',
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 3,
  },
  year: {
    color: 'rgba(255,255,255,0.62)',
    fontSize: 13,
    fontWeight: '600',
  },
  dot: {
    width: 3,
    height: 3,
    borderRadius: 9,
    marginHorizontal: 8,
    backgroundColor: 'rgba(255,255,255,0.38)',
  },
  reg: {
    color: 'rgba(255,255,255,0.62)',
    fontSize: 12,
    fontWeight: '600',
    fontFamily: 'monospace',
    letterSpacing: 0.5,
  },
  pill: {
    marginTop: 6,
    alignItems: 'flex-start',
  },
  thumb: {
    width: 88,
    height: 64,
    marginLeft: 12,
    borderRadius: 12,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  thumbImage: {
    width: '100%',
    height: '100%',
  },
  divider: {
    height: 1,
    backgroundColor: CARD_DIVIDER,
  },
  stats: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  stat: {
    flex: 1,
  },
  statValue: {
    color: Colors.textOnDark,
    fontSize: 15,
    fontWeight: '700',
  },
  statLabel: {
    marginTop: 2,
    color: 'rgba(255,255,255,0.5)',
    fontSize: 10,
    letterSpacing: 0.5,
  },
  actions: {
    flexDirection: 'row',
    height: 50,
  },
  action: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionText: {
    marginLeft: 8,
    color: Colors.primary,
    fontSize: 14,
    fontWeight: '700',
  },
  actionDivider: {
    width: 1,
    backgroundColor: CARD_DIVIDER,
  },
});
