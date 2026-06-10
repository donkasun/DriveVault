import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/cloudinary_upload_result.dart';

class UploadRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  UploadRepository(this._apiClient, {Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches a Cloudinary signature from the backend, then uploads [bytes]
  /// directly to Cloudinary. Returns the upload result with [secureUrl] and
  /// [publicId].
  Future<CloudinaryUploadResult> uploadFile(
    Uint8List bytes,
    String folder, {
    String filename = 'upload',
    void Function(int sent, int total)? onProgress,
  }) async {
    // 1. Fetch upload signature from backend
    final sigData = await _apiClient.post(
      '/uploads/cloudinary-signature',
      body: {'folder': folder},
    );

    final signature = sigData['signature'] as String;
    final timestamp = sigData['timestamp'] as int;
    final apiKey = sigData['apiKey'] as String;
    final cloudName = sigData['cloudName'] as String;
    final sigFolder = sigData['folder'] as String;

    // 2. Upload directly to Cloudinary
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': apiKey,
      'timestamp': timestamp.toString(),
      'signature': signature,
      'folder': sigFolder,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    if (response.data == null) {
      throw Exception('Empty Cloudinary upload response');
    }

    return CloudinaryUploadResult.fromJson(response.data!);
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(apiClientProvider));
});
