import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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

class _MaintenanceFormScreenState
    extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateCtrl;
  late final TextEditingController _serviceTypeCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _workshopCtrl;
  late final TextEditingController _notesCtrl;
  String? _category;
  bool _saving = false;

  static const _categories = [
    'maintenance',
    'repair',
    'inspection',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dateCtrl = TextEditingController(
        text: e?.date ?? _today());
    _serviceTypeCtrl =
        TextEditingController(text: e?.serviceType ?? '');
    _odometerCtrl = TextEditingController(
        text: e?.odometer != null ? e!.odometer.toString() : '');
    _costCtrl = TextEditingController(
        text: e?.costCents != null
            ? (e!.costCents! / 100).toStringAsFixed(2)
            : '');
    _currencyCtrl =
        TextEditingController(text: e?.currency ?? 'USD');
    _workshopCtrl =
        TextEditingController(text: e?.workshop ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _category = e?.category;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _serviceTypeCtrl.dispose();
    _odometerCtrl.dispose();
    _costCtrl.dispose();
    _currencyCtrl.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final costText = _costCtrl.text.trim();
      final odomText = _odometerCtrl.text.trim();

      final data = <String, dynamic>{
        'date': _dateCtrl.text.trim(),
        'serviceType': _serviceTypeCtrl.text.trim(),
        if (odomText.isNotEmpty) 'odometer': int.parse(odomText),
        if (_category != null) 'category': _category,
        if (costText.isNotEmpty)
          'costCents': (double.parse(costText) * 100).round(),
        'currency': _currencyCtrl.text.trim().isEmpty
            ? 'USD'
            : _currencyCtrl.text.trim(),
        if (_workshopCtrl.text.trim().isNotEmpty)
          'workshop': _workshopCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty)
          'notes': _notesCtrl.text.trim(),
      };

      final repo = ref.read(maintenanceRepositoryProvider);
      if (widget.existing != null) {
        await repo.updateRecord(widget.existing!.id, data);
      } else {
        await repo.createRecord(widget.vehicleId, data);
      }

      ref.invalidate(maintenanceRecordsProvider(widget.vehicleId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 80,
        title: Text(isEdit ? 'Edit Service Record' : 'Add Service Record'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          child: const Text('Cancel', maxLines: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
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
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
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
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            // Odometer
            TextFormField(
              controller: _odometerCtrl,
              decoration: const InputDecoration(
                labelText: 'Odometer (km)',
                border: OutlineInputBorder(),
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
            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v != null &&
                    v.isNotEmpty &&
                    double.tryParse(v) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Currency
            TextFormField(
              controller: _currencyCtrl,
              decoration: const InputDecoration(
                labelText: 'Currency',
                hintText: 'USD',
                border: OutlineInputBorder(),
              ),
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
          ],
        ),
      ),
    );
  }
}
