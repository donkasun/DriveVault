import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../shared/utils/distance_unit.dart';
import '../../../shared/widgets/bottom_sheet_picker_field.dart';
import '../../../shared/widgets/form_screen_app_bar.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import '../../expenses/data/expenses_provider.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/data/vehicle_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_record.dart';

class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final MaintenanceRecord? existing;

  const MaintenanceFormScreen({
    super.key,
    required this.vehicleId,
    this.existing,
  });

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateCtrl;
  late final TextEditingController _serviceTypeCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _workshopCtrl;
  late final TextEditingController _notesCtrl;
  String? _category;
  bool _saving = false;

  static const _categories = ['maintenance', 'repair', 'inspection', 'other'];

  static const _serviceTypeSuggestions = [
    'Oil Change',
    'Tyre Rotation',
    'Brake Service',
    'Air Filter',
    'Battery',
    'Coolant',
    'Inspection',
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dateCtrl = TextEditingController(text: e?.date ?? _today());
    _serviceTypeCtrl = TextEditingController(text: e?.serviceType ?? '');
    _odometerCtrl = TextEditingController(
      text: e?.odometer != null ? e!.odometer.toString() : '',
    );
    _costCtrl = TextEditingController(
      text: e?.costCents != null
          ? (e!.costCents! / 100).toStringAsFixed(2)
          : '',
    );
    _workshopCtrl = TextEditingController(text: e?.workshop ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _category = e?.category;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _serviceTypeCtrl.dispose();
    _odometerCtrl.dispose();
    _costCtrl.dispose();
    _workshopCtrl.dispose();
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service Record'),
        content: const Text(
          'Delete this service record? This cannot be undone.',
        ),
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
      final repo = ref.read(maintenanceRepositoryProvider);
      await repo.deleteRecord(widget.existing!.id);

      ref.invalidate(maintenanceRecordsProvider(widget.vehicleId));
      ref.invalidate(vehicleProvider(widget.vehicleId));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(allExpensesProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service record deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Delete failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final costText = _costCtrl.text.trim();
      final odomText = _odometerCtrl.text.trim();

      // currency intentionally omitted — the backend fills it from the user's
      // currency preference (matches fuel-log form behaviour).
      final data = <String, dynamic>{
        'date': _dateCtrl.text.trim(),
        'serviceType': _serviceTypeCtrl.text.trim(),
        if (odomText.isNotEmpty) 'odometer': int.parse(odomText),
        if (_category != null) 'category': _category,
        if (costText.isNotEmpty)
          'costCents': (double.parse(costText) * 100).round(),
        if (_workshopCtrl.text.trim().isNotEmpty)
          'workshop': _workshopCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };

      final repo = ref.read(maintenanceRepositoryProvider);
      if (_isEdit) {
        await repo.updateRecord(widget.existing!.id, data);
      } else {
        await repo.createRecord(widget.vehicleId, data);
      }

      ref.invalidate(maintenanceRecordsProvider(widget.vehicleId));
      ref.invalidate(vehicleProvider(widget.vehicleId));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(allExpensesProvider);

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

    // Resolve the effective distance unit for this vehicle.
    final vehicle = vehiclesAsync.asData?.value
        .cast<Vehicle?>()
        .firstWhere((v) => v?.id == widget.vehicleId, orElse: () => null);
    final userUnit = meAsync.asData?.value.distanceUnit ?? 'km';
    final unit = effectiveUnit(
      vehicleUnit: vehicle?.distanceUnit,
      userUnit: userUnit,
    );

    return Scaffold(
      appBar: FormScreenAppBar(
        title: _isEdit ? 'Edit Service Record' : 'Add Service Record',
        saving: _saving,
        onSave: _save,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Date *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            // Service type
            TextFormField(
              controller: _serviceTypeCtrl,
              decoration: const InputDecoration(
                labelText: 'Service Type *',
                hintText: 'e.g. Oil Change',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            // Suggestion chips — tapping fills the field (still editable).
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _serviceTypeSuggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () {
                    setState(() => _serviceTypeCtrl.text = suggestion);
                  },
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Odometer — label uses effective distance unit
            TextFormField(
              controller: _odometerCtrl,
              decoration: InputDecoration(
                labelText: 'Odometer (${unit.label})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                  return 'Invalid integer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Category picker
            BottomSheetPickerField<String>(
              label: 'Category',
              sheetTitle: 'Select category',
              value: _category,
              options: _categories,
              labelBuilder: (c) => c[0].toUpperCase() + c.substring(1),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            // Cost
            TextFormField(
              controller: _costCtrl,
              decoration: const InputDecoration(
                labelText: 'Cost',
                hintText: '65.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Workshop
            TextFormField(
              controller: _workshopCtrl,
              decoration: const InputDecoration(
                labelText: 'Workshop',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
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
                  'Delete Service Record',
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
      ),
    );
  }
}
