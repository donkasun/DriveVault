/**
 * Greeting + avatar header. Parity with Flutter dashboard's `_Header`.
 */

import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { greetingFor, initialsFor } from '../helpers';

type Props = {
  displayName: string | null;
  photoUrl: string | null;
};

export function DashboardHeader({ displayName, photoUrl }: Props) {
  const rawName = displayName?.trim() ?? '';
  const hasName = rawName.length > 0;
  const initials = hasName ? initialsFor(rawName) : '?';

  return (
    <View style={styles.row}>
      <View>
        <Text style={styles.greeting}>{greetingFor(new Date().getHours())}</Text>
        {hasName ? <Text style={styles.name}>{rawName}</Text> : null}
      </View>
      {photoUrl != null ? (
        <Image source={{ uri: photoUrl }} style={styles.avatar} />
      ) : (
        <View style={[styles.avatar, styles.avatarFallback]}>
          <Text style={styles.avatarInitials}>{initials}</Text>
        </View>
      )}
    </View>
  );
}

const AVATAR_SIZE = 46;

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  greeting: {
    fontSize: 14,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  name: {
    fontSize: 26,
    fontWeight: '800',
    letterSpacing: -0.6,
    color: Colors.textPrimary,
  },
  avatar: {
    width: AVATAR_SIZE,
    height: AVATAR_SIZE,
    borderRadius: AVATAR_SIZE / 2,
  },
  avatarFallback: {
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarInitials: {
    color: Colors.onPrimary,
    fontWeight: '800',
    fontSize: 18,
  },
});
