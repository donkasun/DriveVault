import 'package:intl/intl.dart';

/// The unit used to display distance values to the user.
///
/// Storage convention: odometer / mileage values are ALWAYS stored and sent
/// over the wire in **kilometres** (integer km).  This enum exists only at the
/// UI edge for display / input conversion.
enum DistanceUnit {
  km,
  mi;

  /// Parse "km" or "mi" (case-insensitive).  Throws [ArgumentError] for
  /// anything else.
  static DistanceUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'km':
        return DistanceUnit.km;
      case 'mi':
        return DistanceUnit.mi;
      default:
        throw ArgumentError.value(value, 'value', 'Must be "km" or "mi"');
    }
  }

  /// Wire/storage label ("km" or "mi").
  String get label => name; // enum name matches the label exactly
}

// ---------------------------------------------------------------------------
// Effective-unit resolution
// ---------------------------------------------------------------------------

/// Returns the effective display unit for a vehicle.
///
/// [vehicleUnit] is the per-vehicle override ("km" / "mi" / null).
/// [userUnit]    is the user-level default ("km" / "mi").
///
/// Rule: vehicleUnit ?? userUnit (vehicle override wins; null inherits default).
DistanceUnit effectiveUnit({
  required String? vehicleUnit,
  required String userUnit,
}) {
  final raw = vehicleUnit ?? userUnit;
  return DistanceUnit.fromString(raw);
}

// ---------------------------------------------------------------------------
// Conversions
// ---------------------------------------------------------------------------

/// Conversion factor from km to miles.
const double _kmToMi = 0.621371;

/// Conversion factor from miles to km.
const double _miToKm = 1.609344;

/// Convert a stored integer km value to the display unit.
///
/// Returns a [double] so callers can format as they like.
double kmToDisplay(int km, DistanceUnit unit) {
  return switch (unit) {
    DistanceUnit.km => km.toDouble(),
    DistanceUnit.mi => km * _kmToMi,
  };
}

/// Convert a user-entered value in [unit] to an integer km for storage.
///
/// Miles are converted to km and the result is rounded to the nearest integer.
int displayToKm(double displayValue, DistanceUnit unit) {
  return switch (unit) {
    DistanceUnit.km => displayValue.round(),
    DistanceUnit.mi => (displayValue * _miToKm).round(),
  };
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

final NumberFormat _intFmt = NumberFormat('#,##0', 'en_US');

/// Format a stored km value for display with a unit suffix.
///
/// Examples:
///   formatDistance(48200, DistanceUnit.km) → "48,200 km"
///   formatDistance(48200, DistanceUnit.mi) → "29,950 mi"
String formatDistance(int km, DistanceUnit unit) {
  final displayValue = kmToDisplay(km, unit);
  return '${_intFmt.format(displayValue.round())} ${unit.label}';
}
