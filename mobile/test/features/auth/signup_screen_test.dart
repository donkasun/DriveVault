import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/auth/presentation/signup_screen.dart';

Widget _buildSignup() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
    ],
    child: const MaterialApp(
      home: SignupScreen(),
    ),
  );
}

void main() {
  group('SignupScreen', () {
    testWidgets('shows Continue with Google button', (tester) async {
      await tester.pumpWidget(_buildSignup());
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows Create account primary button', (tester) async {
      await tester.pumpWidget(_buildSignup());
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('shows EMAIL, PASSWORD, CONFIRM PASSWORD labels', (tester) async {
      await tester.pumpWidget(_buildSignup());
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
    });

    testWidgets('shows sign in link', (tester) async {
      await tester.pumpWidget(_buildSignup());
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_buildSignup());
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.enterText(fields.at(2), 'different123');
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
