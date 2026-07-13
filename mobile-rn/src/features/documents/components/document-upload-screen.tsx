/**
 * Add-document form. Parity with Flutter
 * `document_upload_screen.dart`.
 *
 * File source is a 3-way choice (camera / photo library / browse files) —
 * `Alert.alert` here is the RN equivalent of the Dart `showModalBottomSheet`
 * (same pattern already used by `vehicle-form-screen.tsx`'s photo picker).
 * "Browse files" uses `expo-document-picker` so PDFs can be attached, matching
 * the Dart `FilePicker.pickFiles(allowedExtensions: [pdf, jpg, jpeg, png, heic])`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import * as DocumentPicker from 'expo-document-picker';
import * as ImagePicker from 'expo-image-picker';
import { useState } from 'react';
import { Alert, Keyboard, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { FormScreenAppBar } from '@/components/form-screen-app-bar';
import { MaintenanceDateField } from '@/features/maintenance/components/maintenance-date-field';
import { Colors, Radii, Spacing } from '@/constants/theme';
import { uploadsRepository } from '@/features/uploads/repository';
import { useCreateDocument } from '../hooks';

/** Mirrors Dart `_docTypes` in `document_upload_screen.dart`. */
const DOC_TYPES = ['insurance', 'registration', 'service', 'other'] as const;

function titleCase(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

/** ext → mime, mirrors Dart's `ext == 'pdf' ? 'application/pdf' : 'image/$ext'`. */
function mimeForExtension(ext: string): string {
  const lower = ext.toLowerCase();
  return lower === 'pdf' ? 'application/pdf' : `image/${lower}`;
}

function extensionFromName(name: string): string {
  const dot = name.lastIndexOf('.');
  return dot === -1 ? '' : name.slice(dot + 1);
}

type PickedFile = {
  uri: string;
  name: string;
  mimeType: string;
  sizeBytes: number | null;
};

type Props = {
  vehicleId: string;
  onDone: () => void;
};

export function DocumentUploadScreen({ vehicleId, onDone }: Props) {
  const createDocument = useCreateDocument(vehicleId);

  const [docType, setDocType] = useState<string>('insurance');
  const [title, setTitle] = useState('Insurance');
  const [titleAutoSuggested, setTitleAutoSuggested] = useState('Insurance');
  const [issueDate, setIssueDate] = useState('');
  const [expiryDate, setExpiryDate] = useState('');
  const [file, setFile] = useState<PickedFile | null>(null);
  const [uploading, setUploading] = useState(false);
  const [docTypeError, setDocTypeError] = useState<string | null>(null);
  const [titleError, setTitleError] = useState<string | null>(null);
  const [fileError, setFileError] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  /**
   * Capitalises `type` and sets it as the title if the title is empty or
   * still equals the last auto-suggestion (user hasn't typed their own).
   * Mirrors Dart `_applyDocTypeSuggestion`.
   */
  function applyDocTypeSuggestion(type: string) {
    const suggestion = titleCase(type);
    setTitle((current) => {
      if (current === '' || current === titleAutoSuggested) {
        setTitleAutoSuggested(suggestion);
        return suggestion;
      }
      return current;
    });
  }

  function pickFile() {
    Alert.alert('Select file', undefined, [
      { text: 'Take photo', onPress: () => void captureFromCamera() },
      { text: 'Photo library', onPress: () => void captureFromLibrary() },
      { text: 'Browse files', onPress: () => void browseFiles() },
      { text: 'Cancel', style: 'cancel' },
    ]);
  }

  async function captureFromCamera() {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      Alert.alert('Permission required', 'Please grant camera access to continue.');
      return;
    }
    const result = await ImagePicker.launchCameraAsync({ mediaTypes: ['images'], quality: 0.85 });
    if (result.canceled || result.assets.length === 0) return;
    const asset = result.assets[0];
    setFile({
      uri: asset.uri,
      name: asset.fileName ?? `document-${Date.now()}.jpg`,
      mimeType: asset.mimeType ?? 'image/jpeg',
      sizeBytes: asset.fileSize ?? null,
    });
    setFileError(null);
  }

  async function captureFromLibrary() {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert('Permission required', 'Please grant photo library access to continue.');
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.85 });
    if (result.canceled || result.assets.length === 0) return;
    const asset = result.assets[0];
    setFile({
      uri: asset.uri,
      name: asset.fileName ?? `document-${Date.now()}.jpg`,
      mimeType: asset.mimeType ?? 'image/jpeg',
      sizeBytes: asset.fileSize ?? null,
    });
    setFileError(null);
  }

  async function browseFiles() {
    const result = await DocumentPicker.getDocumentAsync({
      type: ['application/pdf', 'image/jpeg', 'image/png', 'image/heic'],
      copyToCacheDirectory: true,
    });
    if (result.canceled || result.assets.length === 0) return;
    const asset = result.assets[0];
    const ext = extensionFromName(asset.name);
    setFile({
      uri: asset.uri,
      name: asset.name,
      mimeType: asset.mimeType ?? mimeForExtension(ext),
      sizeBytes: asset.size ?? null,
    });
    setFileError(null);
  }

  function validate(): boolean {
    let ok = true;
    if (!docType) {
      setDocTypeError('Please select a document type');
      ok = false;
    } else setDocTypeError(null);

    if (!title.trim()) {
      setTitleError('Required');
      ok = false;
    } else setTitleError(null);

    if (!file) {
      setFileError('Please select a file');
      ok = false;
    } else setFileError(null);

    return ok;
  }

  async function upload() {
    if (!validate() || !file) return;
    Keyboard.dismiss();
    setUploading(true);
    setSaveError(null);
    try {
      const folder = `vehicles/${vehicleId}/documents`;
      const uploadResult = await uploadsRepository.uploadFile(
        { uri: file.uri, name: file.name, mimeType: file.mimeType },
        folder,
      );

      await createDocument.mutateAsync({
        docType,
        title: title.trim(),
        storageUrl: uploadResult.secureUrl,
        storagePublicId: uploadResult.publicId,
        mimeType: file.mimeType,
        ...(file.sizeBytes != null ? { fileSizeBytes: file.sizeBytes } : {}),
        ...(issueDate ? { issueDate } : {}),
        ...(expiryDate ? { expiryDate } : {}),
      });

      onDone();
    } catch (e) {
      setSaveError(e instanceof Error ? `Upload failed: ${e.message}` : 'Upload failed');
    } finally {
      setUploading(false);
    }
  }

  return (
    <View style={styles.screen}>
      <FormScreenAppBar title="Add Document" saving={uploading} onCancel={onDone} onSave={upload} />
      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <FilePickerField fileName={file?.name ?? null} onPress={pickFile} />
        {fileError ? <Text style={styles.fieldError}>{fileError}</Text> : null}

        <View style={styles.fieldGap}>
          <BottomSheetPickerField
            label="Document Type *"
            sheetTitle="Select document type"
            value={docType}
            options={[...DOC_TYPES]}
            getOptionLabel={titleCase}
            onSelect={(value) => {
              setDocType(value);
              applyDocTypeSuggestion(value);
            }}
            error={docTypeError}
          />
        </View>

        <Field label="Title *" value={title} onChangeText={setTitle} error={titleError} />

        <MaintenanceDateField label="Issue Date" value={issueDate} onChange={setIssueDate} />
        <MaintenanceDateField label="Expiry Date" value={expiryDate} onChange={setExpiryDate} />

        {saveError ? <Text style={styles.saveError}>{saveError}</Text> : null}
      </ScrollView>
    </View>
  );
}

