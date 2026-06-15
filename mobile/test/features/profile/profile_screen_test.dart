import 'dart:async';

import 'package:drivevault/core/config/app_config.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/profile/presentation/edit_profile_screen.dart';
import 'package:drivevault/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeUser extends Fake implements User {
  final String _email;
  final bool _verified;

  FakeUser({String email = 'test@example.com', bool emailVerified = false})
    : _email = email,
      _verified = emailVerified;

  @override
  String get email => _email;

  @override
  String get displayName => 'Test User';

  @override
  String get uid => 'test-uid';

  @override
  bool get emailVerified => _verified;

  @override
  List<UserInfo> get providerData => [];
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.user);

  AppUser user;
  bool? lastRenewalRemindersEnabled;
  String? lastDistanceUnit;
  Completer<AppUser>? pendingPreferenceUpdate;
  AppUser? pendingPreferenceResponse;

  /// When set, the next [updatePreferences] call throws this error.
  Object? nextUpdateError;

  @override
  Future<AppUser> getMe() async => user;

  @override
  Future<AppUser> updatePreferences({
    String? currency,
    String? distanceUnit,
    bool? renewalRemindersEnabled,
  }) async {
    lastRenewalRemindersEnabled = renewalRemindersEnabled;
    lastDistanceUnit = distanceUnit;

    if (nextUpdateError != null) {
      final err = nextUpdateError!;
      nextUpdateError = null;
      throw err;
    }

    final updatedUser = AppUser(
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      currency: currency ?? user.currency,
      distanceUnit: distanceUnit ?? user.distanceUnit,
      renewalRemindersEnabled:
          renewalRemindersEnabled ?? user.renewalRemindersEnabled,
      createdAt: user.createdAt,
    );
    pendingPreferenceResponse = updatedUser;
    if (pendingPreferenceUpdate != null) {
      return pendingPreferenceUpdate!.future;
    }
    user = updatedUser;
    return user;
  }

  @override
  Future<AppUser> updateProfile({String? displayName}) async {
    user = AppUser(
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      displayName: displayName,
      photoUrl: user.photoUrl,
      currency: user.currency,
      distanceUnit: user.distanceUnit,
      renewalRemindersEnabled: user.renewalRemindersEnabled,
      createdAt: user.createdAt,
    );
    return user;
  }

  void completePendingPreferenceUpdate() {
    final completer = pendingPreferenceUpdate;
    final response = pendingPreferenceResponse;
    if (completer == null || response == null || completer.isCompleted) return;
    user = response;
    completer.complete(response);
    pendingPreferenceUpdate = null;
    pendingPreferenceResponse = null;
  }

  void failPendingPreferenceUpdate(Object error) {
    final completer = pendingPreferenceUpdate;
    if (completer == null || completer.isCompleted) return;
    completer.completeError(error);
    pendingPreferenceUpdate = null;
    pendingPreferenceResponse = null;
  }
}

