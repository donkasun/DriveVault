import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/verify_email_banner.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/breakdown_bar.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/app_button.dart';
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

    // Graceful fallback: never show "there" — use "Welcome back" when no name.
    final rawName = user?.displayName?.trim() ?? '';
    final hasName = rawName.isNotEmpty;
    final displayName = hasName ? rawName : null;
    final photoUrl = user?.photoURL;
    final initials = hasName ? _initials(rawName) : '?';

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
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            if (displayName != null)
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
    return 'Welcome back';
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const _Header(),
          const SizedBox(height: 20),

          // 1. Needs attention (leads the page — product's reason to exist)
          _NeedsAttentionCard(renewals: attentionRenewals),
          const SizedBox(height: 16),

          // 2. One honest spend card (total + breakdown bar + monthly secondary)
          _SpendCard(data: data, currency: currency),
          const SizedBox(height: 16),

          // 3. Recent activity
          if (data.recentActivity.isNotEmpty) ...[
            _RecentActivitySection(
              items: data.recentActivity,
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
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Needs Attention',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (renewals.isEmpty) ...[
              const SizedBox(height: 16),
              _AllSetState(),
            ] else ...[
              const SizedBox(height: 12),
              ...renewals.map((r) => _RenewalAttentionRow(renewal: r)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllSetState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 18, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "You're all set — no renewals due soon.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go('/garage/vehicle/${renewal.vehicleId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              StatusPill.fromRenewalStatus(
                status,
                daysRemaining: renewal.daysRemaining,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      renewal.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      vehicleLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
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
    final monthlyFuelLabel = formatCents(
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
      BreakdownSegment(
        label: 'Purchase',
        valueCents: data.costBreakdown.purchaseCents,
        color: AppColors.textMuted,
      ),
    ];

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Text(
              'TOTAL OWNERSHIP COST',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),

            // The one big number
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'across ${data.vehicleCount} vehicle${data.vehicleCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Breakdown bar
            BreakdownBar(segments: segments),
            const SizedBox(height: 8),

            // Legend
            _BreakdownLegend(segments: segments, currency: currency),
            const SizedBox(height: 16),

            // This-month fuel secondary stat
            StatCard(
              label: 'Fuel · This month',
              value: monthlyFuelLabel,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownLegend extends StatelessWidget {
  final List<BreakdownSegment> segments;
  final String currency;

  const _BreakdownLegend({required this.segments, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: segments
          .map(
            (s) => Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.label,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DecoratedBox(
          decoration: appCardDecoration,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _ActivityRow(item: items[i], currency: currency),
                if (i < items.length - 1)
                  const Divider(height: 1, indent: 52, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  final String currency;

  const _ActivityRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(item.type);
    final iconBg = _bgForType(item.type);
    final iconColor = _colorForType(item.type);
    final friendlyDate = _friendlyDate(item.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Label + vehicle + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.vehicleLabel} · $friendlyDate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Amount (when present)
          if (item.amountCents != null)
            Text(
              formatCents(item.amountCents!, currency: currency),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(ActivityType type) {
    switch (type) {
      case ActivityType.fuel:
        return Icons.local_gas_station;
      case ActivityType.maintenance:
        return Icons.build_outlined;
      case ActivityType.document:
        return Icons.description_outlined;
    }
  }

  Color _bgForType(ActivityType type) {
    switch (type) {
      case ActivityType.fuel:
        return AppColors.warningBg;
      case ActivityType.maintenance:
        return AppColors.dangerBg;
      case ActivityType.document:
        return AppColors.successBg;
    }
  }

  Color _colorForType(ActivityType type) {
    switch (type) {
      case ActivityType.fuel:
        return AppColors.warning;
      case ActivityType.maintenance:
        return AppColors.danger;
      case ActivityType.document:
        return AppColors.success;
    }
  }

  /// Returns "Today", "Yesterday", "13 Jun", or falls back to the raw date.
  String _friendlyDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(dt);
  }
}
