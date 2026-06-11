import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bottom_sheet_picker_field.dart';
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

  bool get _isEditMode => widget.vehicle != null;

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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
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
    final mileage = int.tryParse(_mileageCtrl.text.trim());
    if (mileage != null) data['currentMileage'] = mileage;
    if (_vehicleType != null) data['vehicleType'] = _vehicleType;
    // Fuel & unit fields — sent explicitly (incl. null) so edits can clear them.
    // distanceUnit null = inherit the user's account-level default.
    data['fuelType'] = _fuelType;
    data['distanceUnit'] = _distanceUnit;
    if (_photoUrl != null) data['photoUrl'] = _photoUrl;
    if (_photoPublicId != null) data['photoPublicId'] = _photoPublicId;

    try {
      if (_isEditMode) {
        await ref
            .read(vehiclesProvider.notifier)
            .updateVehicle(widget.vehicle!.id, data);
        // Refresh the detail screen, which watches the single-vehicle provider.
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
    final userUnit =
        ref.watch(meProvider).asData?.value.distanceUnit ?? 'km';
    final distanceUnitDisplay =
        _distanceUnit ?? widget.vehicle?.distanceUnit ?? userUnit;
    final odometerUnitLabel = distanceUnitDisplay == 'mi' ? 'mi' : 'km';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 80,
        title: Text(_isEditMode ? 'Edit Vehicle' : 'Add Vehicle'),
        leading: TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          child: const Text('Cancel', maxLines: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo area
              _PhotoArea(
                photoUrl: _photoUrl,
                isUploading: _isUploading,
                onTap: _pickAndUploadPhoto,
              ),
              const SizedBox(height: 24),

              // Required fields
              _SectionLabel('Vehicle Details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _makeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Make *',
                  hintText: 'e.g. Toyota',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Make is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model *',
                  hintText: 'e.g. Hilux',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Model is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearCtrl,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: 'e.g. 2020',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final year = int.tryParse(value.trim());
                  if (year == null || year < 1886 || year > 2100) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              BottomSheetPickerField<String>(
                label: 'Vehicle Type',
                sheetTitle: 'Select vehicle type',
                value: _vehicleType,
                options: _vehicleTypes,
                labelBuilder: (type) =>
                    type[0].toUpperCase() + type.substring(1),
                onChanged: (value) => setState(() => _vehicleType = value),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Odometer'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageCtrl,
                decoration: InputDecoration(
                  labelText: 'Current Mileage ($odometerUnitLabel)',
                  hintText: 'e.g. 48000',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              _SectionLabel('Registration & Identity'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _regCtrl,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'e.g. ABC-1234',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),

              _SectionLabel('Fuel & Units'),
              const SizedBox(height: 12),
              BottomSheetPickerField<String>(
                label: 'Fuel Type',
                sheetTitle: 'Select fuel type',
                value: _fuelTypeDisplay,
                options: _fuelTypeOptions,
                labelBuilder: (type) => type == _kFuelTypeNone
                    ? 'Not specified'
                    : type[0].toUpperCase() + type.substring(1),
                onChanged: _setFuelType,
              ),
              const SizedBox(height: 12),
              BottomSheetPickerField<String>(
                label: 'Distance Unit',
                sheetTitle: 'Select distance unit',
                value: distanceUnitDisplay,
                options: _distanceUnitOptions,
                labelBuilder: (unit) =>
                    unit == 'km' ? 'Kilometres (km)' : 'Miles (mi)',
                onChanged: (value) => setState(() => _distanceUnit = value),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}

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
        foregroundPainter: _DashedBorderPainter(
          color: AppColors.textMuted,
          radius: 16,
          strokeWidth: 1.5,
        ),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
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
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(
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
                    SizedBox(
                      width: 48,
                      height: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 36,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            left: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add vehicle photo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 6.0;
      const gapLength = 4.0;
      while (distance < metric.length) {
        final end = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0.0, metric.length)),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
