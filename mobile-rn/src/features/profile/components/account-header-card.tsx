/**
 * Account header card at the top of the profile screen: avatar initial,
 * display name (+ Unverified badge), email, chevron to edit. Parity with
 * Flutter `_AccountHeaderCard` in `profile_screen.dart`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import type { AuthUser } from '@/features/auth/types';
import type { AppUser } from '../types';

// One-off colors lifted from `profile_screen.dart` — not part of the shared
// theme, kept local per CLAUDE.md's "cite the Dart line" rule.
const AVATAR_BG = '#FFD200'; // line 295
const AVATAR_INK = '#1F2030'; // line 301
const NAME_COLOR = '#24243A'; // line 321
const EMAIL_COLOR = '#8F90A6'; // line 338
const CHEVRON_COLOR = '#C3C4D1'; // line 345
const BADGE_BG = '#FDF3E4'; // line 367
const BADGE_INK = '#C96A00'; // line 376-384

type Props = {
  user: AppUser;
  authUser: AuthUser | null;
  onPress: () => void;
};

export function AccountHeaderCard({ user, authUser, onPress }: Props) {
  const displayName = (user.displayName?.trim() ? user.displayName.trim() : user.email).trim();
  const initial = displayName.length > 0 ? displayName[0].toUpperCase() : 'U';
  const emailVerified = authUser?.emailVerified ?? true;

  return (
    <Pressable onPress={onPress} style={styles.card}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{initial}</Text>
      </View>
      <View style={styles.textCol}>
        <View style={styles.nameRow}>
          <Text style={styles.name} numberOfLines={1}>
            {displayName}
          </Text>
          {!emailVerified ? (
            <View style={styles.badge}>
              <Ionicons name="warning-outline" size={14} color={BADGE_INK} />
              <Text style={styles.badgeText}>Unverified</Text>
            </View>
          ) : null}
        </View>
        <Text style={styles.email} numberOfLines={1}>
          {user.email}
        </Text>
      </View>
      <Ionicons name="chevron-forward" size={22} color={CHEVRON_COLOR} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 22,
    paddingHorizontal: 16,
    paddingVertical: 18,
    shadowColor: '#000000',
    shadowOpacity: 0.07,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 6 },
    elevation: 2,
  },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: AVATAR_BG,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 20,
    fontWeight: '800',
    color: AVATAR_INK,
  },
  textCol: {
    flex: 1,
    marginLeft: 14,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    columnGap: 8,
  },
  name: {
    flexShrink: 1,
    fontSize: 18,
    fontWeight: '800',
    color: NAME_COLOR,
  },
  email: {
    marginTop: 2,
    fontSize: 13,
    fontWeight: '500',
    color: EMAIL_COLOR,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    backgroundColor: BADGE_BG,
    columnGap: 4,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: BADGE_INK,
  },
});
