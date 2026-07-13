/**
 * Add/edit vehicle form. Parity with Flutter
 * `features/vehicles/presentation/vehicle_form_screen.dart`.
 *
 * One component handles both modes: pass `vehicleId` to edit an existing
 * vehicle, omit it to create a new one. Only `hooks.ts` talks to the API —
 * this screen calls `useVehicle`/`useCreateVehicle`/`useUpdateVehicle`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import * as ImagePicker from 'expo-image-picker';
import { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Image,
  Keyboard,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { FormScreenAppBar } from '@/components/form-screen-app-bar';
import { Colors, Radii, Spacing } from '@/constants/theme';
import { useMe } from '@/features/profile/hooks';
import { uploadsRepository } from '@/features/uploads/repository';
import { effectiveUnit, type DistanceUnit } from '@/lib/distance-unit';
import { useCreateVehicle, useUpdateVehicle, useVehicle } from '../hooks';
import {
  buildCreatePayload,
  buildUpdatePayload,
  canSaveVehicleForm,
  DEFAULT_VEHICLE_TYPE,
  DISTANCE_UNIT_OPTIONS,
  fuelTypeFromDisplay,
  fuelTypeToDisplay,
  FUEL_TYPE_NONE,
  FUEL_TYPE_OPTIONS,
  initialMileageDisplayValue,
  VEHICLE_TYPES,
  validateRequired,
  validateYear,
  type VehicleFormState,
} from '../vehicle-form';

type Props = {
  /** Pass the vehicle id to edit an existing vehicle; omit to create a new one. */
  vehicleId?: string;
  onDone: () => void;
};

