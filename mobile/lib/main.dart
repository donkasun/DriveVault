import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/config/app_config.dart';
import 'features/dashboard/presentation/dashboard_provider.dart';
import 'features/vehicles/presentation/vehicles_provider.dart';
import 'core/router/app_router.dart';
import 'core/sync/app_lifecycle_observer.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.assertConfigured();
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light, // iOS: dark icons
      statusBarIconBrightness: Brightness.dark, // Android: dark icons
    ),
  );
  runApp(const ProviderScope(child: DriveVaultApp()));
}

class DriveVaultApp extends ConsumerStatefulWidget {
  const DriveVaultApp({super.key});

  @override
  ConsumerState<DriveVaultApp> createState() => _DriveVaultAppState();
}

class _DriveVaultAppState extends ConsumerState<DriveVaultApp> {
  late final AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = AppLifecycleObserver(
      refreshDashboard: () => ref.read(dashboardProvider.notifier).refresh(),
      refreshVehicles: () => ref.read(vehiclesProvider.notifier).refresh(),
    );
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'DriveVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
