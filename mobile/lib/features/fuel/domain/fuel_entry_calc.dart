enum FuelField { liters, total, perLiter }

/// Resolves the liters / total-amount / price-per-liter triple for quick fuel
/// entry. Only two of the three are needed; the third is derived. Price-per-
/// liter starts as a sticky default (prefilled from the last log).
///
/// The two most-recently-edited fields are authoritative; the remaining field
/// is computed. When per-liter is edited while both others are set, liters is
/// kept and total is recomputed.
///
/// [derivedField] exposes which of the three fields is currently being computed
/// so the UI can tag it as "AUTO". When fewer than two fields are set the
/// derived field is null (no computation possible yet).
class FuelEntryCalc {
  double? liters;
  double? total;
  double? pricePerLiter;

  final List<FuelField> _locked = [];

  FuelEntryCalc({double? initialPerLiter}) {
    if (initialPerLiter != null && initialPerLiter > 0) {
      pricePerLiter = initialPerLiter;
      _locked.add(FuelField.perLiter);
    }
  }

  /// The field currently being derived (AUTO), or null when there isn't one.
  FuelField? get derivedField {
    if (_locked.length < 2) return null;
    return FuelField.values.firstWhere((f) => !_locked.contains(f));
  }

  void setField(FuelField field, double? value) {
    switch (field) {
      case FuelField.liters:
        liters = value;
      case FuelField.total:
        total = value;
      case FuelField.perLiter:
        pricePerLiter = value;
    }

    _locked.remove(field);
    if (value == null) {
      _recompute();
      return;
    }
    _locked.add(field);
    while (_locked.length > 2) {
      final victim =
          (field == FuelField.perLiter && _locked.contains(FuelField.total))
          ? FuelField.total
          : _locked.first;
      _locked.remove(victim);
    }
    _recompute();
  }

  void _recompute() {
    if (_locked.length < 2) return;
    final computed = FuelField.values.firstWhere((f) => !_locked.contains(f));
    switch (computed) {
      case FuelField.perLiter:
        if (liters != null && liters! > 0 && total != null) {
          pricePerLiter = total! / liters!;
        }
      case FuelField.liters:
        if (total != null && pricePerLiter != null && pricePerLiter! > 0) {
          liters = total! / pricePerLiter!;
        }
      case FuelField.total:
        if (liters != null && pricePerLiter != null && pricePerLiter! > 0) {
          total = liters! * pricePerLiter!;
        }
    }
  }

  bool get isComplete =>
      liters != null && liters! > 0 && total != null && total! >= 0;
}
