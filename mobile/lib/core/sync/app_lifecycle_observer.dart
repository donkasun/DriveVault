import 'dart:async';

import 'package:flutter/widgets.dart';

/// Observes app lifecycle events and triggers background data refreshes
/// when the app returns to the foreground.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() _refreshDashboard;
  final Future<void> Function() _refreshVehicles;

  AppLifecycleObserver({
    required Future<void> Function() refreshDashboard,
    required Future<void> Function() refreshVehicles,
  }) : _refreshDashboard = refreshDashboard,
       _refreshVehicles = refreshVehicles;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDashboard());
      unawaited(_refreshVehicles());
    }
  }
}
