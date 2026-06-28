import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

import '../../../core/config/app_config.dart';
import '../../driving_credentials/presentation/driving_credentials_section.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../domain/user.dart';
import '../data/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(meProvider);
    final authUser = ref.watch(authStateChangesProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: meAsync.when(
                loading: () => const _ProfileLoadingSkeleton(),
                error: (e, _) =>
                    Center(child: Text('Failed to load profile: $e')),
                data: (user) => _ProfileBody(user: user, authUser: authUser),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final AppUser user;
  final User? authUser;

  const _ProfileBody({required this.user, required this.authUser});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  static const double _bottomScrollablePadding = 132;

  late AppUser _user;
  int _pendingPreferenceUpdates = 0;
  int _updateToken = 0;

  bool get _saving => _pendingPreferenceUpdates > 0;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void didUpdateWidget(covariant _ProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProfileView(oldWidget.user, widget.user)) {
      _user = widget.user;
    }
  }

  Future<void> _update({
    String? distanceUnit,
    bool? renewalRemindersEnabled,
  }) async {
    final previous = _user;
    final token = ++_updateToken;
    setState(() {
      _pendingPreferenceUpdates += 1;
      _user = _applyPreferenceUpdate(
        _user,
        distanceUnit: distanceUnit,
        renewalRemindersEnabled: renewalRemindersEnabled,
      );
    });
    try {
      final updatedUser = await ref
          .read(userRepositoryProvider)
          .updatePreferences(
            distanceUnit: distanceUnit,
            renewalRemindersEnabled: renewalRemindersEnabled,
          );
      if (!mounted || token != _updateToken) return;
      setState(() => _user = updatedUser);
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted && token == _updateToken) {
        setState(() => _user = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preference: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pendingPreferenceUpdates -= 1);
      }
    }
  }

  AppUser _applyPreferenceUpdate(
    AppUser user, {
    String? distanceUnit,
    bool? renewalRemindersEnabled,
  }) {
    return AppUser(
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      currency: user.currency,
      distanceUnit: distanceUnit ?? user.distanceUnit,
      renewalRemindersEnabled:
          renewalRemindersEnabled ?? user.renewalRemindersEnabled,
      createdAt: user.createdAt,
    );
  }

  bool _sameProfileView(AppUser a, AppUser b) {
    return a.id == b.id &&
        a.email == b.email &&
        a.displayName == b.displayName &&
        a.photoUrl == b.photoUrl &&
        a.currency == b.currency &&
        a.distanceUnit == b.distanceUnit &&
        a.renewalRemindersEnabled == b.renewalRemindersEnabled;
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign out?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will need to sign in again to access your vehicles and data.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(ctx, rootNavigator: true).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  foregroundColor: AppColors.textOnDark,
                  elevation: 0,
                ),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx, rootNavigator: true).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, _bottomScrollablePadding),
      children: [
        const _SectionLabel('Account'),
        const SizedBox(height: 8),
        _AccountHeaderCard(
          user: _user,
          authUser: widget.authUser,
          onTap: () => context.push('/profile/edit'),
        ),
        const SizedBox(height: 20),

        const _SectionLabel('Preferences'),
        const SizedBox(height: 8),
        _PreferencesCard(
          user: _user,
          saving: _saving,
          onDistanceUnitChanged: (value) => _update(distanceUnit: value),
          onRenewalRemindersChanged: (value) =>
              _update(renewalRemindersEnabled: value),
        ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 20),

        const _SectionLabel('Driving Credentials'),
        const SizedBox(height: 8),
        const DrivingCredentialsSection(),
        const SizedBox(height: 20),

        const _SectionLabel('About'),
        const SizedBox(height: 8),
        const _AboutSection(),
        const SizedBox(height: 20),

        _SignOutButton(onPressed: _confirmSignOut),
      ],
    );
  }
}

class _AccountHeaderCard extends StatelessWidget {
  final AppUser user;
  final User? authUser;
  final VoidCallback onTap;

