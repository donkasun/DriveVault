import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/distance_unit.dart';
import '../../../shared/widgets/bottom_sheet_picker_field.dart';
import '../../../shared/widgets/form_screen_app_bar.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/data/vehicle_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_log.dart';

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

  /// Whether single-vehicle auto-select has been attempted.
  bool _autoSelectAttempted = false;

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
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _isFullTank = e?.isFullTank ?? true;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _litersCtrl.dispose();
    _unitPriceCtrl.dispose();
    _odometerCtrl.dispose();
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

  /// Apply add-mode defaults once per selected vehicle: latest unit price and
  /// latest odometer reading (shown as a placeholder, not prefilled).
  void _applyAddDefaults(Vehicle? vehicle, List<FuelLog>? logs) {
    if (_isEdit || vehicle == null || logs == null) return;
    if (_addDefaultsAppliedFor == vehicle.id) return;
    _addDefaultsAppliedFor = vehicle.id;

    final latestLog = logs.isNotEmpty ? logs.first : null;
    if (latestLog != null &&
        _unitPriceCtrl.text.trim().isEmpty &&
        latestLog.liters > 0) {
      _unitPriceCtrl.text = (latestLog.priceCents / 100 / latestLog.liters)
          .toStringAsFixed(2);
    }

    final latestOdometerKm =
        latestLog?.odometer ?? vehicle.currentMileage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _latestOdometerKm = latestOdometerKm);
    });
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fuel Log'),
        content: const Text('Delete this fuel log? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(fuelRepositoryProvider);
      await repo.deleteFuelLog(widget.existing!.id);

      final vehicleIdForDelete = widget.existing!.vehicleId;
      ref.invalidate(fuelLogsProvider(vehicleIdForDelete));
      ref.invalidate(fuelStatsProvider(vehicleIdForDelete));
      ref.invalidate(vehicleProvider(vehicleIdForDelete));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fuel log deleted')));
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Delete failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
        'notes': notes,
      };

      final vehicleIdForSave = _selectedVehicleId!;
      final repo = ref.read(fuelRepositoryProvider);
      if (_isEdit) {
        await repo.updateFuelLog(widget.existing!.id, data);
      } else {
        await repo.createFuelLog(vehicleIdForSave, data);
      }

      ref.invalidate(fuelLogsProvider(vehicleIdForSave));
      ref.invalidate(fuelStatsProvider(vehicleIdForSave));
      ref.invalidate(vehicleProvider(vehicleIdForSave));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : 'An unexpected error occurred';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
      appBar: FormScreenAppBar(
        title: _isEdit ? 'Edit Fuel Log' : 'Add Fuel Log',
        saving: _saving,
        onSave: () => _save(_effectiveUnit),
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
    // Task 2: auto-select when exactly one vehicle and none pre-selected.
    if (!_isEdit && !_autoSelectAttempted && _selectedVehicleId == null) {
      _autoSelectAttempted = true;
      if (vehicles.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedVehicleId = vehicles.first.id;
            });
          }
        });
      }
    }

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

    final odometerHintKm = _latestOdometerKm ?? selected?.currentMileage;
    final odometerHint = odometerHintKm != null
        ? kmToDisplay(odometerHintKm, unit).round().toString()
        : null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle picker — editable when adding, locked when editing a log.
          _buildVehiclePicker(vehicles),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _litersCtrl,
                    label: 'Liters *',
                    hint: '45.5',
                    isDecimal: true,
                  ),
                ),
                const SizedBox(width: 12),
                _buildFullTankField(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _unitPriceCtrl,
            label: 'Price per liter *',
            hint: '1.71',
            isDecimal: true,
          ),
          const SizedBox(height: 16),
          _buildOdometerField(unit: unit, hint: odometerHint),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          if (_isEdit) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Delete Fuel Log',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Task 3: Vehicle picker bottom sheet with dividers + rounded corners.
  Widget _buildVehiclePicker(List<Vehicle> vehicles) {
    return GestureDetector(
      onTap: _isEdit
          ? null
          : () => _showVehiclePicker(vehicles),
      child: AbsorbPointer(
        absorbing: _isEdit,
        child: BottomSheetPickerField<String>(
          label: 'Vehicle *',
          sheetTitle: 'Select vehicle',
          value: _selectedVehicleId,
          options: vehicles.map((v) => v.id).toList(),
          labelBuilder: (id) =>
              vehicles.firstWhere((v) => v.id == id).displayName,
          enabled: !_isEdit,
          onChanged: (value) => setState(() {
            _selectedVehicleId = value;
            _latestOdometerKm = null;
            _addDefaultsAppliedFor = null;
            _odometerCtrl.clear();
          }),
          validator: (v) => v == null ? 'Select a vehicle' : null,
        ),
      ),
    );
  }

  /// Shows a polished vehicle picker bottom sheet with rounded corners and
  /// dividers between rows (Task 3).
  Future<void> _showVehiclePicker(List<Vehicle> vehicles) async {
    if (_isEdit) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select Vehicle',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (ctx, i) {
                  final v = vehicles[i];
                  return ListTile(
                    title: Text(v.displayName),
                    trailing: _selectedVehicleId == v.id
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(v.id),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != _selectedVehicleId) {
      setState(() {
        _selectedVehicleId = picked;
        _latestOdometerKm = null;
        _addDefaultsAppliedFor = null;
        _odometerCtrl.clear();
      });
    }
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

  Widget _buildFullTankField() {
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final labelStyle =
        inputTheme.labelStyle ?? Theme.of(context).textTheme.bodyLarge;
    final enabledBorder = inputTheme.enabledBorder;
    final borderRadius = enabledBorder is OutlineInputBorder
        ? enabledBorder.borderRadius
        : BorderRadius.circular(12);

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 0, 2, 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inputTheme.fillColor ?? AppColors.surface,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Full Tank', style: labelStyle),
            Switch(
              value: _isFullTank,
              onChanged: (v) => setState(() => _isFullTank = v),
              trackOutlineColor: const WidgetStatePropertyAll(Colors.black87),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOdometerField({
    required DistanceUnit unit,
    String? hint,
  }) {
    return TextFormField(
      controller: _odometerCtrl,
      decoration: InputDecoration(
        labelText: 'Odometer (${unit.label}) *',
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (int.tryParse(v) == null) return 'Invalid integer';
        return null;
      },
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
          final parsed = double.tryParse(v);
          if (parsed == null) return 'Invalid number';
          // Liters field: reject zero / negative values.
          if (label.startsWith('Liters') && parsed <= 0) {
            return 'Enter a value greater than 0';
          }
        } else {
          if (int.tryParse(v) == null) return 'Invalid integer';
        }
        return null;
      },
    );
  }
}
