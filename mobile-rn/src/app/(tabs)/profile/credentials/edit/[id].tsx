/**
 * Edit-credential route. Derives the credential from the `useDrivingCredentials`
 * cache by `id` (Dart pushes the whole object via `extra:`; here we look it up
 * from the already-fetched list instead of re-fetching a single-item endpoint
 * that doesn't exist — see docs/03-api-contract.md, only list/create/update/delete
 * are defined).
 */

import { useLocalSearchParams, useRouter } from 'expo-router';
import { ActivityIndicator, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import { DrivingCredentialFormScreen } from '@/features/driving-credentials/components/driving-credential-form-screen';
import { useDrivingCredentials } from '@/features/driving-credentials/hooks';

export default function EditCredentialRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { data: credentials, isLoading } = useDrivingCredentials();
  const existing = credentials?.find((c) => c.id === id);

  if (isLoading || !existing) {
    return (
      <SafeAreaView style={styles.center} edges={['top']}>
        <ActivityIndicator size="large" color={Colors.textPrimary} />
      </SafeAreaView>
    );
  }

  return <DrivingCredentialFormScreen existing={existing} onDone={() => router.back()} />;
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.surface,
  },
});
