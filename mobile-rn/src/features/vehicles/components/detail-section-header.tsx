/**
 * Section header with a title, optional item count, and a dark-on-yellow
 * "+ Label" pill button. Parity with Flutter `vehicle_detail_screen.dart`
 * `_SectionHeader` (lines 673-732).
 */

import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';

type Props = {
  title: string;
  count?: number | null;
  buttonLabel: string;
  onAdd: () => void;
};

export function DetailSectionHeader({ title, count, buttonLabel, onAdd }: Props) {
  return (
    <View style={styles.row}>
      <Text style={styles.title}>{title}</Text>
      {count != null ? <Text style={styles.count}>{count}</Text> : null}
      <View style={styles.spacer} />
      <Pressable accessibilityRole="button" onPress={onAdd} style={styles.button}>
        <Text style={styles.buttonLabel}>+ {buttonLabel}</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 24,
    paddingBottom: 10,
  },
  title: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  count: {
    marginLeft: 6,
    fontSize: 17,
    fontWeight: '400',
    color: Colors.textMuted,
  },
  spacer: {
    flex: 1,
  },
  button: {
    backgroundColor: Colors.onPrimary,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 999,
  },
  buttonLabel: {
    color: Colors.primary,
    fontWeight: '700',
    fontSize: 13,
  },
});