function titleCase(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

function fuelTypeLabel(type: string): string {
  return type === FUEL_TYPE_NONE ? 'Not specified' : titleCase(type);
}

export function VehicleFormScreen({ vehicleId, onDone }: Props) {
  const isEditMode = vehicleId != null;

  const { data: vehicle, isLoading: isLoadingVehicle } = useVehicle(vehicleId ?? '');
  const { data: me } = useMe();
  const createVehicle = useCreateVehicle();
  const updateVehicle = useUpdateVehicle(vehicleId ?? '');

  const userUnit: DistanceUnit = me?.distanceUnit ?? 'km';

  // Waiting on the vehicle fetch in edit mode before we can seed initial state.
  const ready = !isEditMode || vehicle != null;

  const [make, setMake] = useState('');
  const [model, setModel] = useState('');
  const [year, setYear] = useState('');
  const [yearError, setYearError] = useState<string | null>(null);
  const [registrationNumber, setRegistrationNumber] = useState('');
  const [mileageDisplay, setMileageDisplay] = useState('');
  const [vehicleType, setVehicleType] = useState<string | null>(DEFAULT_VEHICLE_TYPE);
  const [fuelType, setFuelType] = useState<string | null>(null);
  const [distanceUnit, setDistanceUnit] = useState<DistanceUnit | null>(null);
  const [photoUrl, setPhotoUrl] = useState<string | null>(null);
  const [photoPublicId, setPhotoPublicId] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [makeTouched, setMakeTouched] = useState(false);
  const [modelTouched, setModelTouched] = useState(false);

  // Seed form state from the fetched vehicle exactly once (edit mode only),
  // converting the stored km odometer to the display unit on first render —
  // parity with `_maybeConvertMileage`. A render-phase state update (not an
  // effect) so the seeded values show up in the same paint the data arrives.
  const [seededVehicleId, setSeededVehicleId] = useState<string | null>(null);
  if (ready && vehicle && seededVehicleId !== vehicle.id) {
    setSeededVehicleId(vehicle.id);
    setMake(vehicle.make);
    setModel(vehicle.model);
    setYear(vehicle.year != null ? String(vehicle.year) : '');
    setRegistrationNumber(vehicle.registrationNumber ?? '');
    setVehicleType(vehicle.vehicleType ?? DEFAULT_VEHICLE_TYPE);
    setFuelType(vehicle.fuelType);
    setDistanceUnit(vehicle.distanceUnit);
    setPhotoUrl(vehicle.photoUrl);
    setPhotoPublicId(vehicle.photoPublicId);

    const unit = effectiveUnit(vehicle.distanceUnit, userUnit);
    const storedKmText = vehicle.currentMileage != null ? String(vehicle.currentMileage) : '';
    setMileageDisplay(initialMileageDisplayValue(storedKmText, unit));
  }

  const distanceUnitDisplay: DistanceUnit = distanceUnit ?? vehicle?.distanceUnit ?? userUnit;
  const odometerUnitLabel = distanceUnitDisplay === 'mi' ? 'mi' : 'km';

  const canSave = !isSaving && canSaveVehicleForm(make, model);

  async function pickAndUploadPhoto() {
    Alert.alert('Add vehicle photo', undefined, [
      { text: 'Take photo', onPress: () => void capturePhoto('camera') },
      { text: 'Photo library', onPress: () => void capturePhoto('library') },
      { text: 'Cancel', style: 'cancel' },
    ]);
  }

  async function capturePhoto(source: 'camera' | 'library') {
    const permission =
      source === 'camera'
        ? await ImagePicker.requestCameraPermissionsAsync()
        : await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert('Permission required', 'Please grant access to continue.');
      return;
    }

    const result =
      source === 'camera'
        ? await ImagePicker.launchCameraAsync({ mediaTypes: ['images'], quality: 0.85 })
        : await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.85 });

    if (result.canceled || result.assets.length === 0) return;
    const asset = result.assets[0];

    setIsUploading(true);
    try {
      // File bytes never touch our backend — uploaded directly to Cloudinary
      // via a backend-signed request (CLAUDE.md).
      const uploadResult = await uploadsRepository.uploadFile(
        {
          uri: asset.uri,
          name: asset.fileName ?? `vehicle-${Date.now()}.jpg`,
          mimeType: asset.mimeType ?? 'image/jpeg',
        },
        'vehicles',
      );
      setPhotoUrl(uploadResult.secureUrl);
      setPhotoPublicId(uploadResult.publicId);
    } catch (e) {
      Alert.alert('Upload failed', String(e));
    } finally {
      setIsUploading(false);
    }
  }

  async function save() {
    const yearErr = validateYear(year);
    setYearError(yearErr);
    setMakeTouched(true);
    setModelTouched(true);
    if (yearErr || !canSaveVehicleForm(make, model)) return;

    Keyboard.dismiss();
    setIsSaving(true);

    const state: VehicleFormState = {
      make,
      model,
      year,
      registrationNumber,
      mileageDisplay,
      vehicleType,
      fuelType,
      distanceUnit,
      photoUrl,
      photoPublicId,
    };
    const effectiveDistUnit = effectiveUnit(distanceUnit ?? vehicle?.distanceUnit ?? null, userUnit);

    try {
      if (isEditMode && vehicle) {
        await updateVehicle.mutateAsync(buildUpdatePayload(state, effectiveDistUnit, vehicle));
      } else {
        await createVehicle.mutateAsync(buildCreatePayload(state, effectiveDistUnit));
      }
      onDone();
    } catch (e) {
      Alert.alert('Error', String(e));
    } finally {
      setIsSaving(false);
    }
  }

  const makeError = makeTouched ? validateRequired('Make', make) : null;
  const modelError = modelTouched ? validateRequired('Model', model) : null;

  if (isEditMode && isLoadingVehicle && !vehicle) {
    return (
      <View style={styles.screen}>
        <FormScreenAppBar title="Edit Vehicle" onCancel={onDone} />
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={Colors.textPrimary} />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.screen}>
      <FormScreenAppBar
        title={isEditMode ? 'Edit Vehicle' : 'Add Vehicle'}
        saving={isSaving}
        onCancel={onDone}
        onSave={canSave ? save : undefined}
      />
      <ScrollView
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
      >
        {/* Photo */}
        <PhotoArea photoUrl={photoUrl} isUploading={isUploading} onPress={pickAndUploadPhoto} />

        <SectionLabel text="Vehicle Details" />

        <View style={styles.row}>
          <View style={styles.flexHalf}>
            <FormField
              label="Make"
              required
              placeholder="Toyota"
              value={make}
              onChangeText={setMake}
              onBlur={() => setMakeTouched(true)}
              error={makeError}
              autoCapitalize="words"
            />
          </View>
          <View style={styles.gap} />
          <View style={styles.flexHalf}>
            <FormField
              label="Model"
              required
              placeholder="Hilux"
              value={model}
              onChangeText={setModel}
              onBlur={() => setModelTouched(true)}
              error={modelError}
              autoCapitalize="words"
            />
          </View>
        </View>

        <View style={styles.row}>
          <View style={styles.flexHalf}>
            <FormField
              label="Year"
              placeholder="2020"
              value={year}
              onChangeText={(text) => setYear(text.replace(/[^0-9]/g, ''))}
              onBlur={() => setYearError(validateYear(year))}
              error={yearError}
              keyboardType="number-pad"
            />
          </View>
          <View style={styles.gap} />
          <View style={styles.flexHalf}>
            <BottomSheetPickerField
              label="Type"
              sheetTitle="Select vehicle type"
              value={vehicleType}
              options={[...VEHICLE_TYPES]}
              getOptionLabel={titleCase}
              onSelect={setVehicleType}
            />
          </View>
        </View>

        <FormField
          label="Current Mileage"
          placeholder="e.g. 48000"
          value={mileageDisplay}
          onChangeText={(text) => setMileageDisplay(text.replace(/[^0-9]/g, ''))}
          keyboardType="number-pad"
          suffix={odometerUnitLabel}
        />

        <View style={styles.sectionGap} />
        <SectionLabel text="Registration & Fuel" />

        <FormField
          label="Registration Number"
          placeholder="e.g. ABC-1234"
          value={registrationNumber}
          onChangeText={setRegistrationNumber}
          autoCapitalize="characters"
        />

        <View style={styles.row}>
          <View style={styles.flexHalf}>
            <BottomSheetPickerField
              label="Fuel Type"
              sheetTitle="Select fuel type"
              value={fuelTypeToDisplay(fuelType)}
              options={FUEL_TYPE_OPTIONS}
              getOptionLabel={fuelTypeLabel}
              onSelect={(value) => setFuelType(fuelTypeFromDisplay(value))}
            />
          </View>
          <View style={styles.gap} />
          <View style={styles.flexHalf}>
            <BottomSheetPickerField
              label="Distance Unit"
              sheetTitle="Select distance unit"
              value={distanceUnitDisplay}
              options={DISTANCE_UNIT_OPTIONS}
              getOptionLabel={(unit) => unit}
              onSelect={setDistanceUnit}
            />
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

function SectionLabel({ text }: { text: string }) {
  return <Text style={styles.sectionLabel}>{text.toUpperCase()}</Text>;
}

type FormFieldProps = {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  onBlur?: () => void;
  placeholder?: string;
  required?: boolean;
  error?: string | null;
  keyboardType?: 'default' | 'number-pad';
  autoCapitalize?: 'none' | 'words' | 'characters';
  suffix?: string;
};

function FormField({
  label,
  value,
  onChangeText,
  onBlur,
  placeholder,
  required = false,
  error,
  keyboardType = 'default',
  autoCapitalize = 'none',
  suffix,
}: FormFieldProps) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{required ? `${label} *` : label}</Text>
      <View style={[styles.fieldInputWrap, !!error && styles.fieldInputWrapError]}>
        <TextInput
          style={styles.fieldInput}
          value={value}
          onChangeText={onChangeText}
          onBlur={onBlur}
          placeholder={placeholder}
          placeholderTextColor={Colors.textMuted}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
        />
        {suffix ? <Text style={styles.fieldSuffix}>{suffix}</Text> : null}
      </View>
      {error ? <Text style={styles.fieldError}>{error}</Text> : null}
    </View>
  );
}

