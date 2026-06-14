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
    test('fromJson maps currency, distanceUnit, and reminders toggle', () {
      final u = AppUser.fromJson(
        baseJson()..addAll({
          'currency': 'EUR',
          'distanceUnit': 'mi',
          'renewalRemindersEnabled': false,
        }),
      );

      expect(u.currency, 'EUR');
      expect(u.distanceUnit, 'mi');
      expect(u.renewalRemindersEnabled, isFalse);
    });

    test('defaults to USD / km / true when fields are absent', () {
      final u = AppUser.fromJson(baseJson());
      expect(u.currency, 'USD');
      expect(u.distanceUnit, 'km');
      expect(u.renewalRemindersEnabled, isTrue);
    });
  });
}
