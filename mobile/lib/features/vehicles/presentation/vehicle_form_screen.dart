import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/distance_unit.dart';
import '../../../shared/widgets/bottom_sheet_picker_field.dart';
import '../../../shared/widgets/dashed_border.dart';
import '../../../shared/widgets/form_screen_app_bar.dart';
import '../../profile/data/user_repository.dart';
import '../data/upload_repository.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';
import 'vehicles_provider.dart';

/// Possible vehicle types matching the backend enum.
const _vehicleTypes = ['car', 'pickup', 'van', 'truck', 'motorcycle', 'other'];

/// Fuel types matching the backend enum (fixed per vehicle).
const _fuelTypes = ['petrol', 'diesel', 'electric', 'hybrid', 'other'];

/// Sentinel value representing "no fuel type selected" (null in state/API).
const _kFuelTypeNone = '__none__';

/// All fuel type options including the "Not specified" sentinel.
const _fuelTypeOptions = [_kFuelTypeNone, ..._fuelTypes];

const _distanceUnitOptions = ['km', 'mi'];

class VehicleFormScreen extends ConsumerStatefulWidget {
  /// Pass a vehicle to enter edit mode; null = add mode.
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _regCtrl;
  late final TextEditingController _mileageCtrl;

  String? _vehicleType;
  String? _fuelType;

  /// Per-vehicle distance-unit override: null = inherit user default.
  String? _distanceUnit;
  String? _photoUrl;
  String? _photoPublicId;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _mileageConverted = false; // ensure we only convert km→display once

  bool get _isEditMode => widget.vehicle != null;

  bool get _canSave =>
      !_isSaving &&
      _makeCtrl.text.trim().isNotEmpty &&
      _modelCtrl.text.trim().isNotEmpty;

  /// Maps the nullable [_fuelType] to the sentinel string used by the picker.
  String get _fuelTypeDisplay => _fuelType ?? _kFuelTypeNone;

  /// Maps a picker value (possibly the sentinel) back to a nullable fuel type.
  void _setFuelType(String picked) =>
      setState(() => _fuelType = picked == _kFuelTypeNone ? null : picked);

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(
      text: v?.year != null ? v!.year.toString() : '',
    );
    _regCtrl = TextEditingController(text: v?.registrationNumber ?? '');
    _mileageCtrl = TextEditingController(
      text: v?.currentMileage != null ? v!.currentMileage.toString() : '',
    );
    _vehicleType = v?.vehicleType ?? 'car';
    _fuelType = v?.fuelType;
    _distanceUnit = v?.distanceUnit;
    _photoUrl = v?.photoUrl;
    _photoPublicId = v?.photoPublicId;

