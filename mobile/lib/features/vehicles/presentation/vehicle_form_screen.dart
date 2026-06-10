import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../data/upload_repository.dart';
import '../domain/vehicle.dart';
import 'vehicles_provider.dart';

/// Possible vehicle types matching the backend enum.
const _vehicleTypes = [
  'car',
  'pickup',
  'van',
  'truck',
  'motorcycle',
  'other',
];

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
  late final TextEditingController _vinCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _mileageCtrl;

  String? _vehicleType;
  String? _photoUrl;
  String? _photoPublicId;
  bool _isUploading = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.vehicle != null;

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
    _vinCtrl = TextEditingController(text: v?.vin ?? '');
    _priceCtrl = TextEditingController(
      text: v?.purchasePriceCents != null
          ? (v!.purchasePriceCents! / 100).toStringAsFixed(2)
          : '',
    );
    _currencyCtrl = TextEditingController(text: v?.currency ?? 'USD');
    _mileageCtrl = TextEditingController(
      text: v?.currentMileage != null ? v!.currentMileage.toString() : '',
    );
    _vehicleType = v?.vehicleType;
    _photoUrl = v?.photoUrl;
    _photoPublicId = v?.photoPublicId;
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _regCtrl.dispose();
    _vinCtrl.dispose();
    _priceCtrl.dispose();
    _currencyCtrl.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final priceText = _priceCtrl.text.trim();
    int? priceCents;
    if (priceText.isNotEmpty) {
      final amount = double.tryParse(priceText);
      if (amount != null) priceCents = (amount * 100).round();
    }

    final data = <String, dynamic>{
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
    };
    final year = int.tryParse(_yearCtrl.text.trim());
    if (year != null) data['year'] = year;
    final reg = _regCtrl.text.trim();
    if (reg.isNotEmpty) data['registrationNumber'] = reg;
    final vin = _vinCtrl.text.trim();
    if (vin.isNotEmpty) data['vin'] = vin;
    if (priceCents != null) data['purchasePriceCents'] = priceCents;
    final currency = _currencyCtrl.text.trim();
    if (currency.isNotEmpty) data['currency'] = currency;
    final mileage = int.tryParse(_mileageCtrl.text.trim());
    if (mileage != null) data['currentMileage'] = mileage;
    if (_vehicleType != null) data['vehicleType'] = _vehicleType;
    if (_photoUrl != null) data['photoUrl'] = _photoUrl;
    if (_photoPublicId != null) data['photoPublicId'] = _photoPublicId;

    try {
      if (_isEditMode) {
        await ref
            .read(vehiclesProvider.notifier)
            .updateVehicle(widget.vehicle!.id, data);
      } else {
        await ref.read(vehiclesProvider.notifier).create(data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text(
          'Are you sure you want to delete this vehicle? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(vehiclesProvider.notifier)
            .deleteVehicle(widget.vehicle!.id);
        if (mounted) context.go('/garage');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Vehicle' : 'Add Vehicle'),
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete vehicle',
              onPressed: _confirmDelete,
            ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
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
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select type'),
                items: _vehicleTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type[0].toUpperCase() + type.substring(1),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _vehicleType = value),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _vinCtrl,
                decoration: const InputDecoration(
                  labelText: 'VIN',
                  hintText: 'Vehicle identification number',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),

              _SectionLabel('Purchase Info'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _currencyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 3,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionLabel('Odometer'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current Mileage (km)',
                  hintText: 'e.g. 48000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
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
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
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
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 40,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add vehicle photo',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
