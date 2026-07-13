/**
 * Document viewer route (Dart pushes a `MaterialPageRoute` to
 * `DocumentViewerScreen(document: doc)` — not a go_router path). This derives
 * the document from the `useDocuments` cache by `docId` rather than passing
 * the whole object through route params.
 */

import { useLocalSearchParams, useRouter } from 'expo-router';
import { ActivityIndicator, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/theme';
import { DocumentViewerScreen } from '@/features/documents/components/document-viewer-screen';
import { useDocuments } from '@/features/documents/hooks';

export default function DocumentViewerRoute() {
  const { id, docId } = useLocalSearchParams<{ id: string; docId: string }>();
  const router = useRouter();
  const { data: docs, isLoading } = useDocuments(id);
  const doc = docs?.find((d) => d.id === docId);

  if (isLoading || !doc) {
    return (
      <SafeAreaView style={styles.center} edges={['top']}>
        <ActivityIndicator size="large" color={Colors.textPrimary} />
      </SafeAreaView>
    );
  }

  return (
    <DocumentViewerScreen document={doc} onBack={() => router.back()} onDeleted={() => router.back()} />
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.surface,
  },
});
