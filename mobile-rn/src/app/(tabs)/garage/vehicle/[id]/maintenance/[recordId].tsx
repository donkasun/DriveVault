/**
 * Stub route for editing a maintenance record (Dart pushes
 * `/garage/vehicle/$id/maintenance/edit` with the record as `extra`). Expo
 * Router file params are string-only, so this takes `recordId` and re-derives
 * the record from the `useMaintenanceRecords` cache rather than passing the
 * whole object. A full edit form is out of scope for this port.
 */

import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import { useMaintenanceRecords } from '@/features/maintenance/hooks';

export default function EditMaintenanceRoute() {
  const { id, recordId } = useLocalSearchParams<{ id: string; recordId: string }>();
  const { data: records } = useMaintenanceRecords(id);
  const record = records?.find((r) => r.id === recordId);

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.body}>
        <Text style={styles.title}>{record?.serviceType ?? 'Edit service'}</Text>
        <Text style={styles.subtitle}>Vehicle: {id}</Text>
        <Text style={styles.subtitle}>Record: {recordId}</Text>
        <Text style={styles.note}>The edit-maintenance form has not been ported yet.</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  body: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  subtitle: {
    marginTop: 8,
    color: Colors.textMuted,
  },
  note: {
    marginTop: 16,
    textAlign: 'center',
    color: Colors.textMuted,
  },
});
