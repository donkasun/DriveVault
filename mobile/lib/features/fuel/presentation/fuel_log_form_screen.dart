import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fuel_repository.dart';
import '../domain/fuel_log.dart';

class FuelLogFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final FuelLog? existing;

  const FuelLogFormScreen({
    super.key,
    required this.vehicleId,
    this.existing,
  });

  @override
  ConsumerState<FuelLogFormScreen> createState() =>
      _FuelLogFormScreenState();
}

class _FuelLogFormScreenState extends ConsumerState<FuelLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateCtrl;
  late final TextEditingController _litersCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isFullTank;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dateCtrl = TextEditingController(
        text: e?.date ?? _today());
    _litersCtrl = TextEditingController(
        text: e != null ? e.liters.toString() : '');
    // Display as decimal (cents / 100)
    _priceCtrl = TextEditingController(
        text: e != null ? (e.priceCents / 100).toStringAsFixed(2) : '');
    _odometerCtrl = TextEditingController(
        text: e != null ? e.odometer.toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _isFullTank = e?.isFullTank ?? true;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _litersCtrl.dispose();
    _priceCtrl.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final liters = double.parse(_litersCtrl.text.trim());
      final priceCents =
          (double.parse(_priceCtrl.text.trim()) * 100).round();
      final odometer = int.parse(_odometerCtrl.text.trim());
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      final data = {
        'date': _dateCtrl.text.trim(),
        'liters': liters,
        'priceCents': priceCents,
        'currency': 'USD',
        'odometer': odometer,
        'isFullTank': _isFullTank,
        'notes': notes,
      };

      final repo = ref.read(fuelRepositoryProvider);
      if (widget.existing != null) {
        await repo.updateFuelLog(widget.existing!.id, data);
      } else {
        await repo.createFuelLog(widget.vehicleId, data);
      }

      ref.invalidate(fuelLogsProvider(widget.vehicleId));
      ref.invalidate(fuelStatsProvider(widget.vehicleId));

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
        title: Text(isEdit ? 'Edit Fuel Log' : 'Add Fuel Log'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 72,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
              controller: _priceCtrl,
              label: 'Total Price *',
              hint: '78.00',
              isDecimal: true,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _odometerCtrl,
              label: 'Odometer (km) *',
              hint: '48200',
              isDecimal: false,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Full Tank'),
              value: _isFullTank,
              onChanged: (v) => setState(() => _isFullTank = v),
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
          ],
        ),
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
      keyboardType:
          TextInputType.numberWithOptions(decimal: isDecimal),
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
