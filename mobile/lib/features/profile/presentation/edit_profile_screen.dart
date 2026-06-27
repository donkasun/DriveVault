import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/form_screen_app_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../data/user_repository.dart';

/// Full-screen dialog to edit the user's display name.
/// Route: /profile/edit  (fullscreenDialog: true)
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(meProvider).asData?.value;
    _displayNameCtrl = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(displayName: _displayNameCtrl.text.trim());
      ref.invalidate(meProvider);
      // Wait for meProvider to resolve before popping so the profile screen
      // reflects the new name immediately.
      await ref.read(meProvider.future);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(meProvider).requireValue;
    final User? authUser = ref.watch(authStateChangesProvider).asData?.value;
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : '';
    final emailVerified = authUser?.emailVerified ?? true;
    final isGoogleUser = authUser?.providerData.any(
          (p) => p.providerId == 'google.com',
        ) ??
        false;

    return Scaffold(
      appBar: FormScreenAppBar(
        title: 'Edit Profile',
        saving: _saving,
        cancelEnabled: !_saving,
        onCancel: () => context.pop(),
        onSave: _save,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primary,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2030),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Display name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _displayNameCtrl,
              enabled: !isGoogleUser,
              decoration: InputDecoration(
                hintText: 'Your name',
                filled: true,
                fillColor: isGoogleUser
                    ? const Color(0xFFF4F4F8)
                    : Colors.white,
                helperText: isGoogleUser ? 'Synced from Google' : null,
                helperStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9A9AAF),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: Color(0xFFE6E7EF)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: Color(0xFFE6E7EF)),
                ),
                disabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: Color(0xFFE6E7EF)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (v) {
                if (!isGoogleUser && (v == null || v.trim().isEmpty)) {
                  return 'Display name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Email'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6E7EF)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!emailVerified) const _UnverifiedBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Color(0xFF9A9AAF),
      ),
    );
  }
}

class _UnverifiedBadge extends StatelessWidget {
  const _UnverifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
