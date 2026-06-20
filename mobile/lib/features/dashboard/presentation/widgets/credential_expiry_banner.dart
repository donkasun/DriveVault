import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        final urgent = creds
            .where(
              (c) =>
                  c.status == CredentialStatus.soon ||
                  c.status == CredentialStatus.overdue,
            )
            .toList();
        if (urgent.isEmpty) return const SizedBox.shrink();

        final first = urgent.first;
        final label = DrivingCredential.labelFor(first.docType);
        final body = first.status == CredentialStatus.overdue
            ? '$label has expired.'
            : '$label expires in ${first.daysUntilExpiry} day(s).';

        final isOverdue = first.status == CredentialStatus.overdue;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: isOverdue
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFFFF8E6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOverdue
                  ? const Color(0xFFFFCDD2)
                  : const Color(0xFFFFE082),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: isOverdue ? Colors.red : const Color(0xFFF08A00),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverdue
                        ? Colors.red[800]
                        : const Color(0xFFC96A00),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFF9A9AAF),
                onPressed: () => setState(() => _dismissed = true),
              ),
            ],
          ),
        );
      },
    );
  }
}
