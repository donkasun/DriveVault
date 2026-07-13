/**
 * Edit-profile screen: display name (disabled for Google users), read-only
 * email + Unverified badge. Parity with Flutter
 * `profile/presentation/edit_profile_screen.dart`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useState } from 'react';
import { Alert, StyleSheet, Text, TextInput, View } from 'react-native';

import { FormScreenAppBar } from '@/components/form-screen-app-bar';
import { Colors, Radii, Spacing } from '@/constants/theme';
import { useAuthStore } from '@/features/auth/store';
import { useMe, useUpdateMe } from '../hooks';

const AVATAR_INK = '#1F2030'; // edit_profile_screen.dart line 97
const BADGE_BG = '#FDF3E4'; // line 209
const BADGE_INK = '#C96A00'; // line 218-226
const GOOGLE_FILL = '#F4F4F8'; // line 112

type Props = {
  onDone: () => void;
};

export function EditProfileScreen({ onDone }: Props) {
  const { data: user } = useMe();
  const authUser = useAuthStore((s) => s.user);
  const updateMe = useUpdateMe();

  const isGoogleUser = authUser ? !authUser.isPasswordProvider : false;
  const [displayName, setDisplayName] = useState(user?.displayName ?? '');
  const [error, setError] = useState<string | null>(null);

  const initial = displayName.trim() ? displayName.trim()[0].toUpperCase() : 'U';
  const emailVerified = authUser?.emailVerified ?? true;

  async function handleSave() {
    if (!isGoogleUser && displayName.trim().length === 0) {
      setError('Display name cannot be empty');
      return;
    }
    setError(null);

    try {
      await updateMe.mutateAsync({ displayName: displayName.trim() });
      onDone();
    } catch (e) {
      Alert.alert('Could not save', e instanceof Error ? e.message : String(e));
    }
  }

  return (
    <View style={styles.screen}>
      <FormScreenAppBar
        title="Edit Profile"
        saving={updateMe.isPending}
        cancelEnabled={!updateMe.isPending}
        onCancel={onDone}
        onSave={handleSave}
      />
      <View style={styles.content}>
        <View style={styles.avatarWrap}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{initial}</Text>
          </View>
        </View>

        <Text style={styles.fieldLabel}>DISPLAY NAME</Text>
        <TextInput
          value={displayName}
          onChangeText={setDisplayName}
          editable={!isGoogleUser}
          placeholder="Your name"
          style={[
            styles.input,
            isGoogleUser && styles.inputDisabled,
            !!error && styles.inputError,
          ]}
          onSubmitEditing={handleSave}
        />
        {isGoogleUser ? <Text style={styles.helper}>Synced from Google</Text> : null}
        {error ? <Text style={styles.errorText}>{error}</Text> : null}

        <View style={styles.fieldGap} />
        <Text style={styles.fieldLabel}>EMAIL</Text>
        <View style={styles.emailRow}>
          <Text style={styles.emailText}>{user?.email}</Text>
          {!emailVerified ? (
            <View style={styles.badge}>
              <Ionicons name="warning-outline" size={14} color={BADGE_INK} />
              <Text style={styles.badgeText}>Unverified</Text>
            </View>
          ) : null}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: Spacing.three,
  },
  avatarWrap: {
    alignItems: 'center',
    marginBottom: Spacing.four,
  },
  avatar: {
    width: 84,
    height: 84,
    borderRadius: 42,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 28,
    fontWeight: '800',
    color: AVATAR_INK,
  },
  fieldLabel: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
    color: Colors.textMuted,
    marginBottom: 8,
  },
  input: {
    minHeight: 52,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.card,
    paddingHorizontal: 16,
    fontSize: 16,
    color: Colors.textPrimary,
    backgroundColor: Colors.surface,
  },
  inputDisabled: {
    backgroundColor: GOOGLE_FILL,
  },
  inputError: {
    borderColor: Colors.danger,
  },
  helper: {
    marginTop: 6,
    fontSize: 12,
    color: Colors.textMuted,
  },
  errorText: {
    marginTop: 6,
    fontSize: 12,
    color: Colors.danger,
  },
  fieldGap: {
    height: Spacing.three,
  },
  emailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.card,
    paddingHorizontal: 16,
    paddingVertical: 14,
    backgroundColor: Colors.surface,
  },
  emailText: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    columnGap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: BADGE_BG,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: BADGE_INK,
  },
});
