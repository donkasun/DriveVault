import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/distance_unit.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_log.dart';

/// Common fuel variant presets offered as quick-fill chips. The variant is
/// free text, so users can also type their own.
const _variantPresets = [
  '92 Octane',
  '95 Octane',
  '98 Octane',
  'Diesel',
  'Super Diesel',
];

class FuelLogFormScreen extends ConsumerStatefulWidget {
  /// Pre-selected vehicle (e.g. opened from a vehicle's detail). When null the
  /// user picks a vehicle from the dropdown (e.g. opened from a home shortcut).
  final String? vehicleId;
  final FuelLog? existing;

  const FuelLogFormScreen({super.key, this.vehicleId, this.existing});

  @override
  ConsumerState<FuelLogFormScreen> createState() => _FuelLogFormScreenState();
}

class _FuelLogFormScreenState extends ConsumerState<FuelLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateCtrl;
  late final TextEditingController _litersCtrl;
  late final TextEditingController _unitPriceCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _variantCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isFullTank;
  bool _saving = false;

  String? _selectedVehicleId;

  /// Latest odometer (km) for the selected vehicle, shown as a placeholder.
  int? _latestOdometerKm;

  /// The effective distance unit for the currently-selected vehicle/user combo.
  /// Set each time _buildForm runs so the AppBar Save button can access it.
  DistanceUnit _effectiveUnit = DistanceUnit.km;

  bool _editInitialised = false;
  String? _addDefaultsAppliedFor;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedVehicleId = widget.vehicleId ?? e?.vehicleId;
    _dateCtrl = TextEditingController(text: e?.date ?? _today());
    _litersCtrl = TextEditingController(
      text: e != null ? e.liters.toString() : '',
    );
    _unitPriceCtrl = TextEditingController();
    _odometerCtrl = TextEditingController();
    _variantCtrl = TextEditingController(text: e?.fuelVariant ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _isFullTank = e?.isFullTank ?? true;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _litersCtrl.dispose();
    _unitPriceCtrl.dispose();
    _odometerCtrl.dispose();
    _variantCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}'
          '-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  /// One-time control population for edit mode (needs the effective unit, which
  /// is only known after the user/vehicle data loads).
  void _initEditControls(DistanceUnit unit) {
    if (!_isEdit || _editInitialised) return;
    final e = widget.existing!;
    final unitPrice = e.liters > 0 ? e.priceCents / 100 / e.liters : 0;
    _unitPriceCtrl.text = unitPrice.toStringAsFixed(2);
    _odometerCtrl.text = kmToDisplay(e.odometer, unit).round().toString();
    _editInitialised = true;
  }

  /// Apply add-mode defaults once per selected vehicle: default fuel variant,
  /// latest unit price, and latest odometer (placeholder).
  void _applyAddDefaults(Vehicle? vehicle, List<FuelLog>? logs) {
    if (_isEdit || vehicle == null || logs == null) return;
    if (_addDefaultsAppliedFor == vehicle.id) return;
    _addDefaultsAppliedFor = vehicle.id;

    if (_variantCtrl.text.trim().isEmpty &&
        vehicle.defaultFuelVariant != null) {
      _variantCtrl.text = vehicle.defaultFuelVariant!;
    }
    final latest = logs.isNotEmpty ? logs.first : null;
    if (latest != null) {
      if (_unitPriceCtrl.text.trim().isEmpty && latest.liters > 0) {
        _unitPriceCtrl.text = (latest.priceCents / 100 / latest.liters)
            .toStringAsFixed(2);
      }
      // Trigger a rebuild so the odometer placeholder picks up the latest value.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _latestOdometerKm = latest.odometer);
      });
    }
  }

  Future<void> _save(DistanceUnit unit) async {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final liters = double.parse(_litersCtrl.text.trim());
      final unitPrice = double.parse(_unitPriceCtrl.text.trim());
      final priceCents = (unitPrice * liters * 100).round();
      final odometerKm = displayToKm(
        double.parse(_odometerCtrl.text.trim()),
        unit,
      );
      final variant = _variantCtrl.text.trim();
      final notes = _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim();

      // currency intentionally omitted — the backend fills it from the user's
      // currency preference (Doc 3).
      final data = <String, dynamic>{
        'date': _dateCtrl.text.trim(),
        'liters': liters,
        'priceCents': priceCents,
        'odometer': odometerKm,
        'isFullTank': _isFullTank,
        'fuelVariant': variant.isEmpty ? null : variant,
        'notes': notes,
      };

      final repo = ref.read(fuelRepositoryProvider);
      if (_isEdit) {
        await repo.updateFuelLog(widget.existing!.id, data);
      } else {
        await repo.createFuelLog(_selectedVehicleId!, data);
      }

      ref.invalidate(fuelLogsProvider(_selectedVehicleId!));
      ref.invalidate(fuelStatsProvider(_selectedVehicleId!));

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final meAsync = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Fuel Log' : 'Add Fuel Log'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 72,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: () => _save(_effectiveUnit),
                    child: const Text('Save'),
                  ),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load vehicles: $e')),
        data: (vehicles) => meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load profile: $e')),
          data: (user) => _buildForm(vehicles, user.distanceUnit),
        ),
      ),
    );
  }

  Widget _buildForm(List<Vehicle> vehicles, String userUnit) {
    Vehicle? selected;
    for (final v in vehicles) {
      if (v.id == _selectedVehicleId) selected = v;
    }
    final unit = effectiveUnit(
      vehicleUnit: selected?.distanceUnit,
      userUnit: userUnit,
    );
    // Keep _effectiveUnit in sync so the AppBar Save button can call _save.
    if (_effectiveUnit != unit) {
      // Use a post-frame callback to avoid setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _effectiveUnit = unit);
      });
    }
    _initEditControls(unit);

    // Watch the selected vehicle's logs to derive add-mode prefills.
    if (_selectedVehicleId != null) {
      final logsAsync = ref.watch(fuelLogsProvider(_selectedVehicleId!));
      _applyAddDefaults(selected, logsAsync.asData?.value);
    }

    final odometerHint = _latestOdometerKm != null
        ? kmToDisplay(_latestOdometerKm!, unit).round().toString()
        : '48200';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle picker — editable when adding, locked when editing a log.
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicleId,
            decoration: const InputDecoration(
              labelText: 'Vehicle *',
              border: OutlineInputBorder(),
            ),
            items: vehicles
                .map(
                  (v) =>
                      DropdownMenuItem(value: v.id, child: Text(v.displayName)),
                )
                .toList(),
            onChanged: _isEdit
                ? null
                : (value) => setState(() {
                    _selectedVehicleId = value;
                    _latestOdometerKm = null;
                    _addDefaultsAppliedFor = null;
                  }),
            validator: (v) => v == null ? 'Select a vehicle' : null,
          ),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _litersCtrl,
            label: 'Liters *',
            hint: '45.5',
            isDecimal: true,
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _unitPriceCtrl,
            label: 'Price per liter *',
            hint: '1.71',
            isDecimal: true,
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _odometerCtrl,
            label: 'Odometer (${unit.label}) *',
            hint: odometerHint,
            isDecimal: false,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _variantCtrl,
            decoration: const InputDecoration(
              labelText: 'Fuel variant',
              hintText: 'e.g. 95 Octane',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _variantPresets
                .map(
                  (p) => ActionChip(
                    label: Text(p),
                    onPressed: () => setState(() => _variantCtrl.text = p),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Full Tank'),
            value: _isFullTank,
            onChanged: (v) => setState(() => _isFullTank = v),
            trackOutlineColor: WidgetStatePropertyAll(Colors.black87),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : () => _save(unit),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateCtrl,
      readOnly: true,
      onTap: _pickDate,
      decoration: const InputDecoration(
        labelText: 'Date *',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDecimal,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isDecimal) {
          if (double.tryParse(v) == null) return 'Invalid number';
        } else {
          if (int.tryParse(v) == null) return 'Invalid integer';
        }
        return null;
      },
    );
  }
}
