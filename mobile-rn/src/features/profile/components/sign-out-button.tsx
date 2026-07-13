/**
 * Sign-out button — red styling, `Alert.alert` confirmation (the RN
 * equivalent of the Dart `showModalBottomSheet`, per
 * `docs/ui-conventions.md`: destructive actions use a confirmation sheet).
 * Parity with Flutter `_SignOutButton` / `_confirmSignOut` in `profile_screen.dart`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Alert, Pressable, StyleSheet, Text } from 'react-native';

import { Colors } from '@/constants/theme';

// One-off color lifted from `profile_screen.dart` `_SignOutButton` line 424/429.
const ICON_TINT = '#7D7D9A';

type Props = {
  onConfirm: () => void;
};

export function SignOutButton({ onConfirm }: Props) {
  const handlePress = () => {
    Alert.alert('Sign out?', 'You will need to sign in again to access your vehicles and data.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign Out', style: 'destructive', onPress: onConfirm },
    ]);
  };

  return (
    <Pressable onPress={handlePress} style={styles.button}>
      <Ionicons name="log-out-outline" size={18} color={ICON_TINT} />
      <Text style={styles.label}>Sign out</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    columnGap: 10,
    backgroundColor: Colors.surface,
    borderRadius: 14,
    paddingVertical: 14,
    shadowColor: '#000000',
    shadowOpacity: 0.07,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: ICON_TINT,
  },
});
