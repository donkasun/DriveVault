import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drivevault/core/theme/app_theme.dart';
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

    final email = user.email ?? '';

    return _BannerCard(
      email: email,
      onResend: () async {
        await repo.sendEmailVerification();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification link sent — check your inbox.'),
            ),
          );
        }
      },
      onDismiss: () =>
          ref.read(verifyBannerDismissedProvider.notifier).dismiss(),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.email,
    required this.onResend,
    required this.onDismiss,
  });

  final String email;
  final VoidCallback onResend;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResend,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.photoUploadTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Envelope icon
            Icon(
              Icons.mail_outline_rounded,
              size: 22,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Verify your email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to resend the link to $email',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Dismiss X
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
