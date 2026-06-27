import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/bottom_sheet_picker_field.dart';
import '../../../shared/widgets/form_screen_app_bar.dart';
import '../data/driving_credential_repository.dart';
import '../domain/driving_credential.dart';

const _kTextPrimary = Color(0xFF13121C);
const _kTextMuted = Color(0xFF73738A);

class DrivingCredentialFormScreen extends ConsumerStatefulWidget {
  final DrivingCredential? existing;

  const DrivingCredentialFormScreen({super.key, this.existing});

  @override
  ConsumerState<DrivingCredentialFormScreen> createState() =>
      _DrivingCredentialFormScreenState();
}

class _DrivingCredentialFormScreenState
    extends ConsumerState<DrivingCredentialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNumberCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _docType = 'license';
  bool _saving = false;

  static const _docTypes = ['license', 'permit', 'international_license'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _docType = e.docType;
      _docNumberCtrl.text = e.docNumber ?? '';
      _issueDateCtrl.text = e.issueDate ?? '';
      _expiryDateCtrl.text = e.expiryDate ?? '';
      _notesCtrl.text = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _docNumberCtrl.dispose();
    _issueDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null && mounted) {
      setState(() {
        ctrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}'
            '-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _delete() async {
    final cred = widget.existing!;
    final label = DrivingCredential.labelFor(cred.docType);
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
                'Delete "$label"?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This cannot be undone.',
                style: TextStyle(color: _kTextMuted),
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
    if (confirm != true || !mounted) return;
    try {
      await ref.read(drivingCredentialRepositoryProvider).delete(cred.id);
      ref.invalidate(credentialsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(drivingCredentialRepositoryProvider);
      final body = <String, dynamic>{
        'docType': _docType!,
        if (_docNumberCtrl.text.isNotEmpty)
          'docNumber': _docNumberCtrl.text.trim(),
        if (_issueDateCtrl.text.isNotEmpty) 'issueDate': _issueDateCtrl.text,
        if (_expiryDateCtrl.text.isNotEmpty)
          'expiryDate': _expiryDateCtrl.text,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };
      if (widget.existing != null) {
        await repo.update(widget.existing!.id, body);
      } else {
        await repo.create(body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: FormScreenAppBar(
        title: isEdit ? 'Edit Credential' : 'Add Credential',
        saving: _saving,
        onSave: _save,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BottomSheetPickerField<String>(
              label: 'Document Type *',
              sheetTitle: 'Select credential type',
              value: _docType,
              options: _docTypes,
              labelBuilder: DrivingCredential.labelFor,
              onChanged: (v) => setState(() => _docType = v),
              validator: (v) => v == null ? 'Please select a type' : null,
              enabled: widget.existing == null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _docNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Document Number',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _issueDateCtrl,
              readOnly: true,
              onTap: () => _pickDate(_issueDateCtrl),
              decoration: const InputDecoration(
                labelText: 'Issue Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expiryDateCtrl,
              readOnly: true,
              onTap: () => _pickDate(_expiryDateCtrl),
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            if (_expiryDateCtrl.text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Add an expiry date to receive renewal reminders.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A9AAF)),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
              ),
            ),
            if (isEdit) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Credential'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
