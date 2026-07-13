/** Tinted error box above the form. Parity with Flutter's `_errorMessage` container. */

import { StyleSheet, Text, View } from 'react-native';

import { Colors, Spacing } from '@/constants/theme';

export function AuthErrorBanner({ message }: { message: string | null }) {
  if (!message) return null;

  return (
    <View style={styles.container} accessibilityRole="alert">
      <Text style={styles.text}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 12,
    borderRadius: 10,
    backgroundColor: Colors.dangerBg,
    marginBottom: Spacing.three,
  },
  text: {
    fontSize: 14,
    color: Colors.danger,
  },
});
