import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/document.dart';

class DocumentRepository {
  final ApiClient _apiClient;

  DocumentRepository(this._apiClient);

  Future<List<Document>> fetchDocuments(String vehicleId) async {
    final list =
        await _apiClient.getList('/vehicles/$vehicleId/documents');
    return list.map(Document.fromJson).toList();
  }

  Future<Document> createDocument(
      String vehicleId, Map<String, dynamic> data) async {
    final json = await _apiClient.post(
      '/vehicles/$vehicleId/documents',
      body: data,
    );
    return Document.fromJson(json);
  }

  Future<void> deleteDocument(String id) async {
    await _apiClient.delete('/documents/$id');
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(ref.watch(apiClientProvider)),
);

final documentsProvider =
    FutureProvider.family<List<Document>, String>((ref, vehicleId) async {
  ref.keepAlive();
  final repo = ref.watch(documentRepositoryProvider);
  return repo.fetchDocuments(vehicleId);
});

final groupedDocumentsProvider = FutureProvider.family<
    Map<String, List<Document>>, String>((ref, vehicleId) async {
  ref.keepAlive();
  final docs = await ref.watch(documentsProvider(vehicleId).future);
  return groupDocumentsByType(docs);
});
