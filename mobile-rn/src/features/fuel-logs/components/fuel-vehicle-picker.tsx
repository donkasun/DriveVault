/**
 * Vehicle selector row + picker modal for the quick fuel-entry sheet.
 * Parity with Flutter `quick_fuel_entry_sheet.dart` `_buildVehicleSelector` /
 * `_VehiclePickerSheet` (lines 518-597, 1014-1132).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Image } from 'expo-image';
import { FlatList, Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import type { Vehicle } from '@/features/vehicles/types';

/** One-off literal, Dart `quick_fuel_entry_sheet.dart` line 526. */
const SELECTOR_BG = '#F2F2F7';

function vehicleTypeIcon(type: string | null): React.ComponentProps<typeof Ionicons>['name'] {
  switch (type) {
    case 'motorcycle':
      return 'bicycle-outline';
    case 'truck':
    case 'pickup':
      return 'car-outline';
    case 'van':
      return 'bus-outline';
    default:
      return 'car-sport-outline';
  }
}

function VehicleIcon({ vehicle, size = 34 }: { vehicle: Vehicle | undefined; size?: number }) {
  if (vehicle?.photoUrl) {
    return (
      <Image
        source={{ uri: vehicle.photoUrl }}
        style={{ width: size, height: size, borderRadius: 9 }}
        contentFit="cover"
      />
    );
  }
  return (
    <View
      style={[
        styles.iconWrap,
        { width: size, height: size, backgroundColor: 'rgba(255,214,0,0.12)' },
      ]}
    >
      <Ionicons name={vehicleTypeIcon(vehicle?.vehicleType ?? null)} size={size * 0.55} color="#A06800" />
    </View>
  );
}

type SelectorProps = {
  vehicles: Vehicle[];
  selected: Vehicle | undefined;
  onPress: () => void;
};

export function FuelVehicleSelector({ vehicles, selected, onPress }: SelectorProps) {
  const tappable = vehicles.length > 1;
  return (
    <Pressable
      accessibilityRole="button"
      disabled={!tappable}
      onPress={onPress}
      style={styles.selector}
    >
      <VehicleIcon vehicle={selected} />
      <View style={styles.selectorText}>
        <Text style={styles.selectorName} numberOfLines={1}>
          {selected ? `${selected.make} ${selected.model}` : '—'}
        </Text>
        {selected?.registrationNumber ? (
          <Text style={styles.selectorReg} numberOfLines={1}>
            {selected.registrationNumber}
          </Text>
        ) : null}
      </View>
      {tappable ? <Ionicons name="chevron-down" size={20} color={Colors.textMuted} /> : null}
    </Pressable>
  );
}

type PickerProps = {
  visible: boolean;
  vehicles: Vehicle[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onClose: () => void;
};

export function FuelVehiclePickerModal({ visible, vehicles, selectedId, onSelect, onClose }: PickerProps) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} accessibilityLabel="Dismiss" />
      <View style={styles.sheet}>
        <SafeAreaView edges={['bottom']}>
          <View style={styles.handle} />
          <View style={styles.sheetHeader}>
            <Text style={styles.sheetTitle}>Select vehicle</Text>
            <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={onClose} style={styles.close}>
              <Ionicons name="close" size={18} color={Colors.textPrimary} />
            </Pressable>
          </View>
          <FlatList
            data={vehicles}
            keyExtractor={(v) => v.id}
            style={styles.list}
            renderItem={({ item }) => (
              <Pressable
                accessibilityRole="button"
                onPress={() => onSelect(item.id)}
                style={styles.row}
              >
                <VehicleIcon vehicle={item} size={38} />
                <View style={styles.selectorText}>
                  <Text style={styles.rowName} numberOfLines={1}>
                    {item.make} {item.model}
                  </Text>
                  {item.registrationNumber ? (
                    <Text style={styles.selectorReg} numberOfLines={1}>
                      {item.registrationNumber}
                    </Text>
                  ) : null}
                </View>
                {item.id === selectedId ? (
                  <Ionicons name="checkmark" size={20} color={Colors.success} />
                ) : null}
              </Pressable>
            )}
          />
        </SafeAreaView>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  selector: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 16,
    marginBottom: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 13,
    backgroundColor: SELECTOR_BG,
  },
  iconWrap: {
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
  },
  selectorText: {
    flex: 1,
    marginLeft: 11,
  },
  selectorName: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  selectorReg: {
    fontSize: 11,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  backdrop: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    marginTop: 'auto',
    maxHeight: '70%',
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
  },
  handle: {
    alignSelf: 'center',
    width: 36,
    height: 4,
    borderRadius: 2,
    backgroundColor: Colors.divider,
    marginTop: 10,
    marginBottom: 2,
  },
  sheetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 8,
  },
  sheetTitle: {
    flex: 1,
    fontSize: 20,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  close: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background,
  },
  list: {
    maxHeight: 400,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.divider,
  },
  rowName: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
});
