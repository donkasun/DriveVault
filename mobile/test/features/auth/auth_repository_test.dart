import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    test('exposes authStateChanges stream from FirebaseAuth', () {
      final repository = AuthRepository.testing();
      expect(repository.authStateChanges, isA<Stream>());
    });

    test('currentUser is null when not signed in', () {
      final repository = AuthRepository.testing();
      // Without a live Firebase session in unit tests, current user is null.
      expect(repository.currentUser, isNull);
    });
  });

  group('email verification methods', () {
    test('sendEmailVerification is a no-op when there is no current user', () async {
      final repo = AuthRepository.testing(currentUser: null);
      await expectLater(repo.sendEmailVerification(), completes);
    });

    test('reloadUser is a no-op when there is no current user', () async {
      final repo = AuthRepository.testing(currentUser: null);
      await expectLater(repo.reloadUser(), completes);
    });
  });
}