function PhotoArea({
  photoUrl,
  isUploading,
  onPress,
}: {
  photoUrl: string | null;
  isUploading: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel="Add vehicle photo"
      disabled={isUploading}
      onPress={onPress}
      style={styles.photoArea}
    >
      {isUploading ? (
        <View style={styles.photoCenter}>
          <ActivityIndicator size="large" color={Colors.textPrimary} />
          <Text style={styles.photoUploading}>Uploading...</Text>
        </View>
      ) : photoUrl ? (
        <View style={StyleSheet.absoluteFill}>
          <Image source={{ uri: photoUrl }} style={StyleSheet.absoluteFill} resizeMode="cover" />
          <View style={styles.changePhotoBadge}>
            <Text style={styles.changePhotoText}>Change photo</Text>
          </View>
        </View>
      ) : (
        <View style={styles.photoCenter}>
          <View style={styles.photoIconWrap}>
            <Ionicons name="camera" size={28} color={Colors.textPrimary} />
          </View>
          <Text style={styles.photoAddText}>Add vehicle photo</Text>
        </View>
      )}
    </Pressable>
  );
}

const PHOTO_ACCENT = '#A06800';

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.surface,
  },
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    padding: Spacing.three,
    paddingBottom: 100,
  },
  row: {
    flexDirection: 'row',
    marginBottom: Spacing.two + 2,
  },
  flexHalf: {
    flex: 1,
  },
  gap: {
    width: Spacing.two + 2,
  },
  sectionGap: {
    height: Spacing.four,
  },
  sectionLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: Colors.textMuted,
    letterSpacing: 1.2,
    marginBottom: 10,
  },
  photoArea: {
    height: 130,
    borderRadius: Radii.card,
    backgroundColor: Colors.photoUploadTint,
    borderWidth: 1.5,
    borderColor: PHOTO_ACCENT,
    borderStyle: Platform.OS === 'ios' ? 'dashed' : 'dashed',
    overflow: 'hidden',
    marginBottom: Spacing.four,
  },
  photoCenter: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoUploading: {
    marginTop: 8,
    color: Colors.textMuted,
  },
  photoIconWrap: {
    width: 52,
    height: 52,
    borderRadius: 14,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoAddText: {
    marginTop: 10,
    color: PHOTO_ACCENT,
    fontSize: 14,
    fontWeight: '700',
  },
  changePhotoBadge: {
    position: 'absolute',
    bottom: 8,
    right: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: 'rgba(0,0,0,0.54)',
  },
  changePhotoText: {
    color: Colors.textOnDark,
    fontSize: 12,
  },
  field: {
    marginBottom: Spacing.two + 2,
  },
  fieldLabel: {
    fontSize: 12,
    color: Colors.textMuted,
    marginBottom: 4,
  },
  fieldInputWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
  },
  fieldInputWrapError: {
    borderColor: Colors.danger,
  },
  fieldInput: {
    flex: 1,
    fontSize: 16,
    color: Colors.textPrimary,
    paddingVertical: 14,
  },
  fieldSuffix: {
    marginLeft: Spacing.two,
    fontSize: 14,
    color: Colors.textMuted,
  },
  fieldError: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.danger,
  },
});
