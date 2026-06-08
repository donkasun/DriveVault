import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// NOTE: Firebase is NOT initialized here yet. Task C2 adds `firebase_options.dart`
// (via `flutterfire configure`) and wires `Firebase.initializeApp()` + auth gating.
void main() {
  runApp(const ProviderScope(child: DriveVaultApp()));
}

class DriveVaultApp extends ConsumerWidget {
  const DriveVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'DriveVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
