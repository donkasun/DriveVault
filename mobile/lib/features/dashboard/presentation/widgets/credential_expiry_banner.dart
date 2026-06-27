import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/driving_credentials/data/driving_credential_repository.dart';
import '../../../../features/driving_credentials/domain/driving_credential.dart';

class CredentialExpiryBanner extends ConsumerStatefulWidget {
  const CredentialExpiryBanner({super.key});

  @override
  ConsumerState<CredentialExpiryBanner> createState() =>
      _CredentialExpiryBannerState();
}

class _CredentialExpiryBannerState
    extends ConsumerState<CredentialExpiryBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final asyncCreds = ref.watch(credentialsProvider);
    return asyncCreds.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (creds) {
        final urgent = creds.where(
          (c) =>
              c.status == CredentialStatus.soon ||
              c.status == CredentialStatus.overdue,
        );
        if (urgent.isEmpty) return const SizedBox.shrink();

        final first = urgent.first;
        final label = DrivingCredential.labelFor(first.docType);
        final days = first.daysUntilExpiry;
        final isOverdue = first.status == CredentialStatus.overdue;

        final String subtitle;
        if (isOverdue) {
          subtitle = 'Expired — update your credentials';
        } else if (days != null) {
          subtitle = 'Expires in $days day${days == 1 ? '' : 's'}';
        } else {
          subtitle = 'Expiring soon';
        }

        final Color bgColor = isOverdue
            ? const Color(0xFFFFF0F0)
            : AppColors.photoUploadTint;
        final Color borderColor = isOverdue
            ? const Color(0xFFFFCDD2)
            : AppColors.warning.withValues(alpha: 0.30);
        final Color iconColor = isOverdue ? AppColors.danger : AppColors.warning;
        final Color titleColor = isOverdue ? AppColors.danger : AppColors.textPrimary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
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
        );
      },
    );
  }
}
