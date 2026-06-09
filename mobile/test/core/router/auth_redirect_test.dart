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
        ),
        isNull,
      );
    });

    test('signed-in user on login goes to home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/login',
          isLoading: false,
          isLoggedIn: true,
        ),
        '/home',
      );
    });

    test('signed-in user on splash goes to home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/splash',
          isLoading: false,
          isLoggedIn: true,
        ),
        '/home',
      );
    });

    test('signed-in user on home stays on home', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/home',
          isLoading: false,
          isLoggedIn: true,
        ),
        isNull,
      );
    });

    test('sign-out scenario: signed-out on profile goes to login', () {
      expect(
        resolveAuthRedirect(
          currentRoute: '/profile',
          isLoading: false,
          isLoggedIn: false,
        ),
        '/login',
      );
    });
  });
}
