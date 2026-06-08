import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivevault/main.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

class FakeUser extends Fake implements User {
  @override
  String get email => 'test@example.com';
  @override
  String get displayName => 'Test User';
  @override
  String get uid => 'test-uid';
}

void main() {
  testWidgets('App boots to LoginScreen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const DriveVaultApp(),
      ),
    );
    await tester.pump(); // Start navigation/redirects
    await tester.pumpAndSettle(); // Wait for transitions to finish

    // Should find the Sign In card title and login form elements
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('App boots to DashboardScreen when signed in', (WidgetTester tester) async {
    final fakeUser = FakeUser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(fakeUser)),
        ],
        child: const DriveVaultApp(),
      ),
    );
    await tester.pump(); // Start navigation/redirects
    await tester.pumpAndSettle(); // Wait for transitions to finish

    // Should find the dashboard/home screen text
    expect(find.text('Dashboard coming soon — Phase 1 scaffold.'), findsOneWidget);
  });
}
