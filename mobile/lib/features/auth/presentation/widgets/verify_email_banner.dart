import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

/// In-memory, per-session dismissal of the verify-email banner. Resets on app
/// restart (no persistence) so the nudge returns each launch until verified.
class BannerDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
  void reset() => state = false;
}

final verifyBannerDismissedProvider =
    NotifierProvider<BannerDismissedNotifier, bool>(
      BannerDismissedNotifier.new,
    );

class VerifyEmailBanner extends ConsumerWidget {
  const VerifyEmailBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(verifyBannerDismissedProvider);
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    final isPasswordProvider =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;
    final unverified = user != null && !user.emailVerified;

    if (dismissed || !isPasswordProvider || !unverified) {
      return const SizedBox.shrink();
    }

    return MaterialBanner(
      backgroundColor: Colors.amber.shade100,
      content: const Text('Verify your email to secure your account.'),
      leading: const Icon(Icons.mark_email_unread_outlined),
      actions: [
        TextButton(
          onPressed: () async {
            await repo.sendEmailVerification();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification email sent')),
              );
            }
          },
          child: const Text('Resend'),
        ),
        TextButton(
          onPressed: () async {
            await repo.reloadUser();
            ref.invalidate(verifyBannerDismissedProvider);
          },
          child: const Text("I've verified"),
        ),
        TextButton(
          onPressed: () =>
              ref.read(verifyBannerDismissedProvider.notifier).dismiss(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