/// Minimal routed app that stubs Firebase auth so that
/// [authStateChangesProvider] never attempts to reach a real Firebase instance.
Widget _buildTestApp({
  required _FakeUserRepository repo,
  required AppUser user,
}) {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      meProvider.overrideWith((_) async => user),
      userRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(
        AuthRepository.testing(currentUser: null),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows settings card and opens edit profile', (tester) async {
    final authUser = FakeUser(emailVerified: false);
    final user = AppUser(
      id: 'u-1',
      firebaseUid: 'fb-1',
      email: 'crtest083@gmail.com',
      displayName: 'Tharindu',
      currency: 'LKR',
      distanceUnit: 'km',
      renewalRemindersEnabled: true,
      createdAt: DateTime(2026, 1, 1),
    );
    final repo = _FakeUserRepository(user);
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((_) async => user),
          authRepositoryProvider.overrideWithValue(
            AuthRepository.testing(currentUser: authUser),
          ),
          userRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Tharindu'), findsOneWidget);
    expect(find.text('crtest083@gmail.com'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text(AppConfig.appVersion), findsOneWidget);

    await tester.tap(find.text('Tharindu'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('crtest083@gmail.com'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
  });

  testWidgets('optimistically updates distance and reminders', (tester) async {
    final user = AppUser(
      id: 'u-1',
      firebaseUid: 'fb-1',
      email: 'me@example.com',
      currency: 'LKR',
      distanceUnit: 'km',
      renewalRemindersEnabled: true,
      createdAt: DateTime(2026, 1, 1),
    );
    final repo = _FakeUserRepository(user);

    await tester.pumpWidget(_buildTestApp(repo: repo, user: user));

    await tester.pumpAndSettle();

    // _SectionLabel uppercases its text, so check for 'PREFERENCES' not 'Preferences'.
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('Distance unit'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Renewal reminders'), findsOneWidget);
    expect(find.text(AppConfig.appVersion), findsOneWidget);

    repo.pendingPreferenceUpdate = Completer<AppUser>();
    await tester.tap(find.text('Miles'));
    await tester.pump();

    final milesStyle = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Miles'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(milesStyle.style.color, Colors.white);
    expect(repo.lastDistanceUnit, 'mi');

    repo.completePendingPreferenceUpdate();
    await tester.pumpAndSettle();

    repo.pendingPreferenceUpdate = Completer<AppUser>();
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(repo.lastRenewalRemindersEnabled, isFalse);

    repo.completePendingPreferenceUpdate();
    await tester.pumpAndSettle();
  });

  testWidgets('reminders switch is disabled while a PATCH is in flight', (
    tester,
  ) async {
    final user = AppUser(
      id: 'u-1',
      firebaseUid: 'fb-1',
      email: 'me@example.com',
      currency: 'LKR',
      distanceUnit: 'km',
      renewalRemindersEnabled: true,
      createdAt: DateTime(2026, 1, 1),
    );
    final repo = _FakeUserRepository(user);

    await tester.pumpWidget(_buildTestApp(repo: repo, user: user));
    await tester.pumpAndSettle();

    // Switch starts enabled (saving == false).
    expect(
      tester.widget<Switch>(find.byType(Switch)).onChanged,
      isNotNull,
      reason: 'Switch must be enabled before any request is in flight',
    );

    // Start an in-flight update.
    repo.pendingPreferenceUpdate = Completer<AppUser>();
    await tester.tap(find.byType(Switch));
    await tester.pump();

    // While in-flight, onChanged must be null (disabled).
    expect(
      tester.widget<Switch>(find.byType(Switch)).onChanged,
      isNull,
      reason: 'Switch must be disabled while a PATCH request is in flight',
    );

    // Complete the update and confirm enabled again.
    repo.completePendingPreferenceUpdate();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Switch>(find.byType(Switch)).onChanged,
      isNotNull,
      reason: 'Switch must be re-enabled after the request completes',
    );
  });

  testWidgets('reminders toggle rolls back and shows SnackBar on PATCH error', (
    tester,
  ) async {
    final user = AppUser(
      id: 'u-1',
      firebaseUid: 'fb-1',
      email: 'me@example.com',
      currency: 'LKR',
      distanceUnit: 'km',
      renewalRemindersEnabled: true,
      createdAt: DateTime(2026, 1, 1),
    );
    final repo = _FakeUserRepository(user);

    // MaterialApp provides a ScaffoldMessenger above the ProfileScreen's
    // Scaffold so SnackBars are hosted at the right level.
    await tester.pumpWidget(_buildTestApp(repo: repo, user: user));
    await tester.pumpAndSettle();

    // Initial value: true.
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    // Make the next PATCH throw.
    repo.pendingPreferenceUpdate = Completer<AppUser>();
    await tester.tap(find.byType(Switch));
    await tester.pump();

    // Optimistic update: switch shows false immediately.
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    // Fail the request.
    repo.failPendingPreferenceUpdate(Exception('network error'));
    await tester.pumpAndSettle();

    // After failure: value reverts to true.
    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isTrue,
      reason: 'Switch must revert to previous value on error',
    );

    // SnackBar with error message must be visible.
    expect(
      find.textContaining('Could not save preference'),
      findsOneWidget,
      reason: 'SnackBar must appear with error message on PATCH failure',
    );
  });

  testWidgets(
    'currency row is static — no picker control, just a locked label',
    (tester) async {
      final user = AppUser(
        id: 'u-1',
        firebaseUid: 'fb-1',
        email: 'me@example.com',
        currency: 'LKR',
        distanceUnit: 'km',
        renewalRemindersEnabled: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final repo = _FakeUserRepository(user);

      await tester.pumpWidget(_buildTestApp(repo: repo, user: user));
      await tester.pumpAndSettle();

      // Currency label is displayed as plain text — not inside an interactive
      // picker widget (no DropdownButton, no GestureDetector wrapping a picker).
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Locked for this account'), findsOneWidget);

      // Lock icon should be present (visual indicator of non-interactivity).
      expect(
        find.byIcon(Icons.lock_outline_rounded),
        findsOneWidget,
        reason: 'Lock icon must be visible beside the static currency value',
      );

      // No DropdownButton or interactive bottom-sheet picker.
      expect(
        find.byType(DropdownButton<String>),
        findsNothing,
        reason: 'Currency must not offer any dropdown picker',
      );

      // Tapping the currency row must NOT push any route or open a picker;
      // repo should see zero preference updates.
      await tester.tap(find.text('Currency'), warnIfMissed: false);
      await tester.pump();

      expect(
        repo.lastDistanceUnit,
        isNull,
        reason: 'Tapping the static currency row must not trigger any PATCH',
      );
      expect(
        repo.lastRenewalRemindersEnabled,
        isNull,
        reason: 'Tapping the static currency row must not trigger any PATCH',
      );
    },
  );
}