function FilePickerField({ fileName, onPress }: { fileName: string | null; onPress: () => void }) {
  return (
    <View style={styles.fieldGap}>
      <Pressable accessibilityRole="button" accessibilityLabel="Select file" onPress={onPress} style={styles.filePickerRow}>
        <Ionicons name="attach" size={18} color={Colors.textPrimary} />
        <Text style={styles.filePickerLabel} numberOfLines={1}>
          {fileName ?? 'Select File'}
        </Text>
      </Pressable>
    </View>
  );
}

type FieldProps = {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  error?: string | null;
};

function Field({ label, value, onChangeText, error }: FieldProps) {
  return (
    <View style={styles.fieldGap}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <View style={[styles.fieldInputWrap, !!error && styles.fieldInputWrapError]}>
        <TextInput
          style={styles.fieldInput}
          value={value}
          onChangeText={onChangeText}
          placeholderTextColor={Colors.textMuted}
        />
      </View>
      {error ? <Text style={styles.fieldError}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.surface,
  },
  content: {
    padding: Spacing.three,
    paddingBottom: 100,
  },
  fieldGap: {
    marginBottom: Spacing.two + 8,
  },
  fieldLabel: {
    fontSize: 12,
    color: Colors.textMuted,
    marginBottom: 4,
  },
  fieldInputWrap: {
    minHeight: 52,
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
  },
  fieldInputWrapError: {
    borderColor: Colors.danger,
  },
  fieldInput: {
    fontSize: 16,
    color: Colors.textPrimary,
    paddingVertical: 14,
  },
  fieldError: {
    marginTop: -4,
    marginBottom: Spacing.two,
    fontSize: 12,
    color: Colors.danger,
  },
  filePickerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
  },
  filePickerLabel: {
    marginLeft: 10,
    fontSize: 16,
    color: Colors.textPrimary,
  },
  saveError: {
    marginTop: 4,
    color: Colors.danger,
  },
});
