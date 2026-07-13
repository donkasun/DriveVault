/**
 * Expo Router file params are string-only, so this re-derives the record from
 * the `useMaintenanceRecords` cache by `recordId` rather than passing the
 * whole object (Dart pushes the record directly as route `extra`).
 */

import { useLocalSearchParams, useRouter } from 'expo-router';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { MaintenanceFormScreen } from '@/features/maintenance/components/maintenance-form-screen';
import { useMaintenanceRecords } from '@/features/maintenance/hooks';

export default function EditMaintenanceRoute() {
  const { id, recordId } = useLocalSearchParams<{ id: string; recordId: string }>();
  const router = useRouter();
  const { data: records, isLoading } = useMaintenanceRecords(id);
  const record = records?.find((r) => r.id === recordId);

  if (isLoading || !record) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={Colors.textPrimary} />
      </View>
    );
  }

  return <MaintenanceFormScreen vehicleId={id} existing={record} onDone={() => router.back()} />;
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.surface,
  },
});
