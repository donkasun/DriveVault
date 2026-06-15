import '../../../shared/constants/currencies.dart';
import '../../fuel/domain/fuel_log.dart';
import '../../maintenance/domain/maintenance_record.dart';

enum ExpenseKind { fuel, maintenance }

class Expense {
  final String id;
  final String vehicleId;
  final ExpenseKind kind;
  final String date; // YYYY-MM-DD
  final int costCents; // maintenance null cost -> 0
  final String currency; // record currency, fallback handled by caller
  final FuelLog? fuelLog; // non-null when kind==fuel
  final MaintenanceRecord? maintenanceRecord; // non-null when kind==maintenance

  const Expense({
    required this.id,
    required this.vehicleId,
    required this.kind,
    required this.date,
    required this.costCents,
    required this.currency,
    this.fuelLog,
    this.maintenanceRecord,
  });

  factory Expense.fromFuelLog(FuelLog l) => Expense(
    id: l.id,
    vehicleId: l.vehicleId,
    kind: ExpenseKind.fuel,
    date: l.date,
    costCents: l.priceCents,
    currency: l.currency,
    fuelLog: l,
    maintenanceRecord: null,
  );

  factory Expense.fromMaintenance(MaintenanceRecord m) => Expense(
    id: m.id,
    vehicleId: m.vehicleId,
    kind: ExpenseKind.maintenance,
    date: m.date,
    costCents: m.costCents ?? 0,
    currency: m.currency ?? kFallbackCurrency,
    fuelLog: null,
    maintenanceRecord: m,
  );
}
