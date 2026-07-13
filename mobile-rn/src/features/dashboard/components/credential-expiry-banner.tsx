/**
 * Surfaces the most urgent personal driving-credential expiry (license,
 * permit, international license) on the dashboard. Parity with Flutter
 * `features/dashboard/presentation/widgets/credential_expiry_banner.dart`.
 *
 * Per-session dismissible (component state — resets on remount/app restart).
 */

import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { credentialLabelFor } from '@/features/driving-credentials/types';
import { useDrivingCredentials } from '@/features/driving-credentials/hooks';

export function CredentialExpiryBanner() {
  const [dismissed, setDismissed] = useState(false);
  const { data: credentials } = useDrivingCredentials();

  if (dismissed || !credentials) return null;

  const urgent = credentials.filter((c) => c.status === 'soon' || c.status === 'overdue');
  if (urgent.length === 0) return null;

  const first = urgent[0]!;
  const label = credentialLabelFor(first.docType);
  const days = first.daysUntilExpiry;
  const isOverdue = first.status === 'overdue';

  const subtitle = isOverdue
    ? 'Expired — update your credentials'
    : days != null
      ? `Expires in ${days} day${days === 1 ? '' : 's'}`
      : 'Expiring soon';

  const bgColor = isOverdue ? '#FFF0F0' : Colors.photoUploadTint;
  const borderColor = isOverdue ? '#FFCDD2' : 'rgba(251,191,36,0.30)'; // AppColors.warning @ 30%
  const titleColor = isOverdue ? Colors.danger : Colors.textPrimary;

  return (
    <View style={[styles.card, { backgroundColor: bgColor, borderColor }]}>
      <Text style={styles.icon}>⚠️</Text>
      <View style={styles.textCol}>
        <Text style={[styles.title, { color: titleColor }]}>{label}</Text>
        <Text style={styles.subtitle}>{subtitle}</Text>
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Dismiss"
        hitSlop={8}
        onPress={() => setDismissed(true)}
        style={styles.dismiss}
      >
        <Text style={styles.dismissGlyph}>✕</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 12,
  },
  icon: {
    fontSize: 20,
  },
  textCol: {
    flex: 1,
    marginLeft: 12,
  },
  title: {
    fontSize: 13,
    fontWeight: '700',
  },
  subtitle: {
    marginTop: 2,
    fontSize: 12,
    fontWeight: '400',
    color: Colors.textMuted,
  },
  dismiss: {
    marginLeft: 8,
    padding: 4,
  },
  dismissGlyph: {
    fontSize: 14,
    color: Colors.textMuted,
  },
});
