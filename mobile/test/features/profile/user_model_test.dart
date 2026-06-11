import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/profile/domain/user.dart';

void main() {
  Map<String, dynamic> baseJson() => {
    'id': 'u-1',
    'firebaseUid': 'fb-1',
    'email': 'me@example.com',
    'displayName': 'Kasun',
    'photoUrl': null,
    'createdAt': '2026-06-08T10:00:00Z',
  };

  group('AppUser preferences (F6)', () {
    test('fromJson maps currency and distanceUnit', () {
      final u = AppUser.fromJson(
        baseJson()..addAll({'currency': 'EUR', 'distanceUnit': 'mi'}),
      );

      expect(u.currency, 'EUR');
      expect(u.distanceUnit, 'mi');
    });

    test('defaults to USD / km when fields are absent', () {
      final u = AppUser.fromJson(baseJson());
      expect(u.currency, 'USD');
      expect(u.distanceUnit, 'km');
    });
  });
}
