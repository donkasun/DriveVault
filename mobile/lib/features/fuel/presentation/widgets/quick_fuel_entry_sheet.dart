import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/sheet_close_button.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../dashboard/presentation/dashboard_provider.dart';
import '../../../profile/data/user_repository.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicles_provider.dart';
import '../../data/fuel_repository.dart';
import '../../domain/fuel_entry_calc.dart';
import '../../domain/fuel_log.dart';
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
  FuelLog? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true, // cover the floating tab bar
    backgroundColor: Colors.transparent,
    builder: (_) =>
        QuickFuelEntrySheet(vehicleId: vehicleId, existing: existing),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class QuickFuelEntrySheet extends ConsumerStatefulWidget {
  final String? vehicleId;
  final FuelLog? existing;
  const QuickFuelEntrySheet({super.key, this.vehicleId, this.existing});

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
  bool _existingSeeded = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId ?? widget.existing?.vehicleId;
    if (widget.existing != null) _isFullTank = widget.existing!.isFullTank;
  }

  void _seedFromExisting(FuelLog log, DistanceUnit unit) {
    if (_existingSeeded) return;
    _existingSeeded = true;
    _calcSeeded = true; // block _seedFromLatest from overwriting

    final parsed = DateTime.tryParse(log.date);
    if (parsed != null) _date = parsed;

    final odoDisplay = kmToDisplay(log.odometer, unit).round();
    _odometerCtrl.text = odoDisplay.toString();

    final liters = log.liters;
    final total = log.priceCents / 100;
    final perLiter = liters > 0 ? total / liters : null;

    _litersCtrl.text = liters.toStringAsFixed(2);
    _totalCtrl.text = total.toStringAsFixed(2);
    if (perLiter != null) _perLiterCtrl.text = perLiter.toStringAsFixed(2);

    _calc = FuelEntryCalc(initialPerLiter: perLiter);
    _calc.setField(FuelField.liters, liters);
    _calc.setField(FuelField.total, total);
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

  /// Seed per-liter price + odometer hint from the latest log for the selected
  /// vehicle. Returns true when a valid price was found and seeded so the
  /// caller knows whether to try a fallback.
  bool _seedFromLatest(List<dynamic> logs, Vehicle? vehicle) {
    if (_calcSeeded) return true;
    // Odometer hint: always set from this vehicle's data when available.
    final latest = logs.isNotEmpty ? logs.first : null;
    _latestOdometerKm ??= latest?.odometer ?? vehicle?.currentMileage;
    if (latest != null && latest.liters > 0) {
      final perLiter = latest.priceCents / 100 / latest.liters;
      _perLiterCtrl.text = perLiter.toStringAsFixed(2);
      _calc = FuelEntryCalc(initialPerLiter: perLiter);
      _calcSeeded = true;
      return true;
    }
    // No usable price yet — don't lock _calcSeeded so fallback can still run.
    _calc = FuelEntryCalc();
    return false;
  }

  /// Fallback: find the most recent log across vehicles with the same
  /// fuelType as [selected] and seed the per-liter price from it.
  void _seedFallbackPrice(List<Vehicle> vehicles, Vehicle? selected) {
    if (_calcSeeded) return;
    final fuelType = selected?.fuelType;
    for (final v in vehicles) {
      if (v.id == _selectedVehicleId) continue;
      // Match fuel type — if selected has no type set, accept any vehicle.
      if (fuelType != null && v.fuelType != fuelType) continue;
      final logsAsync = ref.watch(fuelLogsProvider(v.id));
      if (!logsAsync.hasValue) continue;
      final logs = logsAsync.value!;
      if (logs.isEmpty) continue;
      final latest = logs.first;
      if (latest.liters <= 0) continue;
      final perLiter = latest.priceCents / 100 / latest.liters;
      _perLiterCtrl.text = perLiter.toStringAsFixed(2);
      _calc = FuelEntryCalc(initialPerLiter: perLiter);
      _calcSeeded = true;
      return;
    }
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
    _syncCalcFromControllers(activeField: field);
    _reflectDerived(except: field);
    setState(() {});
  }

  double? _parseValue(TextEditingController controller) {
    return double.tryParse(controller.text.trim());
  }

  /// Rebuild the calculator from the visible controller values.
  ///
  /// The currently edited field is applied last so it remains authoritative,
  /// while the other populated fields provide the context needed to derive the
  /// third value.
  void _syncCalcFromControllers({required FuelField activeField}) {
    final liters = _parseValue(_litersCtrl);
    final total = _parseValue(_totalCtrl);
    final perLiter = _parseValue(_perLiterCtrl);

    _calc = FuelEntryCalc(
      initialPerLiter: perLiter != null && perLiter > 0 ? perLiter : null,
    );

    for (final field in const [
      FuelField.liters,
      FuelField.total,
      FuelField.perLiter,
    ]) {
      if (field == activeField) continue;
      _calc.setField(field, switch (field) {
        FuelField.liters => liters,
        FuelField.total => total,
        FuelField.perLiter => perLiter,
      });
    }

    _calc.setField(activeField, switch (activeField) {
      FuelField.liters => liters,
      FuelField.total => total,
      FuelField.perLiter => perLiter,
    });
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
    final odoText = _odometerCtrl.text.trim();
    // Valid if the user typed a parseable integer OR we have a known last reading.
    if (odoText.isNotEmpty && int.tryParse(odoText) == null) return false;
    if (odoText.isEmpty && _latestOdometerKm == null) return false;
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
      final odoText = _odometerCtrl.text.trim();
      final int odometerKm;
      if (odoText.isNotEmpty) {
        odometerKm = displayToKm(int.parse(odoText).toDouble(), unit).round();
      } else {
        // Fallback to the last-known reading (already stored in km).
        odometerKm = _latestOdometerKm!;
      }
      final liters = _calc.liters!;
      final priceCents = (_calc.total! * 100).round();

      final data = <String, dynamic>{
        'date': _dateText,
        'liters': liters,
        'priceCents': priceCents,
        'odometer': odometerKm,
        'isFullTank': _isFullTank,
        'notes': widget.existing?.notes,
      };
      if (widget.existing != null) {
        await ref.read(fuelRepositoryProvider).updateFuelLog(widget.existing!.id, data);
        ref.invalidate(fuelLogsProvider(_selectedVehicleId!));
      } else {
        await ref
            .read(fuelLogsProvider(_selectedVehicleId!).notifier)
            .createOptimistic(_selectedVehicleId!, data);
      }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: vehiclesAsync.when(
              loading: () => const _SheetBox(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  _SheetBox(child: Text('Failed to load vehicles: $e')),
              data: (vehicles) => meAsync.when(
                loading: () => const _SheetBox(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    _SheetBox(child: Text('Failed to load profile: $e')),
                data: (user) => _buildSheet(vehicles, user.distanceUnit),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(List<Vehicle> vehicles, String userUnit) {
    // Default to the vehicle with the most recent activity (latest updatedAt).
    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      final sorted = [...vehicles]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _selectedVehicleId = sorted.first.id;
    }

    Vehicle? selected;
    for (final v in vehicles) {
      if (v.id == _selectedVehicleId) selected = v;
    }
    final unit = effectiveUnit(
      vehicleUnit: selected?.distanceUnit,
      userUnit: userUnit,
    );

    if (widget.existing != null) {
      _seedFromExisting(widget.existing!, unit);
    } else if (_selectedVehicleId != null) {
      final logsAsync = ref.watch(fuelLogsProvider(_selectedVehicleId!));
      if (logsAsync.hasValue) {
        final priceFound = _seedFromLatest(logsAsync.value!, selected);
        if (!priceFound) _seedFallbackPrice(vehicles, selected);
      }
    }

    final odoHintKm = _latestOdometerKm ?? selected?.currentMileage;
    final odoHint = odoHintKm != null
        ? kmToDisplay(odoHintKm, unit).round().toString()
        : null;

    // Pre-fill odometer with the hint so Save is enabled without requiring
    // the user to re-enter a value they can already see as the placeholder.
    if (_odometerCtrl.text.isEmpty && odoHint != null) {
      _odometerCtrl.text = odoHint;
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(vehicles, unit),
          if (vehicles.isNotEmpty) _buildVehicleSelector(vehicles, selected),
          _buildFields(unit, odoHint),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          const SizedBox(height: 10),
          FuelNumericKeypad(
            controller: _activeCtrl,
            onChanged: _onKeypadChanged,
          ),
          _buildActions(unit),
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
              widget.existing != null ? 'Edit fill-up' : 'Log a fill-up',
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
          SheetCloseButton(onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  // ── Vehicle selector ──────────────────────────────────────────────────────

  Widget _buildVehicleSelector(List<Vehicle> vehicles, Vehicle? selected) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: vehicles.length > 1 ? () => _showVehiclePicker(vehicles) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              _vehicleTypeIcon(
                selected?.vehicleType,
                size: 34,
                photoUrl: selected?.photoUrl,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected?.displayName ?? '—',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (selected?.registrationNumber != null)
                      Text(
                        selected!.registrationNumber!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (vehicles.length > 1)
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehiclePicker(List<Vehicle> vehicles) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehiclePickerSheet(
        vehicles: vehicles,
        selectedId: _selectedVehicleId,
        onSelected: (id) {
          setState(() {
            _selectedVehicleId = id;
            _calcSeeded =
                false; // re-seed price/L from new vehicle's latest log
            _latestOdometerKm = null;
            _perLiterCtrl.clear();
            _litersCtrl.clear();
            _totalCtrl.clear();
            _odometerCtrl.clear();
            _calc = FuelEntryCalc();
          });
        },
      ),
    );
  }

  static Widget _vehicleTypeIcon(
    String? type, {
    double size = 34,
    String? photoUrl,
  }) {
    if (photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _vehicleTypeIcon(type, size: size),
        ),
      );
    }
    final icon = switch (type) {
      'motorcycle' => Icons.two_wheeler,
      'truck' || 'pickup' => Icons.local_shipping_outlined,
      'van' => Icons.airport_shuttle_outlined,
      _ => Icons.directions_car_outlined,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: size * 0.55, color: const Color(0xFFA06800)),
    );
  }

  // ── Fields section ────────────────────────────────────────────────────────

  Widget _buildFields(DistanceUnit unit, String? odoHint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Odometer — flat single-line row
          GestureDetector(
            key: ValueKey('fuel_field_Odometer (${unit.label})'),
            onTap: () => setState(() {
              _odometerFocused = true;
              _focusedCalcField = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _odometerFocused
                    ? AppColors.surface
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: _odometerFocused
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _odometerFocused
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  const Text(
                    'ODOMETER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _odometerCtrl.text.isEmpty
                            ? (odoHint ?? '0')
                            : _odometerCtrl.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: _odometerCtrl.text.isEmpty
                              ? AppColors.divider
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_odometerFocused) const _BlinkingCursor(),
                    ],
                  ),
                  const SizedBox(width: 3),
                  Text(
                    unit.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Liters, Total paid, Price/L — the derive triple
          Row(
            children: [
              Expanded(
                flex: 2,
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
                flex: 3,
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
                flex: 3,
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
          const SizedBox(height: 10),
          // Full / Partial toggle — below the tiles per design
          _buildFullPartialToggle(),
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
    String? unitSuffix,
  }) {
    final text = controller.text;
    final isEmpty = text.isEmpty;
    // Strip trailing .00 for display only; keep fractional cents when non-zero.
    final displayText = text.endsWith('.00')
        ? text.substring(0, text.length - 3)
        : text;
    // Active: white bg + dark border + shadow. Inactive: very light gray, no border.
    final bgColor = isFocused ? AppColors.surface : const Color(0xFFF2F2F7);
    final borderColor = isFocused ? AppColors.textPrimary : Colors.transparent;

    return GestureDetector(
      key: ValueKey('fuel_field_$label'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isAuto) const SizedBox(width: 4),
                if (isAuto)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'AUTO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (prefix != null && !isEmpty)
                  Text(
                    prefix,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAuto ? AppColors.textMuted : AppColors.textMuted,
                    ),
                  ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isEmpty ? (hint ?? '0') : displayText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isEmpty
                                ? AppColors.divider
                                : isAuto
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isFocused) const _BlinkingCursor(),
                    ],
                  ),
                ),
                if (unitSuffix != null)
                  Text(
                    unitSuffix,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
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
    return Row(
      children: [
        _buildToggleOption(
          label: 'Full tank',
          selected: _isFullTank,
          onTap: () => setState(() => _isFullTank = true),
        ),
        const SizedBox(width: 8),
        _buildToggleOption(
          label: 'Partial',
          selected: !_isFullTank,
          onTap: () => setState(() => _isFullTank = false),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.divider,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(DistanceUnit unit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Opacity(
        opacity: _canSave ? 1.0 : 0.5,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton(
            onPressed: _canSave ? () => _save(unit) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Vehicle picker sheet ─────────────────────────────────────────────────────

class _VehiclePickerSheet extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String? selectedId;
  final void Function(String id) onSelected;

  const _VehiclePickerSheet({
    required this.vehicles,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 2),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select vehicle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            for (final v in vehicles)
              InkWell(
                onTap: () {
                  onSelected(v.id);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _QuickFuelEntrySheetState._vehicleTypeIcon(
                        v.vehicleType,
                        size: 38,
                        photoUrl: v.photoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (v.registrationNumber != null)
                              Text(
                                v.registrationNumber!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (v.id == selectedId)
                        const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
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

/// Blinking vertical bar cursor for custom-keypad fields.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 20,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
