import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

import '../data/user_repository.dart';

/// Common 3-letter currency codes offered in the picker. Single currency
/// per user (Doc 3) — applied to all money fields.
const _currencies = ['USD', 'EUR', 'GBP', 'LKR', 'INR', 'AUD', 'CAD', 'JPY'];

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

  Future<void> _update({String? currency, String? distanceUnit}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updatePreferences(currency: currency, distanceUnit: distanceUnit);
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
          leading: const Icon(Icons.email_outlined),
          title: const Text('Email'),
          subtitle: Text(user.email),
        ),
        const Divider(height: 32),

        const _SectionLabel('Preferences'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _currencies.contains(user.currency)
              ? user.currency
              : null,
          decoration: const InputDecoration(
            labelText: 'Currency',
            border: OutlineInputBorder(),
          ),
          items: _currencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: _saving ? null : (value) => _update(currency: value),
        ),
        const SizedBox(height: 16),
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
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
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
