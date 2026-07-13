/**
 * Hero photo header: full-bleed vehicle photo (or placeholder), back/edit/delete
 * circular nav buttons, and the vehicle name/meta overlaid at the bottom.
 *
 * Parity with Flutter `vehicle_detail_screen.dart` `_HeroAppBar` /
 * `_VehicleHeroInfo` (lines 163-462). The Dart version is a collapsing
 * `SliverAppBar` with an on-photo-luminance status-bar-style sampler; this RN
 * port simplifies to a fixed-height header (no collapse-on-scroll, no
 * luminance sampling) since neither has a behavioural effect users depend on —
 * flagged here rather than silently dropped.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import type { Vehicle } from '../types';

const HERO_HEIGHT = 220;

type Props = {
  vehicle: Vehicle;
  onBack: () => void;
  onEdit: () => void;
  onDelete: () => void;
};

export function DetailHero({ vehicle, onBack, onEdit, onDelete }: Props) {
  const fuelLabel = vehicle.fuelType
    ? vehicle.fuelType[0].toUpperCase() + vehicle.fuelType.slice(1)
    : null;

  return (
    <View style={styles.root}>
      {vehicle.photoUrl ? (
        <Image source={{ uri: vehicle.photoUrl }} style={StyleSheet.absoluteFill} contentFit="cover" />
      ) : (
        <View style={[StyleSheet.absoluteFill, styles.placeholderBg]} />
      )}

      <LinearGradient
        colors={['rgba(0,0,0,0.39)', 'transparent']}
        style={[StyleSheet.absoluteFill, styles.topGradient]}
      />
      <LinearGradient
        colors={['rgba(0,0,0,0.71)', 'transparent']}
        start={{ x: 0.5, y: 1 }}
        end={{ x: 0.5, y: 0.5 }}
        style={StyleSheet.absoluteFill}
      />

      {!vehicle.photoUrl ? (
        <View style={styles.placeholderCenter}>
          <Ionicons name="car-sport-outline" size={40} color="rgba(255,255,255,0.2)" />
          <Text style={styles.placeholderLabel}>VEHICLE PHOTO</Text>
        </View>
      ) : null}

      <SafeAreaView edges={['top']} style={styles.navRow}>
        <CircleNavButton icon="arrow-back" onPress={onBack} accessibilityLabel="Back" />
        <View style={styles.navSpacer} />
        <CircleNavButton icon="create-outline" onPress={onEdit} accessibilityLabel="Edit vehicle" />
        <View style={styles.navGap} />
        <CircleNavButton icon="trash-outline" onPress={onDelete} accessibilityLabel="Delete vehicle" />
      </SafeAreaView>

      <View style={styles.infoWrap}>
        <Text style={styles.name} numberOfLines={1}>
          {vehicle.make} {vehicle.model}
        </Text>
        <View style={styles.metaRow}>
          {vehicle.year != null ? <Text style={styles.metaText}>{vehicle.year}</Text> : null}
          {vehicle.year != null && fuelLabel ? <Text style={styles.metaDot}>·</Text> : null}
          {fuelLabel ? <Text style={styles.metaText}>{fuelLabel}</Text> : null}
          {vehicle.registrationNumber ? (
            <View style={styles.regBadge}>
              <Text style={styles.regText}>{vehicle.registrationNumber}</Text>
            </View>
          ) : null}
        </View>
      </View>
    </View>
  );
}

function CircleNavButton({
  icon,
  onPress,
  accessibilityLabel,
}: {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  onPress: () => void;
  accessibilityLabel: string;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onPress={onPress}
      style={styles.circleButton}
    >
      <Ionicons name={icon} size={18} color={Colors.textPrimary} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: {
    height: HERO_HEIGHT,
    backgroundColor: Colors.surfaceDark,
    overflow: 'hidden',
  },
  placeholderBg: {
    backgroundColor: Colors.surfaceDark,
  },
  topGradient: {
    height: '60%',
  },
  placeholderCenter: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderLabel: {
    marginTop: 8,
    color: 'rgba(255,255,255,0.2)',
    fontSize: 10,
    fontWeight: '600',
    letterSpacing: 1.5,
  },
  navRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingTop: 4,
  },
  navSpacer: {
    flex: 1,
  },
  navGap: {
    width: 8,
  },
  circleButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.86)',
  },
  infoWrap: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 16,
  },
  name: {
    fontSize: 26,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.4,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
  },
  metaText: {
    color: 'rgba(255,255,255,0.78)',
    fontSize: 13,
    fontWeight: '700',
  },
  metaDot: {
    color: 'rgba(255,255,255,0.59)',
    fontSize: 13,
    marginHorizontal: 5,
  },
  regBadge: {
    marginLeft: 8,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    backgroundColor: 'rgba(255,255,255,0.18)',
  },
  regText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
    fontFamily: 'monospace',
    letterSpacing: 0.5,
  },
});
