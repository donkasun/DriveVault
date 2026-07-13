/**
 * Document viewer. Parity with Flutter `document_viewer_screen.dart`.
 *
 * Delete lives here (with a confirm dialog), not on the upload form —
 * `docs/ui-conventions.md`: destructive resource actions stay on detail/view
 * screens.
 *
 * KNOWN CONTRACT NOTE: `DELETE /documents/{id}` only removes the DB row — it
 * does not delete the underlying Cloudinary asset (the Dart source and the
 * real backend agree on this; `docs/03-api-contract.md` is wrong here).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import * as Linking from 'expo-linking';
import { useState } from 'react';
import { ActivityIndicator, Alert, Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { Colors } from '@/constants/theme';
import { isImageDocument, type Document } from '../types';
import { useDeleteDocument } from '../hooks';

type Props = {
  document: Document;
  onDeleted: () => void;
  onBack: () => void;
};

export function DocumentViewerScreen({ document, onDeleted, onBack }: Props) {
  const deleteDocument = useDeleteDocument(document.vehicleId);
  const [imageErrored, setImageErrored] = useState(false);
  const [imageLoading, setImageLoading] = useState(true);
  const [deleting, setDeleting] = useState(false);

  async function openInBrowser() {
    const canOpen = await Linking.canOpenURL(document.storageUrl);
    if (!canOpen) {
      Alert.alert('Could not open document');
      return;
    }
    await Linking.openURL(document.storageUrl);
  }

  function confirmDelete() {
    Alert.alert('Delete Document', `Delete "${document.title}"? This cannot be undone.`, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete', style: 'destructive', onPress: () => void doDelete() },
    ]);
  }

  async function doDelete() {
    setDeleting(true);
    try {
      await deleteDocument.mutateAsync(document.id);
      onDeleted();
    } catch (e) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete document');
    } finally {
      setDeleting(false);
    }
  }

  const isImage = isImageDocument(document);

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.header}>
        <Pressable accessibilityRole="button" accessibilityLabel="Back" onPress={onBack} hitSlop={8}>
          <Ionicons name="chevron-back" size={24} color={Colors.textPrimary} />
        </Pressable>
        <Text style={styles.headerTitle} numberOfLines={1}>
          {document.title}
        </Text>
        {deleting ? (
          <ActivityIndicator size="small" color={Colors.textPrimary} />
        ) : (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Delete document"
            onPress={confirmDelete}
            hitSlop={8}
          >
            <Ionicons name="trash-outline" size={22} color={Colors.textPrimary} />
          </Pressable>
        )}
      </View>

      {isImage ? (
        <View style={styles.imageBody}>
          {imageErrored ? (
            <Ionicons name="image-outline" size={64} color={Colors.textMuted} />
          ) : (
            <>
              <Image
                source={{ uri: document.storageUrl }}
                style={styles.image}
                resizeMode="contain"
                onLoadEnd={() => setImageLoading(false)}
                onError={() => {
                  setImageLoading(false);
                  setImageErrored(true);
                }}
              />
              {imageLoading ? (
                <ActivityIndicator style={styles.imageLoading} size="large" color={Colors.textPrimary} />
              ) : null}
            </>
          )}
        </View>
      ) : (
        <View style={styles.docBody}>
          <Ionicons name="document-text-outline" size={64} color={Colors.textMuted} />
          <Text style={styles.docTitle}>{document.title}</Text>
          <AppButton label="Open in Browser" onPress={() => void openInBrowser()} style={styles.openButton} />
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.surface,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    height: 56,
    paddingHorizontal: 16,
  },
  headerTitle: {
    flex: 1,
    marginHorizontal: 12,
    fontSize: 16,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  imageBody: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  imageLoading: {
    position: 'absolute',
  },
  docBody: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  docTitle: {
    marginTop: 16,
    fontSize: 16,
    fontWeight: '600',
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  openButton: {
    marginTop: 24,
    minWidth: 200,
  },
});
