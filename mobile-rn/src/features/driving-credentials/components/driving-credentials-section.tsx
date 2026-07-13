/**
 * Driving-credentials card on the profile screen: a list of the user's
 * credentials plus an "Add Credential" row (hidden once all doc types
 * exist). Parity with Flutter
 * `driving_credentials/presentation/driving_credentials_section.dart`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import { ActivityIndicator, Alert, Pressable, StyleSheet, Text, View } from 'react-native';

import { StatusPill, credentialStatusPill } from '@/components/status-pill';
import { Colors } from '@/constants/theme';
import { credentialLabelFor, type DrivingCredential } from '../types';
import { credentialExpiryText, credentialSubtitle, missingDocTypes } from '../credential-form';
import { useDeleteCredential, useDrivingCredentials } from '../hooks';

/** One-off icon tint lifted from `driving_credentials_section.dart` line 197-200. */
const ICON_BG = '#EFF2FF';
const ICON_TINT = '#3F5DE8';
const TEXT_PRIMARY = '#24243A'; // line 209-213
const TEXT_MUTED = '#9A9AAF'; // line 217-221
const CHEVRON = '#B8B8C8'; // line 236-238

function iconNameFor(docType: string): keyof typeof Ionicons.glyphMap {
  switch (docType) {
    case 'permit':
      return 'card-outline';
    case 'international_license':
      return 'language-outline';
    default:
      return 'car-outline';
  }
}

export function DrivingCredentialsSection() {
  const { data: creds, isLoading, isError, error } = useDrivingCredentials();
  const router = useRouter();
  const deleteCredential = useDeleteCredential();

  if (isLoading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="small" color={Colors.textPrimary} />
      </View>
    );
  }

  if (isError) {
    return (
      <Text style={styles.error}>
        Failed to load credentials: {error instanceof Error ? error.message : String(error)}
      </Text>
    );
  }

  const items = creds ?? [];
  const canAddMore = missingDocTypes(items).length > 0;

  const confirmDelete = (cred: DrivingCredential) => {
    const label = credentialLabelFor(cred.docType);
    Alert.alert(`Delete "${label}"?`, 'This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => deleteCredential.mutate(cred.id),
      },
    ]);
  };

  return (
    <View style={styles.card}>
      {items.map((cred, index) => (
        <View key={cred.id}>
          {index > 0 ? <View style={styles.divider} /> : null}
          <Pressable
            onPress={() => router.push(`/profile/credentials/edit/${cred.id}`)}
            onLongPress={() => confirmDelete(cred)}
            style={styles.row}
          >
            <View style={styles.iconWrap}>
              <Ionicons name={iconNameFor(cred.docType)} size={20} color={ICON_TINT} />
            </View>
            <View style={styles.rowText}>
              <Text style={styles.rowTitle} numberOfLines={1}>
                {credentialSubtitle(credentialLabelFor(cred.docType), cred.docNumber)}
              </Text>
              <Text style={styles.rowSubtitle}>{credentialExpiryText(cred.expiryDate)}</Text>
            </View>
            {cred.status ? (
              <View style={styles.pill}>
                <StatusPill {...credentialStatusPill(cred.status, cred.daysUntilExpiry ?? undefined)} />
              </View>
            ) : null}
            <Ionicons name="chevron-forward" size={20} color={CHEVRON} />
          </Pressable>
        </View>
      ))}

      {canAddMore ? (
        <View>
          {items.length > 0 ? <View style={styles.divider} /> : null}
          <Pressable onPress={() => router.push('/profile/credentials/add')} style={styles.addRow}>
            <Ionicons name="add-circle-outline" size={22} color={ICON_TINT} />
            <Text style={styles.addLabel}>Add Credential</Text>
          </Pressable>
        </View>
      ) : null}
    </View>
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
  loading: {
    height: 60,
    alignItems: 'center',
    justifyContent: 'center',
  },
  error: {
    color: Colors.danger,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.divider,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  iconWrap: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: ICON_BG,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowText: {
    flex: 1,
    marginLeft: 14,
  },
  rowTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: TEXT_PRIMARY,
  },
  rowSubtitle: {
    fontSize: 13,
    color: TEXT_MUTED,
    marginTop: 2,
  },
  pill: {
    marginRight: 8,
  },
  addRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 14,
  },
  addLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: ICON_TINT,
    marginLeft: 12,
  },
});
