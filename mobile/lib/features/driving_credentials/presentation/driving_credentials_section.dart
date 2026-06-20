import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/driving_credential_repository.dart';
import '../domain/driving_credential.dart';

class DrivingCredentialsSection extends ConsumerWidget {
  const DrivingCredentialsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCreds = ref.watch(credentialsProvider);

    return asyncCreds.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(
        'Failed to load credentials: $e',
        style: const TextStyle(color: Colors.red),
      ),
      data: (creds) => _CredentialsList(creds: creds),
    );
  }
}

class _CredentialsList extends ConsumerWidget {
  final List<DrivingCredential> creds;

  const _CredentialsList({required this.creds});

  static const _allDocTypes = ['license', 'permit', 'international_license'];

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DrivingCredential cred,
  ) async {
    final confirm = await showModalBottomSheet<bool>(
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
              Text(
                'Delete "${DrivingCredential.labelFor(cred.docType)}"?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This cannot be undone.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(drivingCredentialRepositoryProvider).delete(cred.id);
      ref.invalidate(credentialsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingTypes = creds.map((c) => c.docType).toSet();
    final allTypesPresent = _allDocTypes.every(existingTypes.contains);

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
          ...creds.asMap().entries.map((entry) {
            final i = entry.key;
            final cred = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1),
                _CredentialTile(
                  cred: cred,
                  onTap: () async {
                    final result = await context.push(
                      '/profile/credentials/edit',
                      extra: cred,
                    );
                    if (result == true) ref.invalidate(credentialsProvider);
                  },
                  onLongPress: () => _confirmDelete(context, ref, cred),
                ),
              ],
            );
          }),
          if (!allTypesPresent) ...[
            if (creds.isNotEmpty) const Divider(height: 1),
            _AddCredentialRow(
              onTap: () async {
                final result =
                    await context.push('/profile/credentials/add');
                if (result == true) ref.invalidate(credentialsProvider);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final DrivingCredential cred;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CredentialTile({
    required this.cred,
    required this.onTap,
    required this.onLongPress,
  });

  IconData get _icon {
    switch (cred.docType) {
      case 'permit':
        return Icons.credit_card;
      case 'international_license':
        return Icons.language;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = DrivingCredential.labelFor(cred.docType);
    final subtitle =
        cred.docNumber != null ? '$label · ${cred.docNumber}' : label;
    final expiryText = cred.expiryDate != null
        ? 'Expires ${_formatDate(cred.expiryDate!)}'
        : 'No expiry set';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, size: 20, color: const Color(0xFF3F5DE8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF24243A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiryText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A9AAF),
                    ),
                  ),
                ],
              ),
            ),
            if (cred.status != null) ...[
              const SizedBox(width: 8),
              StatusPill.fromCredentialStatus(
                cred.status,
                daysLeft: cred.daysUntilExpiry,
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFB8B8C8),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d MMM y').format(d);
    } catch (_) {
      return iso;
    }
  }
}

class _AddCredentialRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCredentialRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF3F5DE8)),
            SizedBox(width: 12),
            Text(
              'Add Credential',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3F5DE8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
