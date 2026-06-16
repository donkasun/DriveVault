import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drivevault/core/router/main_shell.dart';
import 'package:drivevault/core/theme/app_theme.dart';

class _Page extends StatelessWidget {
  final String label;

  const _Page(this.label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const _Page('Home body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/garage',
                builder: (context, state) => const _Page('Garage body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const _Page('Expenses body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const _Page('Settings body'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('highlights the active tab like the redesign', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: _router(),
          theme: AppTheme.light,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final garageText = tester.widget<Text>(find.text('Garage'));

    expect(garageText.style?.color, AppColors.textOnDarkMuted);
    expect(find.text('Home'), findsNothing);
    expect(find.byKey(const Key('fab_quick_add')), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsNothing);
    final homeTextAfter = tester.widget<Text>(find.text('Home'));
    expect(homeTextAfter.style?.color, AppColors.textOnDarkMuted);
  });
}
