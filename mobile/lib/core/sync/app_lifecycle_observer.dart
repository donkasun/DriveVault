import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/dashboard_provider.dart';
import '../../features/vehicles/presentation/vehicles_provider.dart';

/// Observes app lifecycle events and triggers background data refreshes
/// when the app returns to the foreground after being backgrounded for
/// more than [_backgroundThreshold].
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef _ref;

  /// Minimum time in the background before triggering a refresh on resume.
  static const _backgroundThreshold = Duration(seconds: 30);

  DateTime? _pausedAt;

  AppLifecycleObserver(WidgetRef ref) : _ref = ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        if (pausedAt != null &&
            DateTime.now().difference(pausedAt) >= _backgroundThreshold) {
          _ref.read(dashboardProvider.notifier).refresh();
          _ref.read(vehiclesProvider.notifier).refresh();
        }
        _pausedAt = null;
      default:
        break;
    }
  }
}
