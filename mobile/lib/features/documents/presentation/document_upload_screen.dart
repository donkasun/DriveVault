import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/bottom_sheet_picker_field.dart';
import '../../../shared/widgets/form_screen_app_bar.dart';
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

  /// Tracks the last auto-suggested title so we can detect user edits.
  String? _lastAutoSuggestedTitle;

  static const _docTypes = ['insurance', 'registration', 'service', 'other'];

  @override
  void initState() {
    super.initState();
    // Apply initial auto-suggestion for the default doc type.
    _applyDocTypeSuggestion(_docType);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _issueDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  /// Capitalises [docType] and sets it as the title if the title is empty or
  /// still equals the last auto-suggestion (i.e. user hasn't typed their own).
  void _applyDocTypeSuggestion(String? docType) {
    if (docType == null) return;
    final suggestion =
        docType[0].toUpperCase() + docType.substring(1);
    final current = _titleCtrl.text;
    if (current.isEmpty || current == _lastAutoSuggestedTitle) {
      _titleCtrl.text = suggestion;
      _lastAutoSuggestedTitle = suggestion;
    }
  }

  Future<void> _pickFile() async {
    final choice = await showModalBottomSheet<_FileSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(_FileSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.of(ctx).pop(_FileSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Browse files'),
              onTap: () => Navigator.of(ctx).pop(_FileSource.browse),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    switch (choice) {
      case _FileSource.camera:
        final picker = ImagePicker();
        final result = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (result == null) return;
        final bytes = await result.readAsBytes();
        setState(() {
          _fileBytes = bytes;
          _fileName = result.name;
          _mimeType = result.mimeType ?? 'image/jpeg';
        });

      case _FileSource.gallery:
        final picker = ImagePicker();
        final result = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (result == null) return;
        final bytes = await result.readAsBytes();
        setState(() {
          _fileBytes = bytes;
          _fileName = result.name;
          _mimeType = result.mimeType ?? 'image/jpeg';
        });

      case _FileSource.browse:
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        if (file.bytes == null) return;
        final ext = (file.extension ?? '').toLowerCase();
        final mime = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
        setState(() {
          _fileBytes = file.bytes;
          _fileName = file.name;
          _mimeType = mime;
        });
    }
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
      appBar: FormScreenAppBar(
        title: 'Add Document',
        saving: _uploading,
        onSave: _upload,
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
              onChanged: (v) {
                setState(() => _docType = v);
                _applyDocTypeSuggestion(v);
              },
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

/// Source options shown in the file-picker bottom sheet.
enum _FileSource { camera, gallery, browse }
