import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/documents/domain/document.dart';

void main() {
  group('Document.fromJson', () {
    final fullJson = {
      'id': 'doc-1',
      'vehicleId': 'v-1',
      'docType': 'insurance',
      'title': '2026 Insurance Policy',
      'storageUrl': 'https://res.cloudinary.com/example/doc.pdf',
      'storagePublicId': 'vehicles/v-1/doc',
      'mimeType': 'application/pdf',
      'fileSizeBytes': 482000,
      'issueDate': '2026-01-01',
      'expiryDate': '2026-12-31',
      'createdAt': '2026-01-01T08:00:00Z',
    };

    test('maps all fields', () {
      final doc = Document.fromJson(fullJson);
      expect(doc.id, 'doc-1');
      expect(doc.vehicleId, 'v-1');
      expect(doc.docType, 'insurance');
      expect(doc.title, '2026 Insurance Policy');
      expect(doc.storageUrl, 'https://res.cloudinary.com/example/doc.pdf');
      expect(doc.storagePublicId, 'vehicles/v-1/doc');
      expect(doc.mimeType, 'application/pdf');
      expect(doc.fileSizeBytes, 482000);
      expect(doc.issueDate, '2026-01-01');
      expect(doc.expiryDate, '2026-12-31');
      expect(doc.createdAt, DateTime.parse('2026-01-01T08:00:00Z'));
    });

    test('handles minimal required fields', () {
      final json = {
        'id': 'doc-2',
        'vehicleId': 'v-1',
        'docType': 'registration',
        'title': 'Car Registration',
        'storageUrl': 'https://example.com/file.jpg',
        'createdAt': '2026-01-01T00:00:00Z',
      };
      final doc = Document.fromJson(json);
      expect(doc.storagePublicId, isNull);
      expect(doc.mimeType, isNull);
      expect(doc.expiryDate, isNull);
    });

    test('isImage returns true for image mimeType', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['mimeType'] = 'image/jpeg';
      final doc = Document.fromJson(json);
      expect(doc.isImage, true);
    });

    test('isImage returns false for PDF mimeType', () {
      final doc = Document.fromJson(fullJson);
      expect(doc.isImage, false);
    });

    test('isImage returns false when mimeType is null', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('mimeType');
      final doc = Document.fromJson(json);
      expect(doc.isImage, false);
    });
  });

  group('daysUntilExpiry', () {
    test('returns null when expiryDate is null', () {
      final json = {
        'id': 'doc-3',
        'vehicleId': 'v-1',
        'docType': 'other',
        'title': 'No Expiry',
        'storageUrl': 'https://example.com/f',
        'createdAt': '2026-01-01T00:00:00Z',
      };
      final doc = Document.fromJson(json);
      expect(doc.daysUntilExpiry(), isNull);
    });

    test('returns negative when expired', () {
      final pastDate = DateTime.now()
          .subtract(const Duration(days: 10));
      final json = {
        'id': 'doc-4',
        'vehicleId': 'v-1',
        'docType': 'insurance',
        'title': 'Old Policy',
        'storageUrl': 'https://example.com/f',
        'expiryDate':
            '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}'
            '-${pastDate.day.toString().padLeft(2, '0')}',
        'createdAt': '2026-01-01T00:00:00Z',
      };
      final doc = Document.fromJson(json);
      expect(doc.daysUntilExpiry()!, isNegative);
    });

    test('returns positive when future expiry', () {
      final futureDate = DateTime.now().add(const Duration(days: 90));
      final json = {
        'id': 'doc-5',
        'vehicleId': 'v-1',
        'docType': 'insurance',
        'title': 'Valid Policy',
        'storageUrl': 'https://example.com/f',
        'expiryDate':
            '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}'
            '-${futureDate.day.toString().padLeft(2, '0')}',
        'createdAt': '2026-01-01T00:00:00Z',
      };
      final doc = Document.fromJson(json);
      expect(doc.daysUntilExpiry()!, isPositive);
    });
  });

  group('groupDocumentsByType', () {
    Document makeDoc(String id, String type) => Document(
          id: id,
          vehicleId: 'v-1',
          docType: type,
          title: 'Title $id',
          storageUrl: 'https://example.com/$id',
          createdAt: DateTime(2026, 1, 1),
        );

    test('groups documents by docType', () {
      final docs = [
        makeDoc('d1', 'insurance'),
        makeDoc('d2', 'registration'),
        makeDoc('d3', 'insurance'),
      ];
      final grouped = groupDocumentsByType(docs);
      expect(grouped.keys, containsAll(['insurance', 'registration']));
      expect(grouped['insurance']!.length, 2);
      expect(grouped['registration']!.length, 1);
    });

    test('returns empty map for empty list', () {
      expect(groupDocumentsByType([]), isEmpty);
    });

    test('each group preserves order', () {
      final docs = [
        makeDoc('d1', 'insurance'),
        makeDoc('d2', 'insurance'),
        makeDoc('d3', 'insurance'),
      ];
      final grouped = groupDocumentsByType(docs);
      final ids =
          grouped['insurance']!.map((d) => d.id).toList();
      expect(ids, ['d1', 'd2', 'd3']);
    });
  });
}
