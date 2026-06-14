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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((_) async => user),
          userRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Preferences'), findsOneWidget);
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
}
