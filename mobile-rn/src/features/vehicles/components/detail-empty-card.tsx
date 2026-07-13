/**
 * Generic empty-state card: white rounded card, centered muted text.
 * Parity with Flutter `vehicle_detail_screen.dart` `_EmptyCard` (lines 1355-1376).
 */

import { StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';

export function DetailEmptyCard({ label }: { label: string }) {
  return (
    <View style={styles.card}>
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: 16,
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    paddingVertical: 20,
    alignItems: 'center',
    justifyContent: 'center',
    ...cardShadow,
  },
  label: {
    color: Colors.textMuted,
    fontSize: 14,
  },
});
