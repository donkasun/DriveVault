/**
 * Stub route for "Upload" a document (Dart pushes
 * `/garage/vehicle/$id/documents/upload`). A full upload form (Cloudinary
 * signed upload + doc metadata) is out of scope for this port.
 */

import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';

export default function UploadDocumentRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.body}>
        <Text style={styles.title}>Upload document</Text>
        <Text style={styles.subtitle}>Vehicle: {id}</Text>
        <Text style={styles.note}>The document upload form has not been ported yet.</Text>
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
