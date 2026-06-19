import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:drivevault/features/driving_credentials/data/driving_credential_repository.dart';
import 'package:drivevault/features/driving_credentials/domain/driving_credential.dart';

import 'driving_credential_repository_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late DrivingCredentialRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = DrivingCredentialRepository(mockApiClient);
  });

  final credentialJson = <String, dynamic>{
    'id': 'cred-001',
    'docType': 'license',
    'docNumber': 'B1234567',
    'issueDate': '2020-03-01',
    'expiryDate': '2028-03-01',
    'notes': null,
    'status': 'ok',
    'daysUntilExpiry': 614,
    'createdAt': '2026-06-19T10:00:00Z',
    'updatedAt': '2026-06-19T10:00:00Z',
  };

  group('fetchAll', () {
    test('maps JSON list to DrivingCredential list', () async {
      when(
        mockApiClient.getList(
          '/me/driving-credentials',
          queryParams: null,
        ),
      ).thenAnswer((_) async => [credentialJson]);

      final creds = await repository.fetchAll();

      expect(creds.length, 1);
      final c = creds.first;
      expect(c.id, 'cred-001');
      expect(c.docType, 'license');
      expect(c.docNumber, 'B1234567');
      expect(c.status, CredentialStatus.ok);
      expect(c.daysUntilExpiry, 614);
    });

    test('returns empty list when API returns empty array', () async {
      when(
        mockApiClient.getList(
          '/me/driving-credentials',
          queryParams: null,
        ),
      ).thenAnswer((_) async => []);

      final creds = await repository.fetchAll();
      expect(creds, isEmpty);
    });
  });

  group('create', () {
    test('posts body and returns DrivingCredential', () async {
      final body = {'docType': 'license', 'docNumber': 'B1234567'};
      when(
        mockApiClient.post('/me/driving-credentials', body: body),
      ).thenAnswer((_) async => credentialJson);

      final cred = await repository.create(body);
      expect(cred.id, 'cred-001');
      expect(cred.docType, 'license');
    });
  });

  group('update', () {
    test('patches credential and returns updated DrivingCredential', () async {
      final patchBody = {'docNumber': 'B9999999'};
      final updatedJson = Map<String, dynamic>.from(credentialJson)
        ..['docNumber'] = 'B9999999';
      when(
        mockApiClient.patch(
          '/me/driving-credentials/cred-001',
          body: patchBody,
        ),
      ).thenAnswer((_) async => updatedJson);

      final cred = await repository.update('cred-001', patchBody);
      expect(cred.docNumber, 'B9999999');
    });
  });

  group('delete', () {
    test('calls delete endpoint', () async {
      when(
        mockApiClient.delete('/me/driving-credentials/cred-001'),
      ).thenAnswer((_) async {});

      await repository.delete('cred-001');
      verify(mockApiClient.delete('/me/driving-credentials/cred-001')).called(1);
    });
  });
}
