/**
 * Garage tab. Parity with Flutter `features/vehicles/presentation/garage_screen.dart`.
 *
 * NOTE: this screen uses one-off hex literals that are NOT in AppColors
 * (#13121C ink, #73738A muted, #E6E6EE dashed border). That is design drift in
 * the Flutter app; reproduced here verbatim rather than snapped to the tokens.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import { useCallback, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { DashedBorder } from '@/components/dashed-border';
import { ShimmerBox } from '@/components/shimmer-box';
import { Colors } from '@/constants/theme';
import { QuickFuelEntrySheet } from '@/features/fuel-logs/components/quick-fuel-entry-sheet';
import { useMe } from '@/features/profile/hooks';
import { useVehicles } from '../hooks';
import type { Vehicle } from '../types';
import { VehicleCard } from './vehicle-card';

/** garage_screen.dart one-off literals. */
const INK = '#13121C';
const MUTED = '#73738A';
const DASH = '#E6E6EE';

/** Leaves room for the floating tab bar. */
const LIST_BOTTOM_PADDING = 100;

export function GarageScreen() {
  const router = useRouter();
  const { data: vehicles, isLoading, error, refetch } = useVehicles();
  const { data: me } = useMe();
  const [fuelSheetVehicleId, setFuelSheetVehicleId] = useState<string | null>(null);

  const onAdd = useCallback(() => router.push('/garage/add-vehicle'), [router]);
  const onOpen = useCallback((id: string) => router.push(`/garage/vehicle/${id}`), [router]);
  const onLogFuel = useCallback((id: string) => setFuelSheetVehicleId(id), []);

  const renderItem = useCallback(
    ({ item }: { item: Vehicle }) => (
      <VehicleCard vehicle={item} user={me} onOpen={onOpen} onLogFuel={onLogFuel} />
    ),
    [me, onOpen, onLogFuel],
  );

  if (isLoading) {
    return (
      <SafeAreaView style={styles.screen} edges={['top']}>
        <GarageSkeleton />
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={styles.screen} edges={['top']}>
        <View style={styles.errorBox}>
          <Ionicons name="alert-circle-outline" size={48} color={Colors.danger} />
          <Text style={styles.errorText}>{String(error)}</Text>
          <AppButton label="Retry" onPress={() => void refetch()} style={styles.retry} />
        </View>
      </SafeAreaView>
    );
  }

  const list = vehicles ?? [];

  if (list.length === 0) {
    return (
      <SafeAreaView style={styles.screen} edges={['top']}>
        <EmptyState onAdd={onAdd} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <GarageHeader count={list.length} />
      <FlatList
        data={list}
        keyExtractor={(v) => v.id}
        renderItem={renderItem}
        contentContainerStyle={styles.listContent}
        ListFooterComponent={<AddVehicleCard onPress={onAdd} />}
      />

      <QuickFuelEntrySheet
        visible={fuelSheetVehicleId != null}
        vehicleId={fuelSheetVehicleId ?? undefined}
        onClose={() => setFuelSheetVehicleId(null)}
      />
    </SafeAreaView>
  );
}

function GarageHeader({ count }: { count: number }) {
  return (
    <View style={styles.header}>
      <Text style={styles.headerTitle}>Your garage</Text>
      <Text style={styles.headerCount}>
        {count} {count === 1 ? 'vehicle' : 'vehicles'}
      </Text>
    </View>
  );
}

function AddVehicleCard({ onPress }: { onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.addCardWrap}>
      <DashedBorder color={DASH} radius={18} strokeWidth={2} style={styles.addCard}>
        <Ionicons name="add" size={20} color={MUTED} />
        <Text style={styles.addCardText}>Add vehicle</Text>
      </DashedBorder>
    </Pressable>
  );
}

function EmptyState({ onAdd }: { onAdd: () => void }) {
  return (
    <View style={styles.emptyRoot}>
      <Text style={[styles.headerTitle, styles.emptyTitle]}>Your garage</Text>

      <View style={styles.emptyCenter}>
        <View style={styles.emptyIcon}>
          <Ionicons name="home-outline" size={38} color={MUTED} />
        </View>

        <Text style={styles.emptyHeading}>Your garage is empty</Text>
        <Text style={styles.emptyBody}>
          Add a vehicle to track its fuel, services and documents.
        </Text>

        <AppButton label="Add vehicle" onPress={onAdd} style={styles.emptyButton} />
      </View>
    </View>
  );
}

function GarageSkeleton() {
  return (
    <View style={styles.skeleton}>
      <ShimmerBox height={28} width={140} borderRadius={8} />
      <View style={styles.skeletonGap} />
      <ShimmerBox height={120} borderRadius={16} />
      <View style={styles.skeletonGapSmall} />
      <ShimmerBox height={120} borderRadius={16} />
      <View style={styles.skeletonGapSmall} />
      <ShimmerBox height={120} borderRadius={16} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 14,
  },
  headerTitle: {
    fontSize: 29,
    fontWeight: '800',
    letterSpacing: -0.6,
    color: INK,
    lineHeight: 30,
  },
  headerCount: {
    marginTop: 4,
    fontSize: 14,
    color: MUTED,
  },
  listContent: {
    paddingBottom: LIST_BOTTOM_PADDING,
  },
  addCardWrap: {
    paddingHorizontal: 20,
  },
  addCard: {
    height: 66,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.5)',
  },
  addCardText: {
    marginLeft: 9,
    color: MUTED,
    fontWeight: '700',
    fontSize: 16,
  },
  emptyRoot: {
    flex: 1,
  },
  emptyTitle: {
    paddingHorizontal: 20,
    paddingTop: 16,
  },
  emptyCenter: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingBottom: 80,
  },
  emptyIcon: {
    width: 80,
    height: 80,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.surface,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 3 },
    elevation: 3,
  },
  emptyHeading: {
    marginTop: 20,
    fontSize: 18,
    fontWeight: '800',
    letterSpacing: -0.3,
    color: INK,
  },
  emptyBody: {
    marginTop: 8,
    textAlign: 'center',
    fontSize: 14,
    color: MUTED,
    lineHeight: 20,
  },
  emptyButton: {
    marginTop: 24,
    alignSelf: 'stretch',
  },
  errorBox: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  errorText: {
    marginTop: 12,
    textAlign: 'center',
    color: Colors.danger,
  },
  retry: {
    marginTop: 16,
    alignSelf: 'stretch',
  },
  skeleton: {
    padding: 16,
    paddingBottom: LIST_BOTTOM_PADDING,
  },
  skeletonGap: {
    height: 16,
  },
  skeletonGapSmall: {
    height: 12,
  },
});
