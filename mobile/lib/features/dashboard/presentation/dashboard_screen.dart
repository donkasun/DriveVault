import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/verify_email_banner.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/activity_entry_card.dart';
import '../../../shared/widgets/breakdown_bar.dart';
import '../../../shared/widgets/fuel_pump_icon.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/app_button.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../profile/data/user_repository.dart';
import '../domain/dashboard_data.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    // Account-wide currency preference (defaults to LKR until /me loads).
    final currency =
        ref.watch(meProvider).asData?.value.currency ?? kFallbackCurrency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VerifyEmailBanner(),
          Expanded(
            child: SafeArea(
              child: dashboardAsync.when(
                loading: () => const _LoadingState(),
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

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(meProvider).asData?.value;

    final rawName = appUser?.displayName?.trim() ?? '';
    final hasName = rawName.isNotEmpty;
    final photoUrl = appUser?.photoUrl;
    final initials = hasName ? _initials(rawName) : '?';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            if (hasName)
              Text(
                rawName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
        photoUrl != null
            ? CircleAvatar(radius: 23, backgroundImage: NetworkImage(photoUrl))
            : CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Welcome back,';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// State: Loading (skeletons)
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonBox(height: 56, borderRadius: 12),
        const SizedBox(height: 20),
        _SkeletonBox(height: 100, borderRadius: 16),
        const SizedBox(height: 16),
        _SkeletonBox(height: 80, borderRadius: 16),
        const SizedBox(height: 16),
        _SkeletonBox(height: 60, borderRadius: 12),
        const SizedBox(height: 8),
        _SkeletonBox(height: 60, borderRadius: 12),
        const SizedBox(height: 24),
        _SkeletonBox(height: 72, borderRadius: 12),
        const SizedBox(height: 8),
        _SkeletonBox(height: 72, borderRadius: 12),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double borderRadius;

  const _SkeletonBox({required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State: Error
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
            Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State: Empty (no vehicles)
// ---------------------------------------------------------------------------

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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 36,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No vehicles yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to start tracking your ownership costs.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add your first vehicle',
              onPressed: () => context.go('/garage'),
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

class _LoadedContent extends ConsumerWidget {
  final DashboardData data;
  final String currency;

  const _LoadedContent({required this.data, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter to only the renewals needing attention (overdue or soon).
    final attentionRenewals = data.upcomingRenewals
        .where(
          (r) =>
              r.status == RenewalStatus.overdue ||
              r.status == RenewalStatus.soon,
        )
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const _Header(),
          const SizedBox(height: 20),

          // 1. Needs attention (only shown when there are items)
          if (attentionRenewals.isNotEmpty) ...[
            _NeedsAttentionCard(renewals: attentionRenewals),
            const SizedBox(height: 16),
          ],

          // 2. One honest spend card (total + breakdown bar + monthly secondary)
          _SpendCard(data: data, currency: currency),
          const SizedBox(height: 16),

          // 3. Recent activity
          if (data.recentActivity.isNotEmpty) ...[
            _RecentActivitySection(
              items: data.recentActivity.take(5).toList(),
              currency: currency,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Needs Attention card
// ---------------------------------------------------------------------------

class _NeedsAttentionCard extends StatelessWidget {
  final List<UpcomingRenewal> renewals;

  const _NeedsAttentionCard({required this.renewals});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.25),
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Needs attention',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (renewals.isNotEmpty)
                  Text(
                    '${renewals.length} item${renewals.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
              ],
            ),
          ),
          for (final renewal in renewals) ...[
            const Divider(height: 1, color: Color(0xFF34333F)),
            _RenewalAttentionRow(renewal: renewal),
          ],
        ],
      ),
    );
  }
}


class _RenewalAttentionRow extends StatelessWidget {
  final UpcomingRenewal renewal;

  const _RenewalAttentionRow({required this.renewal});

  @override
  Widget build(BuildContext context) {
    // Prefer the API-supplied vehicleLabel; fall back to vehicleId prefix.
    final vehicleLabel = renewal.vehicleLabel?.isNotEmpty == true
        ? renewal.vehicleLabel!
        : '${renewal.vehicleId.substring(0, 8)}…';

    final status = renewal.status ?? RenewalStatus.soon;

    return InkWell(
      onTap: () => context.go('/garage/vehicle/${renewal.vehicleId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    renewal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    vehicleLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill.fromRenewalStatus(
              status,
              daysRemaining: renewal.daysRemaining,
              onDark: true,
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0x61EBEBF5), // rgba(235,235,245,0.38)
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Spend card — one number, one meaning
// ---------------------------------------------------------------------------

class _SpendCard extends StatelessWidget {
  final DashboardData data;
  final String currency;

  const _SpendCard({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    final totalLabel = formatCents(
      data.totalOwnershipCostCents,
      currency: currency,
    );
    final monthlyLabel = formatCents(
      data.monthlyFuelSpendCents,
      currency: currency,
    );

    final segments = [
      BreakdownSegment(
        label: 'Fuel',
        valueCents: data.costBreakdown.fuelCents,
        color: AppColors.primary,
      ),
      BreakdownSegment(
        label: 'Maintenance',
        valueCents: data.costBreakdown.maintenanceCents,
        color: AppColors.surfaceDark,
      ),
    ];
    String fmt(int c) => formatCents(c, currency: currency);

    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: AppColors.textMuted,
    );

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Two columns: each has its own label stacked above its value.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left — total ownership cost
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL OWNERSHIP COST', style: labelStyle),
                      const SizedBox(height: 2),
                      Text(
                        totalLabel,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'across ${data.vehicleCount} vehicle${data.vehicleCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right — this month (right-aligned)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('THIS MONTH', style: labelStyle),
                    const SizedBox(height: 4),
                    Text(
                      monthlyLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            BreakdownBarWithLegend(segments: segments, formatAmount: fmt, barHeight: 10),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Recent activity section
// ---------------------------------------------------------------------------

class _RecentActivitySection extends StatelessWidget {
  final List<ActivityItem> items;
  final String currency;

  const _RecentActivitySection({required this.items, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        for (final item in items) ...[
          _ActivityCard(item: item, currency: currency),
          const SizedBox(height: 10),
        ],
        const _SeeAllExpensesButton(),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final String currency;

  const _ActivityCard({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final friendlyDate = _friendlyDate(item.date);

    final String subLabel;
    if (item.type == ActivityType.fuel && item.liters != null) {
      subLabel =
          '$friendlyDate · ${item.liters!.toStringAsFixed(1)} L · ${item.isFull == true ? 'Full tank' : 'Partial'}';
    } else {
      subLabel = '$friendlyDate · ${item.label}';
    }

    return ActivityEntryCard(
      icon: _iconWidget(),
      title: item.vehicleLabel,
      subLabel: subLabel,
      amountCents: item.amountCents,
      currency: currency,
    );
  }

  Widget _iconWidget() {
    if (item.type == ActivityType.fuel) {
      final isFull = item.isFull ?? true;
      final bg = isFull
          ? AppColors.successBg
          : AppColors.primary.withValues(alpha: 0.12);
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: FuelPumpIcon(isFullTank: isFull, size: 20, darkInk: !isFull),
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _bgForType(item.type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_iconForType(item.type), size: 20, color: _colorForType(item.type)),
    );
  }

  IconData _iconForType(ActivityType type) => switch (type) {
    ActivityType.fuel        => Icons.local_gas_station,
    ActivityType.maintenance => Icons.build_outlined,
    ActivityType.document    => Icons.description_outlined,
  };

  Color _bgForType(ActivityType type) => switch (type) {
    ActivityType.fuel        => AppColors.successBg,
    ActivityType.maintenance => AppColors.surfaceDark.withValues(alpha: 0.08),
    ActivityType.document    => AppColors.successBg,
  };

  Color _colorForType(ActivityType type) => switch (type) {
    ActivityType.fuel        => AppColors.success,
    ActivityType.maintenance => AppColors.surfaceDark,
    ActivityType.document    => AppColors.success,
  };

  String _friendlyDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(dt);
  }
}

class _SeeAllExpensesButton extends StatelessWidget {
  const _SeeAllExpensesButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const ActivityScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'See all activity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
