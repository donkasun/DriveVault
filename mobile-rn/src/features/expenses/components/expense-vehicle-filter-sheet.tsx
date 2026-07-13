/**
 * Modal bottom sheet for the vehicle filter. Parity with Flutter
 * `expense_history_screen.dart`'s `_ExpenseFilterSheet` / `_VehicleFilterRow`.
 */

import { FlatList, Modal, Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import type { Vehicle } from '@/features/vehicles/types';
import { vehicleDisplayName } from '@/features/vehicles/types';

type Props = {
  visible: boolean;
  vehicles: Vehicle[];
  selectedVehicleId: string | null;
  onSelect: (vehicleId: string | null) => void;
  onClose: () => void;
};

type Row = { id: string | null; label: string; subtitle?: string | null };

export function ExpenseVehicleFilterSheet({
  visible,
  vehicles,
  selectedVehicleId,
  onSelect,
  onClose,
}: Props) {
  const rows: Row[] = [
    { id: null, label: 'All vehicles' },
    ...vehicles.map((v) => ({ id: v.id, label: vehicleDisplayName(v), subtitle: v.registrationNumber })),
  ];

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} />
      <View style={styles.sheet}>
        <View style={styles.grabber} />
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Filter</Text>
          <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={onClose} hitSlop={8}>
            <Text style={styles.closeGlyph}>✕</Text>
          </Pressable>
        </View>
        <Text style={styles.sectionLabel}>VEHICLE</Text>
        <FlatList
          data={rows}
          keyExtractor={(row) => row.id ?? 'all'}
          renderItem={({ item }) => (
            <VehicleRow
              row={item}
              selected={item.id === selectedVehicleId}
              onPress={() => {
                onSelect(item.id);
                onClose();
              }}
            />
          )}
        />
      </View>
    </Modal>
  );
}

function VehicleRow({ row, selected, onPress }: { row: Row; selected: boolean; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.row}>
      <View style={styles.rowTextCol}>
        <Text style={styles.rowLabel}>{row.label}</Text>
        {row.subtitle ? <Text style={styles.rowSubtitle}>{row.subtitle}</Text> : null}
      </View>
      {selected ? <Text style={styles.checkGlyph}>✓</Text> : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingBottom: 24,
    maxHeight: '70%',
  },
  grabber: {
    alignSelf: 'center',
    marginTop: 10,
    marginBottom: 2,
    width: 36,
    height: 4,
    borderRadius: 2,
    backgroundColor: Colors.divider,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  closeGlyph: {
    fontSize: 16,
    color: Colors.textMuted,
  },
  sectionLabel: {
    paddingHorizontal: 16,
    paddingBottom: 4,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.2,
    color: Colors.textMuted,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 13,
    borderBottomWidth: 0.5,
    borderBottomColor: Colors.divider,
  },
  rowTextCol: {
    flex: 1,
  },
  rowLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  rowSubtitle: {
    fontSize: 12,
    color: Colors.textMuted,
  },
  checkGlyph: {
    fontSize: 16,
    color: Colors.success,
  },
});
