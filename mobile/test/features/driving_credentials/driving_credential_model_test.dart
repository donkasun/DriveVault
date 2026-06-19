import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/driving_credentials/domain/driving_credential.dart';

void main() {
  Map<String, dynamic> baseJson() => {
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

  group('DrivingCredential.fromJson', () {
    test('parses all fields correctly', () {
      final cred = DrivingCredential.fromJson(baseJson());

      expect(cred.id, 'cred-001');
      expect(cred.docType, 'license');
      expect(cred.docNumber, 'B1234567');
      expect(cred.issueDate, '2020-03-01');
      expect(cred.expiryDate, '2028-03-01');
      expect(cred.notes, isNull);
      expect(cred.status, CredentialStatus.ok);
      expect(cred.daysUntilExpiry, 614);
      expect(cred.createdAt, DateTime.parse('2026-06-19T10:00:00Z'));
      expect(cred.updatedAt, DateTime.parse('2026-06-19T10:00:00Z'));
    });

    test('parses status=soon correctly', () {
      final json = baseJson()..['status'] = 'soon';
      final cred = DrivingCredential.fromJson(json);
      expect(cred.status, CredentialStatus.soon);
    });

    test('parses status=overdue correctly', () {
      final json = baseJson()..['status'] = 'overdue';
      final cred = DrivingCredential.fromJson(json);
      expect(cred.status, CredentialStatus.overdue);
    });

    test('parses null status as null', () {
      final json = baseJson()..['status'] = null;
      final cred = DrivingCredential.fromJson(json);
      expect(cred.status, isNull);
    });

    test('tolerates missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'cred-002',
        'docType': 'permit',
        'createdAt': '2026-06-19T10:00:00Z',
        'updatedAt': '2026-06-19T10:00:00Z',
      };
      final cred = DrivingCredential.fromJson(json);
      expect(cred.docNumber, isNull);
      expect(cred.issueDate, isNull);
      expect(cred.expiryDate, isNull);
      expect(cred.notes, isNull);
      expect(cred.status, isNull);
      expect(cred.daysUntilExpiry, isNull);
    });

    test('parses international_license docType', () {
      final json = baseJson()..['docType'] = 'international_license';
      final cred = DrivingCredential.fromJson(json);
      expect(cred.docType, 'international_license');
    });
  });

  group('DrivingCredential.labelFor', () {
    test('returns correct label for license', () {
      expect(DrivingCredential.labelFor('license'), "Driver's License");
    });

    test('returns correct label for permit', () {
      expect(DrivingCredential.labelFor('permit'), 'Driving Permit');
    });

    test('returns correct label for international_license', () {
      expect(
        DrivingCredential.labelFor('international_license'),
        'International Driving License',
      );
    });

    test('falls back to raw docType for unknown values', () {
      expect(DrivingCredential.labelFor('unknown_type'), 'unknown_type');
    });
  });
}
