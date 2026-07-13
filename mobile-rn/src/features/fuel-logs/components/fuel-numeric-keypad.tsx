/**
 * Custom one-handed numeric keypad for the quick fuel-entry sheet.
 * Parity with Flutter `fuel_numeric_keypad.dart`. Controlled: drives whichever
 * field's text is currently active via `value`/`onChange` (RN has no
 * `TextEditingController` to swap, so the parent owns the active field's text).
 *
 * Keys:
 *   Row 1: 1 2 3
 *   Row 2: 4 5 6
 *   Row 3: 7 8 9
 *   Row 4: . 0 ⌫
 * Each key is 48dp tall (>= 44dp a11y minimum).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { applyKeypadPress, BACKSPACE } from '../keypad-helpers';

const KEY_ROWS = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['.', '0', BACKSPACE],
];

type Props = {
  value: string;
  onChange: (next: string) => void;
};

export function FuelNumericKeypad({ value, onChange }: Props) {
  const press = (key: string) => onChange(applyKeypadPress(value, key));

  return (
    <View style={styles.container}>
      {KEY_ROWS.map((row, rowIndex) => (
        <View key={rowIndex} style={styles.row}>
          {row.map((key) => (
            <KeyButton key={key} label={key} onPress={() => press(key)} />
          ))}
        </View>
      ))}
    </View>
  );
}

function KeyButton({ label, onPress }: { label: string; onPress: () => void }) {
  const isDelete = label === BACKSPACE;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={isDelete ? 'Backspace' : label}
      testID={isDelete ? 'keypad_backspace' : `keypad_${label}`}
      onPress={onPress}
      style={({ pressed }) => [styles.key, pressed && styles.keyPressed]}
    >
      {isDelete ? (
        <Ionicons name="backspace-outline" size={20} color={Colors.textPrimary} />
      ) : (
        <Text style={styles.keyLabel}>{label}</Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  row: {
    flexDirection: 'row',
    marginVertical: 2,
    columnGap: 6,
  },
  key: {
    flex: 1,
    height: 48,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.surface,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 3,
    shadowOffset: { width: 0, height: 0.5 },
    elevation: 1,
  },
  keyPressed: {
    opacity: 0.7,
  },
  keyLabel: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
});
