import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/form_screen_app_bar.dart';
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
      await ref.read(userRepositoryProvider).updateProfile(
            displayName: _displayNameCtrl.text.trim(),
          );
      ref.invalidate(meProvider);
      // Wait for meProvider to resolve before popping so the profile screen
      // reflects the new name immediately.
      await ref.read(meProvider.future);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Your name',
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Display name cannot be empty';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
