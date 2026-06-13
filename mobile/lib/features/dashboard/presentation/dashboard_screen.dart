import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/shell_tab_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/verify_email_banner.dart';
import '../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/utils/formatting.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../domain/dashboard_data.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    // Account-wide currency preference (defaults to LKR until /me loads).
    final currency = ref.watch(meProvider).asData?.value.currency ?? kFallbackCurrency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VerifyEmailBanner(),
          Expanded(
            child: SafeArea(
              child: dashboardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
                ),
                data: (data) => data.vehicleCount == 0
                    ? const _EmptyState()
                    : _LoadedContent(data: data, currency: currency),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase not initialized in test environments — user stays null.
    }
    final displayName = user?.displayName ?? 'there';
    final photoUrl = user?.photoURL;
    final initials = _initials(displayName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            Text(
              displayName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        photoUrl != null
            ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(photoUrl))
            : CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// State: Loading, Error, Empty
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.black38,
            ),
            const SizedBox(height: 16),
            const Text(
              'No vehicles yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first vehicle to start tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add your first vehicle',
              onPressed: () =>
                  ref.read(pendingTabProvider.notifier).switchTo(1),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State: Loaded
// ---------------------------------------------------------------------------

class _LoadedContent extends StatelessWidget {
  final DashboardData data;
  final String currency;

  const _LoadedContent({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _Header(),
        const SizedBox(height: 20),
        _TotalCostCard(data: data, currency: currency),
        const SizedBox(height: 16),
        const _QuickActions(),
        const SizedBox(height: 16),
        _StatRow(data: data, currency: currency),
        if (data.upcomingRenewals.isNotEmpty) ...[
          const SizedBox(height: 24),
          _UpcomingRenewalsSection(renewals: data.upcomingRenewals),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.local_gas_station, size: 18),
            label: const Text('Add Fuel Log'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: AppColors.primary,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => showQuickFuelEntrySheet(context),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Total Ownership Cost card
// ---------------------------------------------------------------------------

class _TotalCostCard extends StatelessWidget {
  final DashboardData data;
  final String currency;

  const _TotalCostCard({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Ring is decorative: no honest monthly denominator exists in the API data
    // (costBreakdown is all-time, not monthly). Show a full arc with the
    // monthly fuel spend amount centred inside.
    final monthlySpendLabel = formatCents(
      data.monthlyFuelSpendCents,
      currency: currency,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: appCardDecoration.copyWith(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCents(data.totalOwnershipCostCents, currency: currency),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15151C),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Ownership Cost',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'across ${data.vehicleCount} vehicle(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _SpendRingPainter(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthlySpendLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15151C),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'this month',
                      style: TextStyle(fontSize: 8, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative filled-arc ring showing green arc on grey track.
/// Full arc (no meaningful percentage denominator available from the API).
class _SpendRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Grey track — full circle
    canvas.drawArc(rect, startAngle, 2 * math.pi, false, trackPaint);

    // Green arc — decorative full circle (no fake percentage)
    canvas.drawArc(rect, startAngle, 2 * math.pi, false, arcPaint);
  }

  @override
  bool shouldRepaint(_SpendRingPainter old) => false;
}

// ---------------------------------------------------------------------------
// Two stat cards row
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  final DashboardData data;
  final String currency;

  const _StatRow({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Fuel · This Month',
            value: formatCents(data.monthlyFuelSpendCents, currency: currency),
            icon: Icons.local_gas_station,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Maintenance',
            value: formatCents(
              data.costBreakdown.maintenanceCents,
              currency: currency,
            ),
            icon: Icons.build_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration.copyWith(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15151C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming renewals section
// ---------------------------------------------------------------------------

class _UpcomingRenewalsSection extends ConsumerWidget {
  final List<UpcomingRenewal> renewals;

  const _UpcomingRenewalsSection({required this.renewals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the vehicles list to resolve vehicle names from IDs
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.asData?.value ?? const <Vehicle>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Renewals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF15151C),
          ),
        ),
        const SizedBox(height: 12),
        ...renewals.map((r) => _RenewalRow(renewal: r, vehicles: vehicles)),
      ],
    );
  }
}

class _RenewalRow extends StatelessWidget {
  final UpcomingRenewal renewal;
  final List<Vehicle> vehicles;

  const _RenewalRow({required this.renewal, required this.vehicles});

  /// Returns "Make Model Year" for the renewal's vehicleId, or the first 8
  /// characters of the ID if the vehicle is not found in the list.
  String _vehicleDisplayName() {
    try {
      final v = vehicles.firstWhere((v) => v.id == renewal.vehicleId);
      return [
        v.make,
        v.model,
        v.year?.toString(),
      ].where((s) => s != null && s.isNotEmpty).join(' ');
    } catch (_) {
      return '${renewal.vehicleId.substring(0, 8)}…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = expiryColor(renewal.expiryDate);
    final formatted = _formatDate(renewal.expiryDate);
    final vehicleName = _vehicleDisplayName();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: appCardDecoration.copyWith(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/garage/vehicle/${renewal.vehicleId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      renewal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF15151C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicleName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatted,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
