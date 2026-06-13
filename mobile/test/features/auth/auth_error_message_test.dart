import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/auth/presentation/auth_error_message.dart';

FirebaseAuthException _exc(String code) =>
    FirebaseAuthException(code: code, message: 'test');

void main() {
  group('authErrorMessage', () {
    test('wrong-password → incorrect email or password', () {
      expect(
        authErrorMessage(_exc('wrong-password')),
        'Incorrect email or password',
      );
    });

    test('invalid-credential → incorrect email or password', () {
      expect(
        authErrorMessage(_exc('invalid-credential')),
        'Incorrect email or password',
      );
    });

    test('user-not-found → incorrect email or password', () {
      expect(
        authErrorMessage(_exc('user-not-found')),
        'Incorrect email or password',
      );
    });

    test('email-already-in-use', () {
      expect(
        authErrorMessage(_exc('email-already-in-use')),
        'An account already exists with this email',
      );
    });

    test('invalid-email', () {
      expect(
        authErrorMessage(_exc('invalid-email')),
        'Enter a valid email address',
      );
    });

    test('weak-password', () {
      expect(
        authErrorMessage(_exc('weak-password')),
        'Password must be at least 6 characters',
      );
    });

    test('too-many-requests', () {
      expect(
        authErrorMessage(_exc('too-many-requests')),
        'Too many attempts. Try again later',
      );
    });

    test('network-request-failed', () {
      expect(
        authErrorMessage(_exc('network-request-failed')),
        'No internet connection',
      );
    });

    test('unknown FirebaseAuthException code → generic message', () {
      expect(
        authErrorMessage(_exc('some-unknown-code')),
        'Something went wrong. Please try again',
      );
    });

    test('non-FirebaseAuthException → generic message', () {
      expect(
        authErrorMessage(Exception('network error')),
        'Something went wrong. Please try again',
      );
    });

    test('plain Exception → generic message', () {
      expect(
        authErrorMessage(StateError('oops')),
        'Something went wrong. Please try again',
      );
    });
  });
}
