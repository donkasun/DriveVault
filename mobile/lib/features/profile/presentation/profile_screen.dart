import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

import '../../../core/theme/app_theme.dart';
import '../data/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: meAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (_) => const _ProfileBody(),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody();

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _saving = false;

  Future<void> _update({String? distanceUnit}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updatePreferences(distanceUnit: distanceUnit);
      ref.invalidate(meProvider);
      await ref.read(meProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preference: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
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
    // Safe: parent only builds this once meProvider has data.
    final user = ref.watch(meProvider).requireValue;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionLabel('Account'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: const Text('Display name'),
          subtitle: Text(
            user.displayName?.isNotEmpty == true
                ? user.displayName!
                : 'Not set',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/profile/edit'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.email_outlined),
          title: const Text('Email'),
          subtitle: Text(user.email),
        ),
        const Divider(height: 32),

        const _SectionLabel('Preferences'),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Distance unit',
            border: OutlineInputBorder(),
          ),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'km', label: Text('Kilometres')),
              ButtonSegment(value: 'mi', label: Text('Miles')),
            ],
            selected: {user.distanceUnit},
            onSelectionChanged: _saving
                ? null
                : (sel) => _update(distanceUnit: sel.first),
          ),
        ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        const Divider(height: 32),

        ElevatedButton(
          onPressed: _confirmSignOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}
