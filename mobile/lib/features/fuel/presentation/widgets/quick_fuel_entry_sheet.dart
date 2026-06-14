import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../dashboard/presentation/dashboard_provider.dart';
import '../../../profile/data/user_repository.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicles_provider.dart';
import '../../data/fuel_repository.dart';
import '../../domain/fuel_entry_calc.dart';
import '../fuel_log_form_screen.dart';
import 'fuel_numeric_keypad.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Opens the v2 quick fuel-entry sheet as a bottom sheet that covers the
/// floating tab bar.  [vehicleId] pre-selects a vehicle; omit to let the user
/// pick when they own more than one vehicle.
Future<void> showQuickFuelEntrySheet(
  BuildContext context, {
  String? vehicleId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true, // cover the floating tab bar
    backgroundColor: Colors.transparent,
    builder: (_) => QuickFuelEntrySheet(vehicleId: vehicleId),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class QuickFuelEntrySheet extends ConsumerStatefulWidget {
  final String? vehicleId;
  const QuickFuelEntrySheet({super.key, this.vehicleId});

  @override
  ConsumerState<QuickFuelEntrySheet> createState() =>
      _QuickFuelEntrySheetState();
}

class _QuickFuelEntrySheetState extends ConsumerState<QuickFuelEntrySheet> {
  // Controllers for the three derive-able fields and odometer.
  final _odometerCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _perLiterCtrl = TextEditingController();

  // The focused field fed by the custom keypad.
  // Starts on odometer so the user can enter it first.
  FuelField? _focusedCalcField;
  // Non-null when odometer is focused (before picking a calc field).
  bool _odometerFocused = true;

  TextEditingController get _activeCtrl {
    if (_odometerFocused) return _odometerCtrl;
    return switch (_focusedCalcField) {
      FuelField.liters => _litersCtrl,
      FuelField.total => _totalCtrl,
      FuelField.perLiter => _perLiterCtrl,
      null => _odometerCtrl,
    };
  }

  FuelEntryCalc _calc = FuelEntryCalc();
  String? _selectedVehicleId;
  DateTime _date = DateTime.now();
  int? _latestOdometerKm;
  bool _isFullTank = true; // default Full
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

  // ── Helpers ───────────────────────────────────────────────────────────────

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

  /// Called by the keypad's [onChanged] callback and whenever a field's text
  /// changes.  Updates the calc and reflects derived values back into
  /// non-active controllers.
  void _onKeypadChanged() {
    if (_odometerFocused) {
      // Odometer is not part of the calc triple — just rebuild for disabled state.
      setState(() {});
      return;
    }
    final field = _focusedCalcField;
    if (field == null) return;
    final raw = _activeCtrl.text;
    _calc.setField(field, double.tryParse(raw.trim()));
    _reflectDerived(except: field);
    setState(() {});
  }

  /// Push derived values back into the controllers that are NOT currently
  /// being edited. Never touches [except] (avoids cursor-jump on the active
  /// field).
  void _reflectDerived({required FuelField except}) {
    if (_calc.liters != null && except != FuelField.liters) {
      _litersCtrl.text = _calc.liters!.toStringAsFixed(2);
    } else if (_calc.liters == null && except != FuelField.liters) {
      // Clear if the calc lost this value (user cleared the driving field).
      // Only clear if it was previously derived.
      if (_calc.derivedField == FuelField.liters ||
          _litersCtrl.text.isNotEmpty && except != FuelField.liters) {
        // Only clear controller when it was the derived one.
        if (_calc.derivedField == FuelField.liters) _litersCtrl.clear();
      }
    }
    if (_calc.total != null && except != FuelField.total) {
      _totalCtrl.text = _calc.total!.toStringAsFixed(2);
    } else if (_calc.derivedField == FuelField.total &&
        except != FuelField.total) {
      _totalCtrl.clear();
    }
    if (_calc.pricePerLiter != null && except != FuelField.perLiter) {
      _perLiterCtrl.text = _calc.pricePerLiter!.toStringAsFixed(2);
    } else if (_calc.derivedField == FuelField.perLiter &&
        except != FuelField.perLiter) {
      _perLiterCtrl.clear();
    }
  }

  bool get _canSave {
    if (_saving) return false;
    if (_selectedVehicleId == null) return false;
    if (int.tryParse(_odometerCtrl.text.trim()) == null) return false;
    return _calc.isComplete;
  }

  /// Running total in LKR cents shown on the Save button.
  int? get _totalCents {
    if (_calc.total == null) return null;
    return (_calc.total! * 100).round();
  }

  String _totalLabel() {
    final cents = _totalCents;
    if (cents == null) return 'Save';
    // Format as Rs X,XXX
    final rupees = cents ~/ 100;
    final remainderCents = cents % 100;
    final rupeesStr = rupees.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return remainderCents == 0
        ? 'Save · Rs $rupeesStr'
        : 'Save · Rs $rupeesStr.${remainderCents.toString().padLeft(2, '0')}';
  }

  Future<void> _save(DistanceUnit unit) async {
    if (_saving) return; // double-submit guard
    if (!_canSave) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final odo = int.parse(_odometerCtrl.text.trim());
      final liters = _calc.liters!;
      final priceCents = (_calc.total! * 100).round();
      final odometerKm = displayToKm(odo.toDouble(), unit);

      final data = <String, dynamic>{
        'date': _dateText,
        'liters': liters,
        'priceCents': priceCents,
        'odometer': odometerKm,
        'isFullTank': _isFullTank,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final meAsync = ref.watch(meProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: vehiclesAsync.when(
        loading: () =>
            const _SheetBox(child: Center(child: CircularProgressIndicator())),
        error: (e, _) => _SheetBox(child: Text('Failed to load vehicles: $e')),
        data: (vehicles) => meAsync.when(
          loading: () => const _SheetBox(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _SheetBox(child: Text('Failed to load profile: $e')),
          data: (user) => _buildSheet(vehicles, user.distanceUnit),
        ),
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
      if (logsAsync.hasValue) {
        _seedFromLatest(logsAsync.value!, selected);
      }
    }

    final odoHintKm = _latestOdometerKm ?? selected?.currentMileage;
    final odoHint = odoHintKm != null
        ? kmToDisplay(odoHintKm, unit).round().toString()
        : null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(vehicles, unit),
          _buildFields(unit, odoHint),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          _buildActions(unit),
          FuelNumericKeypad(
            controller: _activeCtrl,
            onChanged: _onKeypadChanged,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(List<Vehicle> vehicles, DistanceUnit unit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Log fuel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Date chip
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _dateText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Close
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Fields section ────────────────────────────────────────────────────────

  Widget _buildFields(DistanceUnit unit, String? odoHint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full / Partial segmented control
          _buildFullPartialToggle(),
          const SizedBox(height: 12),
          // Odometer
          _buildTappableField(
            label: 'Odometer (${unit.label})',
            controller: _odometerCtrl,
            hint: odoHint,
            isFocused: _odometerFocused,
            isAuto: false,
            onTap: () => setState(() {
              _odometerFocused = true;
              _focusedCalcField = null;
            }),
          ),
          const SizedBox(height: 10),
          // Liters, Total paid, Price/L — the derive triple
          Row(
            children: [
              Expanded(
                child: _buildTappableField(
                  label: 'Liters',
                  controller: _litersCtrl,
                  isFocused:
                      !_odometerFocused &&
                      _focusedCalcField == FuelField.liters,
                  isAuto: _calc.derivedField == FuelField.liters,
                  onTap: () => setState(() {
                    _odometerFocused = false;
                    _focusedCalcField = FuelField.liters;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTappableField(
                  label: 'Total paid',
                  controller: _totalCtrl,
                  prefix: 'Rs ',
                  isFocused:
                      !_odometerFocused && _focusedCalcField == FuelField.total,
                  isAuto: _calc.derivedField == FuelField.total,
                  onTap: () => setState(() {
                    _odometerFocused = false;
                    _focusedCalcField = FuelField.total;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTappableField(
                  label: 'Price/L',
                  controller: _perLiterCtrl,
                  prefix: 'Rs ',
                  isFocused:
                      !_odometerFocused &&
                      _focusedCalcField == FuelField.perLiter,
                  isAuto: _calc.derivedField == FuelField.perLiter,
                  onTap: () => setState(() {
                    _odometerFocused = false;
                    _focusedCalcField = FuelField.perLiter;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A tappable read-only field fed by the custom keypad.
  Widget _buildTappableField({
    required String label,
    required TextEditingController controller,
    required bool isFocused,
    required bool isAuto,
    required VoidCallback onTap,
    String? hint,
    String? prefix,
  }) {
    final borderColor = isFocused ? AppColors.primary : AppColors.divider;
    final borderWidth = isFocused ? 2.0 : 1.0;
    final text = controller.text;
    final isEmpty = text.isEmpty;

    return GestureDetector(
      key: ValueKey('fuel_field_$label'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isFocused
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                if (isAuto)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AUTO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (prefix != null && !isEmpty)
                  Text(
                    prefix,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                Text(
                  isEmpty ? (hint ?? '—') : text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                if (isFocused && !isAuto)
                  Container(
                    width: 2,
                    height: 18,
                    margin: const EdgeInsets.only(left: 1),
                    color: AppColors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Full / Partial toggle ─────────────────────────────────────────────────

  Widget _buildFullPartialToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            label: 'Full tank',
            selected: _isFullTank,
            onTap: () => setState(() => _isFullTank = true),
            isFirst: true,
          ),
          _buildToggleOption(
            label: 'Partial',
            selected: !_isFullTank,
            onTap: () => setState(() => _isFullTank = false),
            isFirst: false,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isFirst,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(DistanceUnit unit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Full details
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _saving ? null : () => _openFullDetails(unit),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Full details',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Save
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _canSave ? () => _save(unit) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _canSave
                      ? AppColors.primary
                      : AppColors.divider,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.divider,
                  disabledForegroundColor: AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        _totalLabel(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet scaffold ──────────────────────────────────────────────────────────

class _SheetBox extends StatelessWidget {
  final Widget child;
  const _SheetBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: child,
        ),
      ),
    );
  }
}
