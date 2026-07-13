/**
 * Swipe-to-delete fuel-log row, tap opens the quick-entry sheet in edit mode.
 * Parity with Flutter `fuel_record_card.dart` (`Dismissible` + `AlertDialog`).
 * RN has no `Dismissible`; `react-native-gesture-handler`'s `Swipeable` (an
 * existing dependency) is the equivalent.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Swipeable } from 'react-native-gesture-handler';
import { useRef, useState } from 'react';
import { ActivityIndicator, Modal, Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { effectiveUnit, formatDistance, type DistanceUnit } from '@/lib/distance-unit';
import { formatCents } from '@/lib/formatting';
import { useMe } from '@/features/profile/hooks';
import { useVehicle } from '@/features/vehicles/hooks';
import { useDeleteFuelLog } from '../hooks';
import type { FuelLog } from '../types';
import { QuickFuelEntrySheet } from './quick-fuel-entry-sheet';

const dayMonthFmt = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short' });

function relativeDate(dateStr: string): string {
  const date = new Date(dateStr);
  if (Number.isNaN(date.getTime())) return dateStr;
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const diffDays = Math.round((today.getTime() - d.getTime()) / 86_400_000);
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  return dayMonthFmt.format(date);
}

type Props = {
  log: FuelLog;
  vehicleId: string;
};

export function FuelRecordCard({ log, vehicleId }: Props) {
  const { data: me } = useMe();
  const { data: vehicle } = useVehicle(vehicleId);
  const deleteFuelLog = useDeleteFuelLog(vehicleId);
  const swipeableRef = useRef<Swipeable>(null);

  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [editing, setEditing] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const currency = me?.currency ?? FALLBACK_CURRENCY;
  const unit: DistanceUnit = effectiveUnit(vehicle?.distanceUnit ?? null, me?.distanceUnit ?? 'km');
  const subLabel = `${log.liters.toFixed(1)} L · ${formatDistance(log.odometer, unit)} · ${
    log.isFullTank ? 'Full' : 'Partial'
  }`;

  async function confirmDelete() {
    setDeleteError(null);
    try {
      await deleteFuelLog.mutateAsync(log.id);
      setConfirmingDelete(false);
    } catch (e) {
      setDeleteError(e instanceof Error ? e.message : 'Delete failed');
    }
  }

  return (
    <>
      <Swipeable
        ref={swipeableRef}
        renderRightActions={() => (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Delete fuel log"
            onPress={() => {
              swipeableRef.current?.close();
              setConfirmingDelete(true);
            }}
            style={styles.deleteAction}
          >
            <Ionicons name="trash-outline" size={22} color="#FFFFFF" />
          </Pressable>
        )}
      >
        <Pressable accessibilityRole="button" onPress={() => setEditing(true)} style={styles.row}>
          <View style={[styles.icon, { backgroundColor: log.isFullTank ? Colors.successBg : 'rgba(255,214,0,0.12)' }]}>
            <Ionicons name="water" size={20} color={log.isFullTank ? Colors.success : Colors.onPrimary} />
          </View>
          <View style={styles.body}>
            <Text style={styles.title} numberOfLines={1}>
              {relativeDate(log.date)}
            </Text>
            <Text style={styles.subtitle} numberOfLines={1}>
              {subLabel}
            </Text>
          </View>
          <Text style={styles.amount}>{formatCents(log.priceCents, currency)}</Text>
        </Pressable>
      </Swipeable>

      <Modal visible={confirmingDelete} transparent animationType="fade" onRequestClose={() => setConfirmingDelete(false)}>
        <Pressable style={styles.backdrop} onPress={() => setConfirmingDelete(false)} accessibilityLabel="Dismiss" />
        <View style={styles.dialogWrap}>
          <View style={styles.dialog}>
            <Text style={styles.dialogTitle}>Delete Fuel Log</Text>
            <Text style={styles.dialogBody}>Delete the fuel log for {log.date}? This cannot be undone.</Text>
            {deleteError ? <Text style={styles.dialogError}>{deleteError}</Text> : null}
            <View style={styles.dialogActions}>
              <Pressable accessibilityRole="button" onPress={() => setConfirmingDelete(false)} style={styles.dialogButton}>
                <Text style={styles.dialogCancel}>Cancel</Text>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                disabled={deleteFuelLog.isPending}
                onPress={confirmDelete}
                style={styles.dialogButton}
              >
                {deleteFuelLog.isPending ? (
                  <ActivityIndicator size="small" color={Colors.danger} />
                ) : (
                  <Text style={styles.dialogDelete}>Delete</Text>
                )}
              </Pressable>
            </View>
          </View>
        </View>
      </Modal>

      <QuickFuelEntrySheet visible={editing} existing={log} onClose={() => setEditing(false)} />
    </>
  );
}

const styles = StyleSheet.create({
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
  icon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  body: {
    flex: 1,
    marginLeft: 13,
  },
  title: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  subtitle: {
    marginTop: 1,
    fontSize: 12.5,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  amount: {
    marginLeft: 8,
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  deleteAction: {
    width: 64,
    marginBottom: 10,
    borderRadius: Radii.card,
    marginRight: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FF3B30',
  },
  backdrop: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  dialogWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  dialog: {
    width: '100%',
    padding: 20,
    borderRadius: Radii.card,
    backgroundColor: Colors.surface,
  },
  dialogTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  dialogBody: {
    marginTop: 8,
    color: Colors.textMuted,
  },
  dialogError: {
    marginTop: 8,
    color: Colors.danger,
  },
  dialogActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 20,
    columnGap: 16,
  },
  dialogButton: {
    minWidth: 44,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dialogCancel: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  dialogDelete: {
    fontSize: 15,
    fontWeight: '600',
    color: '#FF3B30',
  },
});
