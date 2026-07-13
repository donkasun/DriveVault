/** "By continuing you agree to our Terms & Privacy Policy" — pinned to the bottom. */

import { StyleSheet, Text } from 'react-native';

import { Colors } from '@/constants/theme';

export function TermsFootnote() {
  return (
    <Text style={styles.text}>
      By continuing you agree to our <Text style={styles.emphasis}>Terms</Text>
      {' & '}
      <Text style={styles.emphasis}>Privacy Policy</Text>
    </Text>
  );
}

const styles = StyleSheet.create({
  text: {
    textAlign: 'center',
    fontSize: 12,
    color: Colors.textMuted,
  },
  emphasis: {
    fontWeight: '600',
    color: Colors.textPrimary,
  },
});
