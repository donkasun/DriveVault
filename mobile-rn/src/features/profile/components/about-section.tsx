/**
 * "About" card: Privacy & data / Help & feedback placeholders + app version
 * row. Parity with Flutter `_AboutSection` in `profile_screen.dart`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import Constants from 'expo-constants';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';

// One-off colors lifted from `profile_screen.dart` `_AboutRow`/`_AboutVersionRow`.
const ICON_BG = '#F6F6FC'; // line 509/546
const ICON_TINT = '#8E8EA8'; // line 512/553
const LABEL_COLOR = '#24243A'; // line 521
const CHEVRON_COLOR = '#B8B8C8'; // line 525
const VERSION_COLOR = '#B0B0C0'; // line 573

const APP_VERSION = Constants.expoConfig?.version ?? '1.0.0';

function showPlaceholder(label: string) {
  Alert.alert(`${label} coming soon`);
}

export function AboutSection() {
  return (
    <View style={styles.card}>
      <AboutRow icon="shield-outline" label="Privacy & data" onPress={() => showPlaceholder('Privacy & data')} />
      <View style={styles.divider} />
      <AboutRow icon="mail-outline" label="Help & feedback" onPress={() => showPlaceholder('Help & feedback')} />
      <View style={styles.divider} />
      <View style={styles.row}>
        <View style={styles.iconWrap}>
          <Ionicons name="settings-outline" size={20} color={ICON_TINT} />
        </View>
        <Text style={styles.label}>Version</Text>
        <Text style={styles.version}>{APP_VERSION}</Text>
      </View>
    </View>
  );
}

function AboutRow({
  icon,
  label,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={styles.row}>
      <View style={styles.iconWrap}>
        <Ionicons name={icon} size={20} color={ICON_TINT} />
      </View>
      <Text style={styles.label}>{label}</Text>
      <Ionicons name="chevron-forward" size={22} color={CHEVRON_COLOR} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 18,
    shadowColor: '#000000',
    shadowOpacity: 0.07,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 6 },
    elevation: 2,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.divider,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  iconWrap: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: ICON_BG,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    flex: 1,
    marginLeft: 14,
    fontSize: 15,
    fontWeight: '700',
    color: LABEL_COLOR,
  },
  version: {
    fontSize: 14,
    fontWeight: '700',
    color: VERSION_COLOR,
  },
});
