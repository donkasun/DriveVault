import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/driving_credential.dart';

class DrivingCredentialRepository {
  final ApiClient _client;

  DrivingCredentialRepository(this._client);

  Future<List<DrivingCredential>> fetchAll() async {
    final list = await _client.getList('/me/driving-credentials');
    return list.map(DrivingCredential.fromJson).toList();
  }

  Future<DrivingCredential> create(Map<String, dynamic> body) async {
    final json = await _client.post('/me/driving-credentials', body: body);
    return DrivingCredential.fromJson(json);
  }

  Future<DrivingCredential> update(String id, Map<String, dynamic> body) async {
    final json =
        await _client.patch('/me/driving-credentials/$id', body: body);
    return DrivingCredential.fromJson(json);
  }

  Future<void> delete(String id) async {
    await _client.delete('/me/driving-credentials/$id');
  }
}

final drivingCredentialRepositoryProvider =
    Provider<DrivingCredentialRepository>(
  (ref) => DrivingCredentialRepository(ref.watch(apiClientProvider)),
);

final credentialsProvider =
    FutureProvider<List<DrivingCredential>>((ref) async {
  ref.keepAlive();
  return ref.watch(drivingCredentialRepositoryProvider).fetchAll();
});