    _makeCtrl.addListener(_onRequiredFieldChanged);
    _modelCtrl.addListener(_onRequiredFieldChanged);
  }

  void _onRequiredFieldChanged() => setState(() {});

  /// On first build, convert the pre-filled km value to the display unit
  /// so the odometer field shows the correct unit when editing.
  void _maybeConvertMileage(DistanceUnit unit) {
    if (_mileageConverted) return;
    _mileageConverted = true;
    if (unit == DistanceUnit.km) return; // stored km == displayed km, no-op
    final raw = int.tryParse(_mileageCtrl.text.trim());
    if (raw == null || raw == 0) return;
    _mileageCtrl.text = kmToDisplay(raw, unit).round().toString();
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _regCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    setState(() => _isUploading = true);

    try {
      final result = await ref
          .read(uploadRepositoryProvider)
          .uploadFile(bytes, 'vehicles', filename: pickedFile.name);
      setState(() {
        _photoUrl = result.secureUrl;
        _photoPublicId = result.publicId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
    };
    final year = int.tryParse(_yearCtrl.text.trim());
    if (year != null) data['year'] = year;
    final reg = _regCtrl.text.trim();
    if (reg.isNotEmpty) data['registrationNumber'] = reg;
    // Convert mileage from display unit back to km for storage.
    final userUnit = ref.read(meProvider).asData?.value.distanceUnit ?? 'km';
    final effectiveDistUnit = effectiveUnit(
      vehicleUnit: _distanceUnit ?? widget.vehicle?.distanceUnit,
      userUnit: userUnit,
    );
    final mileageDisplay = double.tryParse(_mileageCtrl.text.trim());
    if (mileageDisplay != null) {
      data['currentMileage'] = displayToKm(mileageDisplay, effectiveDistUnit);
    }
    if (_vehicleType != null) data['vehicleType'] = _vehicleType;

    if (_isEditMode) {
      final orig = widget.vehicle!;
      if (_fuelType != orig.fuelType) data['fuelType'] = _fuelType;
      if (_distanceUnit != orig.distanceUnit) {
        data['distanceUnit'] = _distanceUnit;
      }
    } else {
      if (_fuelType != null) data['fuelType'] = _fuelType;
      if (_distanceUnit != null) data['distanceUnit'] = _distanceUnit;
    }

    if (_photoUrl != null) data['photoUrl'] = _photoUrl;
    if (_photoPublicId != null) data['photoPublicId'] = _photoPublicId;

    try {
      if (_isEditMode) {
        await ref
            .read(vehiclesProvider.notifier)
            .updateVehicle(widget.vehicle!.id, data);
        ref.invalidate(vehicleProvider(widget.vehicle!.id));
      } else {
        await ref.read(vehiclesProvider.notifier).create(data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userUnit = ref.watch(meProvider).asData?.value.distanceUnit ?? 'km';
    final distanceUnitDisplay =
        _distanceUnit ?? widget.vehicle?.distanceUnit ?? userUnit;
    final odometerUnitLabel = distanceUnitDisplay == 'mi' ? 'mi' : 'km';
    final displayUnit = DistanceUnit.fromString(distanceUnitDisplay);

    // Convert stored km to display unit on the first render (edit mode only).
    _maybeConvertMileage(displayUnit);

    return Scaffold(
      appBar: FormScreenAppBar(
        title: _isEditMode ? 'Edit Vehicle' : 'Add Vehicle',
        saving: _isSaving,
        onCancel: () => context.pop(),
        onSave: _canSave ? _save : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo ────────────────────────────────────────────────────
              _PhotoArea(
                photoUrl: _photoUrl,
                isUploading: _isUploading,
                onTap: _pickAndUploadPhoto,
              ),
              const SizedBox(height: 24),

              // ── Vehicle Details ──────────────────────────────────────────
              _SectionLabel('Vehicle Details'),
              const SizedBox(height: 10),

              // Make + Model side by side
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _makeCtrl,
                      label: 'Make',
                      hint: 'Toyota',
                      required: true,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _modelCtrl,
                      label: 'Model',
                      hint: 'Hilux',
                      required: true,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Year + Type side by side
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _yearCtrl,
                      label: 'Year',
                      hint: '2020',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final yr = int.tryParse(v.trim());
                        if (yr == null || yr < 1886 || yr > 2100) {
                          return 'Invalid year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BottomSheetPickerField<String>(
                      label: 'Type',
                      sheetTitle: 'Select vehicle type',
                      value: _vehicleType,
                      options: _vehicleTypes,
                      labelBuilder: (type) =>
                          type[0].toUpperCase() + type.substring(1),
                      onChanged: (value) =>
                          setState(() => _vehicleType = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Current mileage full-width with unit suffix
              TextFormField(
                controller: _mileageCtrl,
                decoration: InputDecoration(
                  labelText: 'Current Mileage',
                  hintText: 'e.g. 48000',
                  border: const OutlineInputBorder(),
                  suffixText: odometerUnitLabel,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              // ── Registration & Fuel ──────────────────────────────────────
              _SectionLabel('Registration & Fuel'),
              const SizedBox(height: 10),

              TextFormField(
                controller: _regCtrl,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'e.g. ABC-1234',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: BottomSheetPickerField<String>(
                      label: 'Fuel Type',
                      sheetTitle: 'Select fuel type',
                      value: _fuelTypeDisplay,
                      options: _fuelTypeOptions,
                      labelBuilder: (type) => type == _kFuelTypeNone
                          ? 'Not specified'
                          : type[0].toUpperCase() + type.substring(1),
                      onChanged: _setFuelType,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BottomSheetPickerField<String>(
                      label: 'Distance Unit',
                      sheetTitle: 'Select distance unit',
                      value: distanceUnitDisplay,
                      options: _distanceUnitOptions,
                      labelBuilder: (unit) =>
                          unit == 'km' ? 'km' : 'mi',
                      onChanged: (value) =>
                          setState(() => _distanceUnit = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null
              : null),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo area
// ---------------------------------------------------------------------------

class _PhotoArea extends StatelessWidget {
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onTap;

  const _PhotoArea({
    this.photoUrl,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: CustomPaint(
        foregroundPainter: const DashedBorderPainter(
          color: Color(0xFFA06800),
          radius: 16,
          strokeWidth: 1.5,
        ),
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.photoUploadTint,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: isUploading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Uploading...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : photoUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Change photo',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add vehicle photo',
                      style: TextStyle(
                        color: Color(0xFFA06800),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
