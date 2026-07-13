/**
 * Dark branded header: logo + wordmark, then a title and tagline.
 * Parity with Flutter login/signup `_BrandHeader`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Colors, Spacing } from '@/constants/theme';

type Props = {
  title: string;
  tagline: string;
};

export function BrandHeader({ title, tagline }: Props) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top + 20 }]}>
      {/* Decorative circle, top-right */}
      <View style={styles.circle} pointerEvents="none" />

      <View style={styles.logoRow}>
        <View style={styles.logoMark}>
          <Ionicons name="speedometer" size={22} color={Colors.onPrimary} />
        </View>
        <Text style={styles.wordmark}>DriveVault</Text>
      </View>

      <Text style={styles.title}>{title}</Text>
      <Text style={styles.tagline}>{tagline}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
    paddingHorizontal: Spacing.four,
    paddingBottom: 36,
    backgroundColor: Colors.surfaceDark,
    borderBottomLeftRadius: 32,
    borderBottomRightRadius: 32,
    overflow: 'hidden',
  },
  circle: {
    position: 'absolute',
    top: -20,
    right: -40,
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logoMark: {
    width: 40,
    height: 40,
    borderRadius: 11,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  wordmark: {
    marginLeft: 10,
    fontSize: 22,
    fontWeight: '800',
    color: Colors.textOnDark,
  },
  title: {
    marginTop: Spacing.four,
    fontSize: 30,
    fontWeight: '800',
    color: Colors.textOnDark,
    lineHeight: 33,
  },
  tagline: {
    marginTop: 6,
    fontSize: 14,
    fontWeight: '400',
    color: Colors.textOnDarkMuted,
  },
});
