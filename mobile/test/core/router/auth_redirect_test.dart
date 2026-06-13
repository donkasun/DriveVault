import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/router/auth_redirect.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('shows splash while auth state is loading', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/login',
          isLoading: true,
          isLoggedIn: false,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        '/splash',
      );
    });

    test('signed-out user on splash goes to login', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/splash',
          isLoading: false,
          isLoggedIn: false,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        '/login',
      );
    });

    test('signed-out user on protected route goes to login', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/home',
          isLoading: false,
          isLoggedIn: false,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        '/login',
      );
    });

    test('signed-out user can stay on auth routes', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/signup',
          isLoading: false,
          isLoggedIn: false,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        isNull,
      );
    });

    test('signed-out user on verify-email goes to login', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/verify-email',
          isLoading: false,
          isLoggedIn: false,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        '/login',
      );
    });

    test('verified password user on login goes to home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/login',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: true,
          isPasswordProvider: true,
        ),
        '/home',
      );
    });

    test('verified password user on home stays on home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/home',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: true,
          isPasswordProvider: true,
        ),
        isNull,
      );
    });

    test('unverified password user on home stays (no gate)', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/home',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: false,
          isPasswordProvider: true,
        ),
        isNull,
      );
    });

    test('unverified password user on splash goes to home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/splash',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: false,
          isPasswordProvider: true,
        ),
        '/home',
      );
    });

    test('unverified password user on verify-email is sent home (no gate)', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/verify-email',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: false,
          isPasswordProvider: true,
        ),
        '/home',
      );
    });

    test('Google user (not password provider) bypasses the gate', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/home',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        isNull,
      );
    });

    test('verified user on verify-email is sent home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/verify-email',
          isLoading: false,
          isLoggedIn: true,
          isEmailVerified: true,
          isPasswordProvider: true,
        ),
        '/home',
      );
    });

    test('sign-out scenario: signed-out on profile goes to login', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/profile',
          isLoading: false,
          isLoggedIn: false,
          isEmailVerified: false,
          isPasswordProvider: false,
        ),
        '/login',
      );
    });
  });
}
