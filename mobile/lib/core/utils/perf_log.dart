import 'package:flutter/foundation.dart';

class PerfLog {
  static final Map<String, Stopwatch> _watches = {};
  static final Map<String, int> _lastMs = {};

  static void start(String tag) {
    if (!kDebugMode) return;
    _watches[tag] = Stopwatch()..start();
    _lastMs[tag] = 0;
  }

  static void mark(String tag, String label) {
    if (!kDebugMode) return;
    final sw = _watches[tag];
    if (sw == null) return;
    final elapsed = sw.elapsedMilliseconds;
    final delta = elapsed - (_lastMs[tag] ?? 0);
    _lastMs[tag] = elapsed;
    debugPrint('[DriveVault Perf] $tag: $label=${elapsed}ms (Δ+${delta}ms)');
  }
}