  const _AccountHeaderCard({
    required this.user,
    required this.authUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        (user.displayName?.isNotEmpty == true ? user.displayName! : user.email)
            .trim();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final emailVerified = authUser?.emailVerified ?? true;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFD200),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2030),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF24243A),
                            ),
                          ),
                        ),
                        if (!emailVerified) ...[
                          const SizedBox(width: 8),
                          _UnverifiedBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8F90A6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Color(0xFFC3C4D1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnverifiedBadge extends StatelessWidget {
  final bool compact;

  const _UnverifiedBadge({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.warning_amber_outlined,
            size: 14,
            color: Color(0xFFC96A00),
          ),
          SizedBox(width: 4),
          Text(
            'Unverified',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC96A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 18, color: Color(0xFF7D7D9A)),
              SizedBox(width: 10),
              Text(
                'Sign out',
                style: TextStyle(
                  color: Color(0xFF7D7D9A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _AboutRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy & data',
            onTap: () => _showPlaceholder(context, 'Privacy & data'),
          ),
          const Divider(height: 1),
          _AboutRow(
            icon: Icons.mail_outline,
            label: 'Help & feedback',
            onTap: () => _showPlaceholder(context, 'Help & feedback'),
          ),
          const Divider(height: 1),
          const _AboutVersionRow(value: AppConfig.appVersion),
        ],
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label coming soon')));
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF8E8EA8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF24243A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: Color(0xFFB8B8C8)),
          ],
        ),
      ),
    );
  }
}

class _AboutVersionRow extends StatelessWidget {
  final String value;

  const _AboutVersionRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: Color(0xFF8E8EA8),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Version',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF24243A),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB0B0C0),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final AppUser user;
  final bool saving;
  final ValueChanged<String> onDistanceUnitChanged;
  final ValueChanged<bool> onRenewalRemindersChanged;

  const _PreferencesCard({
    required this.user,
    required this.saving,
    required this.onDistanceUnitChanged,
    required this.onRenewalRemindersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyInfo = currencyInfoFor(user.currency);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _PreferenceRowShell(
            icon: Icons.straighten_rounded,
            iconBackground: const Color(0xFFEFF2FF),
            iconColor: const Color(0xFF3F5DE8),
            title: 'Distance unit',
            trailing: _DistanceUnitSelector(
              value: user.distanceUnit,
              enabled: !saving,
              onChanged: onDistanceUnitChanged,
            ),
          ),
          const Divider(height: 1),
          _PreferenceRowShell(
            icon: Icons.payments_outlined,
            iconBackground: const Color(0xFFF1F2F8),
            iconColor: const Color(0xFF8D92A8),
            title: 'Currency',
            subtitle: 'Locked for this account',
            trailing: _LockedCurrencyLabel(
              code: user.currency,
              name: currencyInfo?.name ?? user.currency,
            ),
          ),
          const Divider(height: 1),
          _PreferenceRowShell(
            icon: Icons.notifications_none_rounded,
            iconBackground: const Color(0xFFFFF3D9),
            iconColor: const Color(0xFFF08A00),
            title: 'Renewal reminders',
            subtitle: 'Alert before documents expire',
            trailing: Switch(
              value: user.renewalRemindersEnabled,
              onChanged: saving ? null : onRenewalRemindersChanged,
              activeThumbColor: const Color(0xFF1D1D2D),
              activeTrackColor: const Color(0xFFFFD100),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE3E3EC),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceRowShell extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;

  const _PreferenceRowShell({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24243A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9A9AAF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _DistanceUnitSelector extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _DistanceUnitSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Container(
        width: 164,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5FA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: value == 'mi'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F2E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onChanged('km'),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: value == 'km'
                                ? Colors.white
                                : const Color(0xFF8A8AA3),
                          ),
                          child: const Text('Km'),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onChanged('mi'),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: value == 'mi'
                                ? Colors.white
                                : const Color(0xFF8A8AA3),
                          ),
                          child: const Text('Miles'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedCurrencyLabel extends StatelessWidget {
  final String code;
  final String name;

  const _LockedCurrencyLabel({required this.code, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '$code · $name',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C8CA1),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: Color(0xFFC1C1D0),
        ),
      ],
    );
  }
}

class _ProfileLoadingSkeleton extends StatelessWidget {
  const _ProfileLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        Row(
          children: [
            ShimmerBox(height: 56, borderRadius: 28, width: 56),
            SizedBox(width: 16),
            Expanded(child: ShimmerBox(height: 20, borderRadius: 6)),
          ],
        ),
        SizedBox(height: 24),
        ShimmerBox(height: 52, borderRadius: 12),
        SizedBox(height: 12),
        ShimmerBox(height: 52, borderRadius: 12),
        SizedBox(height: 12),
        ShimmerBox(height: 52, borderRadius: 12),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFF9A9AAF),
        ),
      ),
    );
  }
}
