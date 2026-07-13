/**
 * Stub route for the document viewer (Dart pushes a `MaterialPageRoute` to
 * `DocumentViewerScreen(document: doc)` — not a go_router path). This derives
 * the document from the `useDocuments` cache by `docId` rather than passing
 * the whole object through route params. A full PDF/image viewer is out of
 * scope for this port.
 */

import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import { useDocuments } from '@/features/documents/hooks';

export default function DocumentViewerRoute() {
  const { id, docId } = useLocalSearchParams<{ id: string; docId: string }>();
  const { data: docs } = useDocuments(id);
  const doc = docs?.find((d) => d.id === docId);

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.body}>
        <Text style={styles.title}>{doc?.title ?? 'Document'}</Text>
        <Text style={styles.subtitle}>Vehicle: {id}</Text>
        <Text style={styles.subtitle}>Document: {docId}</Text>
        <Text style={styles.note}>The document viewer has not been ported yet.</Text>
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
