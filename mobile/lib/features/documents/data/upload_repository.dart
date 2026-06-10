import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'cloudinary_result.dart';

class UploadRepository {
  final ApiClient _apiClient;

  UploadRepository(this._apiClient);

  Future<CloudinaryResult> uploadFile(
      Uint8List bytes, String folder) async {
    // Step 1: Get Cloudinary signature from backend
    final sigData = await _apiClient.post(
      '/uploads/cloudinary-signature',
      body: {'folder': folder},
    );

    final signature = sigData['signature'] as String;
    final timestamp = sigData['timestamp'];
    final apiKey = sigData['apiKey'] as String;
    final cloudName = sigData['cloudName'] as String;
    final sigFolder = sigData['folder'] as String;

    // Step 2: Upload directly to Cloudinary
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: 'upload'),
      'api_key': apiKey,
      'timestamp': timestamp.toString(),
      'signature': signature,
      'folder': sigFolder,
    });

    final dio = Dio();
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      data: formData,
    );

    final responseData = response.data!;
    return CloudinaryResult(
      secureUrl: responseData['secure_url'] as String,
      publicId: responseData['public_id'] as String,
    );
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepository(ref.watch(apiClientProvider)),
);
