import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PendingTabNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void switchTo(int index) => state = index;
  void clear() => state = null;
}

final pendingTabProvider =
    NotifierProvider<_PendingTabNotifier, int?>(_PendingTabNotifier.new);
