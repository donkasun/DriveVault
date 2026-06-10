import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'cloudinary_result.dart';

class UploadRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  UploadRepository(this._apiClient, {Dio? dio}) : _dio = dio ?? Dio();

  Future<CloudinaryResult> uploadFile(Uint8List bytes, String folder) async {
    final sigData = await _apiClient.post(
      '/uploads/cloudinary-signature',
      body: {'folder': folder},
    );

    final signature = sigData['signature'] as String;
    final timestamp = sigData['timestamp'];
    final apiKey = sigData['apiKey'] as String;
    final cloudName = sigData['cloudName'] as String;
    final sigFolder = sigData['folder'] as String;

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: 'upload'),
      'api_key': apiKey,
      'timestamp': timestamp.toString(),
      'signature': signature,
      'folder': sigFolder,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      data: formData,
    );

    if (response.data == null) {
      throw Exception('Empty Cloudinary upload response');
    }

    final data = response.data!;
    return CloudinaryResult(
      secureUrl: data['secure_url'] as String,
      publicId: data['public_id'] as String,
    );
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepository(ref.watch(apiClientProvider)),
);
