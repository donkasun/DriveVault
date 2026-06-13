import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/auth/presentation/widgets/verify_email_banner.dart';

// ---------------------------------------------------------------------------
// Fakes — mimic the pattern in test/widget_test.dart
// ---------------------------------------------------------------------------

class _FakeVerifiedUser extends Fake implements User {
  @override
  bool get emailVerified => true;
  @override
  List<UserInfo> get providerData => [_FakePasswordProvider()];
}

class _FakeUnverifiedPasswordUser extends Fake implements User {
  @override
  bool get emailVerified => false;
  @override
  List<UserInfo> get providerData => [_FakePasswordProvider()];
}

class _FakePasswordProvider extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildBanner({
  required AuthRepository repo,
  bool dismissedOverride = false,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      if (dismissedOverride)
        verifyBannerDismissedProvider.overrideWith(
          () => _AlwaysDismissedNotifier(),
        ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: VerifyEmailBanner(),
      ),
    ),
  );
}

/// A notifier that starts in the dismissed state (true) for override tests.
class _AlwaysDismissedNotifier extends BannerDismissedNotifier {
  @override
  bool build() => true;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('VerifyEmailBanner', () {
    testWidgets(
      'shows banner for unverified password user',
      (WidgetTester tester) async {
        final repo = AuthRepository.testing(
          currentUser: _FakeUnverifiedPasswordUser(),
        );

        await tester.pumpWidget(_buildBanner(repo: repo));
        await tester.pump();

        expect(
          find.text('Verify your email to secure your account.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides banner for verified user',
      (WidgetTester tester) async {
        final repo = AuthRepository.testing(
          currentUser: _FakeVerifiedUser(),
        );

        await tester.pumpWidget(_buildBanner(repo: repo));
        await tester.pump();

        expect(
          find.text('Verify your email to secure your account.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'hides banner when dismissed provider is true (unverified user)',
      (WidgetTester tester) async {
        final repo = AuthRepository.testing(
          currentUser: _FakeUnverifiedPasswordUser(),
        );

        await tester.pumpWidget(
          _buildBanner(repo: repo, dismissedOverride: true),
        );
        await tester.pump();

        expect(
          find.text('Verify your email to secure your account.'),
          findsNothing,
        );
      },
    );
  });
}
