import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../dashboard/presentation/dashboard_provider.dart';
import '../../../expenses/data/expenses_provider.dart';
import '../../../profile/data/user_repository.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicles_provider.dart';
import '../../data/maintenance_repository.dart';
import '../../domain/service_type_suggestions.dart';
import '../maintenance_form_screen.dart';

/// Opens the lightweight quick maintenance-entry sheet. [vehicleId] preselects
/// a vehicle (omit to let the user pick when they own more than one).
Future<void> showQuickMaintenanceSheet(
  BuildContext context, {
  String? vehicleId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true, // cover the floating tab bar
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: QuickMaintenanceSheet(vehicleId: vehicleId),
    ),
  );
}

class QuickMaintenanceSheet extends ConsumerStatefulWidget {
  final String? vehicleId;
  const QuickMaintenanceSheet({super.key, this.vehicleId});

  @override
  ConsumerState<QuickMaintenanceSheet> createState() =>
      _QuickMaintenanceSheetState();
}

class _QuickMaintenanceSheetState extends ConsumerState<QuickMaintenanceSheet> {
  final _serviceTypeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();

  String? _selectedVehicleId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
  }

  @override
  void dispose() {
    _serviceTypeCtrl.dispose();
    _costCtrl.dispose();
    _odometerCtrl.dispose();
    super.dispose();
  }

  String get _dateText =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}'
      '-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(DistanceUnit unit) async {
    if (_selectedVehicleId == null) {
      setState(() => _error = 'Please select a vehicle');
      return;
    }
    final serviceType = _serviceTypeCtrl.text.trim();
    if (serviceType.isEmpty) {
      setState(() => _error = 'Enter a service type');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final costText = _costCtrl.text.trim();
      final odoText = _odometerCtrl.text.trim();
      // currency intentionally omitted — backend forces LKR.
      final data = <String, dynamic>{
        'date': _dateText,
        'serviceType': serviceType,
        if (costText.isNotEmpty)
          'costCents': (double.parse(costText) * 100).round(),
        if (odoText.isNotEmpty)
          'odometer': displayToKm(double.parse(odoText), unit),
      };
      await ref
          .read(maintenanceRecordsProvider(_selectedVehicleId!).notifier)
          .createOptimistic(_selectedVehicleId!, data);

      ref.invalidate(vehicleProvider(_selectedVehicleId!));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(allExpensesProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'Could not save';
          _saving = false;
        });
      }
    }
  }

  void _openFullDetails() {
    if (_selectedVehicleId == null) {
      setState(() => _error = 'Please select a vehicle');
      return;
    }
    final id = _selectedVehicleId!;
    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MaintenanceFormScreen(
          vehicleId: id,
          initialServiceType: _serviceTypeCtrl.text.trim().isEmpty
              ? null
              : _serviceTypeCtrl.text.trim(),
          initialCost:
              _costCtrl.text.trim().isEmpty ? null : _costCtrl.text.trim(),
          initialOdometer: _odometerCtrl.text.trim().isEmpty
              ? null
              : _odometerCtrl.text.trim(),
          initialDate: _dateText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final meAsync = ref.watch(meProvider);
    return vehiclesAsync.when(
      loading: () =>
          const _SheetBox(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _SheetBox(child: Text('Failed to load vehicles: $e')),
      data: (vehicles) => meAsync.when(
        loading: () =>
            const _SheetBox(child: Center(child: CircularProgressIndicator())),
        error: (e, _) => _SheetBox(child: Text('Failed to load profile: $e')),
        data: (user) => _buildSheet(vehicles, user.distanceUnit),
      ),
    );
  }

  Widget _buildSheet(List<Vehicle> vehicles, String userUnit) {
    _selectedVehicleId ??= vehicles.length == 1 ? vehicles.first.id : null;
    Vehicle? selected;
    for (final v in vehicles) {
      if (v.id == _selectedVehicleId) selected = v;
    }
    final unit = effectiveUnit(
      vehicleUnit: selected?.distanceUnit,
      userUnit: userUnit,
    );
    final odoHint = selected?.currentMileage != null
        ? kmToDisplay(selected!.currentMileage!, unit).round().toString()
        : null;

    return _SheetBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log service',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (widget.vehicleId == null && vehicles.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicleId,
              decoration: const InputDecoration(
                labelText: 'Vehicle',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final v in vehicles)
                  DropdownMenuItem(value: v.id, child: Text(v.displayName)),
              ],
              onChanged: (id) => setState(() => _selectedVehicleId = id),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            children: [
              for (final s in kServiceTypeSuggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() => _serviceTypeCtrl.text = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serviceTypeCtrl,
            decoration: const InputDecoration(
              labelText: 'Service type *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('qm-cost'),
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cost',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('qm-odometer'),
            controller: _odometerCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Odometer (${unit.label})',
              hintText: odoHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dateText),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : () => _save(unit),
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          TextButton(
            onPressed: _saving ? null : _openFullDetails,
            child: const Text('Full details'),
          ),
        ],
      ),
    );
  }
}

class _SheetBox extends StatelessWidget {
  final Widget child;
  const _SheetBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: child,
      ),
    );
  }
}
