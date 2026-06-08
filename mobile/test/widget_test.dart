import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/main.dart';

void main() {
  testWidgets('App boots to the dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DriveVaultApp()));
    await tester.pumpAndSettle();

    // The dashboard shell renders the app name.
    expect(find.text('DriveVault'), findsWidgets);
    expect(find.text('Dashboard coming soon — Phase 1 scaffold.'), findsOneWidget);
  });
}
