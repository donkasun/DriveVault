/**
 * One row in the Activity list. Parity with Flutter activity screen's
 * `_ActivityTile` — tapping opens the relevant editor/viewer; long-press
 * offers delete (Dart uses swipe-to-delete; RN uses a long-press + confirm
 * dialog instead, a deliberate simplification for this platform).
 */

import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';

import { ActivityEntryCard } from '@/components/activity-entry-card';
import { FuelPumpIcon } from '@/components/fuel-pump-icon';
import { Colors } from '@/constants/theme';
import { useDeleteFuelLog } from '@/features/fuel-logs/hooks';
import { useDeleteMaintenanceRecord } from '@/features/maintenance/hooks';
import { activitySubLabel, activityTitle } from '../helpers';
import { activityQueryKey } from '../hooks';
import type { ActivityEntry } from '../types';

type Props = {
  entry: ActivityEntry;
  vehicleName: string;
  showVehicleName: boolean;
  onEditFuel: (entry: ActivityEntry) => void;
};

export function ActivityTile({ entry, vehicleName, showVehicleName, onEditFuel }: Props) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const deleteFuelLog = useDeleteFuelLog(entry.vehicleId);
  const deleteMaintenanceRecord = useDeleteMaintenanceRecord(entry.vehicleId);

  const handlePress = () => {
    switch (entry.type) {
      case 'fuel':
        onEditFuel(entry);
        break;
      case 'maintenance':
        router.push(`/garage/vehicle/${entry.vehicleId}/maintenance/${entry.id}`);
        break;
      case 'document':
        router.push(`/garage/vehicle/${entry.vehicleId}/documents/${entry.id}`);
        break;
    }
  };

  const handleLongPress = () => {
    Alert.alert('Delete Record', 'Delete this record? This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            if (entry.type === 'fuel') await deleteFuelLog.mutateAsync(entry.id);
            else if (entry.type === 'maintenance') await deleteMaintenanceRecord.mutateAsync(entry.id);
            else return; // Document deletion is owned by the documents feature (out of scope here).
            queryClient.invalidateQueries({ queryKey: activityQueryKey() });
          } catch {
            Alert.alert('Delete failed');
          }
        },
      },
    ]);
  };

  return (
    <Pressable
      style={styles.wrapper}
      onPress={handlePress}
      onLongPress={entry.type === 'document' ? undefined : handleLongPress}
    >
      <ActivityEntryCard
        icon={<TileIcon entry={entry} />}
        title={activityTitle(entry)}
        titleSub={showVehicleName ? vehicleName : null}
        subLabel={activitySubLabel(entry)}
        amountCents={entry.amountCents}
        currency={entry.currency}
      />
    </Pressable>
  );
}

function TileIcon({ entry }: { entry: ActivityEntry }) {
  if (entry.type === 'fuel') {
    const isFull = entry.isFullTank ?? true;
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
  if (entry.type === 'maintenance') {
    return (
      <View style={[styles.iconTile, { backgroundColor: 'rgba(30,29,43,0.08)' }]}>
        <Text style={styles.iconGlyph}>🔧</Text>
      </View>
    );
  }
  const isImage = entry.mimeType?.startsWith('image/') ?? false;
  const glyph = isImage ? '🖼️' : entry.mimeType === 'application/pdf' ? '📕' : '📄';
  return (
    <View style={[styles.iconTile, { backgroundColor: '#EEEEF5' }]}>
      <Text style={styles.iconGlyph}>{glyph}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    marginBottom: 10,
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
