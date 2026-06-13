import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../dashboard/presentation/dashboard_provider.dart';
import '../../../profile/data/user_repository.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicles_provider.dart';
import '../../data/fuel_repository.dart';
import '../../domain/fuel_entry_calc.dart';
import '../fuel_log_form_screen.dart';

/// Opens the lightweight quick fuel-entry sheet. [vehicleId] preselects a
/// vehicle (omit to let the user pick when they own more than one).
Future<void> showQuickFuelEntrySheet(
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
      child: QuickFuelEntrySheet(vehicleId: vehicleId),
    ),
  );
}

class QuickFuelEntrySheet extends ConsumerStatefulWidget {
  final String? vehicleId;
  const QuickFuelEntrySheet({super.key, this.vehicleId});

  @override
  ConsumerState<QuickFuelEntrySheet> createState() =>
      _QuickFuelEntrySheetState();
}

class _QuickFuelEntrySheetState extends ConsumerState<QuickFuelEntrySheet> {
  final _odometerCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _perLiterCtrl = TextEditingController();

  FuelEntryCalc _calc = FuelEntryCalc();
  String? _selectedVehicleId;
  DateTime _date = DateTime.now();
  int? _latestOdometerKm;
  bool _saving = false;
  String? _error;
  bool _calcSeeded = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
  }

  @override
  void dispose() {
    _odometerCtrl.dispose();
    _litersCtrl.dispose();
    _totalCtrl.dispose();
    _perLiterCtrl.dispose();
    super.dispose();
  }

  String get _dateText =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}'
      '-${_date.day.toString().padLeft(2, '0')}';

  /// Seed the sticky per-liter default and odometer hint from the latest log.
  void _seedFromLatest(List<dynamic> logs, Vehicle? vehicle) {
    if (_calcSeeded) return;
    _calcSeeded = true;
    final latest = logs.isNotEmpty ? logs.first : null;
    double? perLiter;
    if (latest != null && latest.liters > 0) {
      perLiter = latest.priceCents / 100 / latest.liters;
      _perLiterCtrl.text = perLiter!.toStringAsFixed(2);
    }
    _calc = FuelEntryCalc(initialPerLiter: perLiter);
    _latestOdometerKm = latest?.odometer ?? vehicle?.currentMileage;
  }

  void _onFieldChanged(FuelField field, String raw) {
    _calc.setField(field, double.tryParse(raw.trim()));
    // Reflect derived values back into the other controllers (not the one being
    // edited, to preserve the cursor).
    if (field != FuelField.liters && _calc.liters != null) {
      _litersCtrl.text = _calc.liters!.toStringAsFixed(2);
    }
    if (field != FuelField.total && _calc.total != null) {
      _totalCtrl.text = _calc.total!.toStringAsFixed(2);
    }
    if (field != FuelField.perLiter && _calc.pricePerLiter != null) {
      _perLiterCtrl.text = _calc.pricePerLiter!.toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _save(DistanceUnit unit) async {
    final odo = int.tryParse(_odometerCtrl.text.trim());
    if (_selectedVehicleId == null) {
      setState(() => _error = 'Please select a vehicle');
      return;
    }
    if (odo == null) {
      setState(() => _error = 'Enter a valid odometer reading');
      return;
    }
    if (!_calc.isComplete) {
      setState(() => _error = 'Enter at least two of liters / total / price');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final liters = _calc.liters!;
      final priceCents = (_calc.total! * 100).round();
      final odometerKm = displayToKm(odo.toDouble(), unit);
      final data = <String, dynamic>{
        'date': _dateText,
        'liters': liters,
        'priceCents': priceCents,
        'odometer': odometerKm,
        'isFullTank': true,
        'notes': null,
      };
      await ref
          .read(fuelRepositoryProvider)
          .createFuelLog(_selectedVehicleId!, data);

      ref.invalidate(fuelLogsProvider(_selectedVehicleId!));
      ref.invalidate(fuelStatsProvider(_selectedVehicleId!));
      ref.invalidate(vehicleProvider(_selectedVehicleId!));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);

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

  void _openFullDetails(DistanceUnit unit) {
    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FuelLogFormScreen(
          vehicleId: _selectedVehicleId,
          initialOdometer: _odometerCtrl.text.trim().isEmpty
              ? null
              : _odometerCtrl.text.trim(),
          initialLiters: _calc.liters?.toStringAsFixed(2),
          initialUnitPrice: _calc.pricePerLiter?.toStringAsFixed(2),
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
    // Auto-select when exactly one vehicle and none preselected.
    _selectedVehicleId ??= vehicles.length == 1 ? vehicles.first.id : null;
    Vehicle? selected;
    for (final v in vehicles) {
      if (v.id == _selectedVehicleId) selected = v;
    }
    final unit = effectiveUnit(
      vehicleUnit: selected?.distanceUnit,
      userUnit: userUnit,
    );
    if (_selectedVehicleId != null) {
      final logsAsync = ref.watch(fuelLogsProvider(_selectedVehicleId!));
      // Only seed once we have actual data (not while still loading).
      if (logsAsync.hasValue) {
        _seedFromLatest(logsAsync.value!, selected);
      }
    }
    final odoHintKm = _latestOdometerKm ?? selected?.currentMileage;
    final odoHint = odoHintKm != null
        ? kmToDisplay(odoHintKm, unit).round().toString()
        : null;

    return _SheetBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log fuel',
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
              onChanged: (id) => setState(() {
                _selectedVehicleId = id;
                _calcSeeded = false;
              }),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _odometerCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Odometer (${unit.label})',
              hintText: odoHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _onFieldChanged(FuelField.total, v),
            decoration: const InputDecoration(
              labelText: 'Total paid',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _litersCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => _onFieldChanged(FuelField.liters, v),
                  decoration: const InputDecoration(
                    labelText: 'Liters',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _perLiterCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => _onFieldChanged(FuelField.perLiter, v),
                  decoration: const InputDecoration(
                    labelText: 'Price/L',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
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
            onPressed: _saving ? null : () => _openFullDetails(unit),
            child: const Text('Full details'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
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
