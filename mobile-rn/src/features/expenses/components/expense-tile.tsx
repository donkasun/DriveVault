/**
 * One row in the expense list. Parity with Flutter
 * `expense_history_screen.dart`'s `_ExpenseTile` — tapping opens the
 * relevant editor; delete uses a long-press + confirm dialog (RN
 * simplification of Dart's swipe-to-dismiss, matching this codebase's
 * existing `activity/components/activity-tile.tsx`).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, Pressable, StyleSheet, View } from 'react-native';

import { ActivityEntryCard } from '@/components/activity-entry-card';
import { FuelPumpIcon } from '@/components/fuel-pump-icon';
import { Colors } from '@/constants/theme';
import { QuickFuelEntrySheet } from '@/features/fuel-logs/components/quick-fuel-entry-sheet';
import { useDeleteFuelLog } from '@/features/fuel-logs/hooks';
import { useDeleteMaintenanceRecord } from '@/features/maintenance/hooks';
import { expenseCategoryLabel, expenseSubLabel } from '../helpers';
import { invalidateExpensesFor } from '../hooks';
import type { Expense } from '../types';

type Props = {
  expense: Expense;
  vehicleName: string;
  showVehicleName: boolean;
};

export function ExpenseTile({ expense, vehicleName, showVehicleName }: Props) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const deleteFuelLog = useDeleteFuelLog(expense.vehicleId);
  const deleteMaintenanceRecord = useDeleteMaintenanceRecord(expense.vehicleId);
  const [editingFuel, setEditingFuel] = useState(false);

  const handlePress = () => {
    if (expense.kind === 'fuel') {
      setEditingFuel(true);
    } else {
      router.push(`/garage/vehicle/${expense.vehicleId}/maintenance/${expense.id}`);
    }
  };

  const handleLongPress = () => {
    Alert.alert('Delete Expense', 'Delete this expense? This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            if (expense.kind === 'fuel') await deleteFuelLog.mutateAsync(expense.id);
            else await deleteMaintenanceRecord.mutateAsync(expense.id);
            invalidateExpensesFor(queryClient, expense.vehicleId);
          } catch {
            Alert.alert('Delete failed');
          }
        },
      },
    ]);
  };

  return (
    <>
      <Pressable style={styles.wrapper} onPress={handlePress} onLongPress={handleLongPress}>
        <ActivityEntryCard
          icon={<TileIcon expense={expense} />}
          title={expenseCategoryLabel(expense)}
          titleSub={showVehicleName ? vehicleName : null}
          subLabel={expenseSubLabel(expense)}
          amountCents={expense.costCents}
          currency={expense.currency}
        />
      </Pressable>
      <QuickFuelEntrySheet
        visible={editingFuel}
        vehicleId={expense.vehicleId}
        existing={expense.fuelLog}
        onClose={() => {
          setEditingFuel(false);
          invalidateExpensesFor(queryClient, expense.vehicleId);
        }}
      />
    </>
  );
}

function TileIcon({ expense }: { expense: Expense }) {
  if (expense.kind === 'fuel') {
    const isFull = expense.fuelLog?.isFullTank ?? false;
    return (
      <View
        style={[styles.iconTile, { backgroundColor: isFull ? Colors.successBg : 'rgba(255,214,0,0.12)' }]}
      >
        <FuelPumpIcon isFullTank={isFull} size={20} darkInk={!isFull} />
      </View>
    );
  }
  return (
    <View style={[styles.iconTile, { backgroundColor: 'rgba(30,29,43,0.08)' }]}>
      <Ionicons name="build-outline" size={20} color={Colors.surfaceDark} />
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
});
