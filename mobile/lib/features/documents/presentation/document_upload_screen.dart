import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bottom_sheet_picker_field.dart';
import '../data/document_repository.dart';
import '../data/upload_repository.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const DocumentUploadScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  String? _docType = 'insurance';
  Uint8List? _fileBytes;
  String? _fileName;
  String? _mimeType;
  bool _uploading = false;

  static const _docTypes = ['insurance', 'registration', 'service', 'other'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _issueDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    setState(() {
      _fileBytes = bytes;
      _fileName = result.name;
      _mimeType = result.mimeType ?? 'image/jpeg';
    });
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}'
          '-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() => _uploading = true);
    try {
      final folder = 'vehicles/${widget.vehicleId}/documents';
      final uploadRepo = ref.read(uploadRepositoryProvider);
      final result = await uploadRepo.uploadFile(_fileBytes!, folder);

      final docRepo = ref.read(documentRepositoryProvider);
      await docRepo.createDocument(widget.vehicleId, {
        'docType': _docType!,
        'title': _titleCtrl.text.trim(),
        'storageUrl': result.secureUrl,
        'storagePublicId': result.publicId,
        if (_mimeType != null) 'mimeType': _mimeType,
        if (_fileBytes != null) 'fileSizeBytes': _fileBytes!.length,
        if (_issueDateCtrl.text.isNotEmpty) 'issueDate': _issueDateCtrl.text,
        if (_expiryDateCtrl.text.isNotEmpty) 'expiryDate': _expiryDateCtrl.text,
      });

      ref.invalidate(documentsProvider(widget.vehicleId));
      ref.invalidate(groupedDocumentsProvider(widget.vehicleId));

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 80,
        title: const Text('Add Document'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          child: const Text('Cancel', maxLines: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _uploading
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _upload,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // File picker
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(_fileName ?? 'Select File'),
              onPressed: _pickFile,
            ),
            const SizedBox(height: 16),
            // Doc type picker
            BottomSheetPickerField<String>(
              label: 'Document Type *',
              sheetTitle: 'Select document type',
              value: _docType,
              options: _docTypes,
              labelBuilder: (t) => t[0].toUpperCase() + t.substring(1),
              onChanged: (v) => setState(() => _docType = v),
              validator: (v) =>
                  v == null ? 'Please select a document type' : null,
            ),
            const SizedBox(height: 16),
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            // Issue date
            TextFormField(
              controller: _issueDateCtrl,
              readOnly: true,
              onTap: () => _pickDate(_issueDateCtrl),
              decoration: const InputDecoration(
                labelText: 'Issue Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            // Expiry date
            TextFormField(
              controller: _expiryDateCtrl,
              readOnly: true,
              onTap: () => _pickDate(_expiryDateCtrl),
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
