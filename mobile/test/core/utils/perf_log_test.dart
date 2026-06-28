import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/utils/perf_log.dart';

void main() {
  test('PerfLog.mark does not throw when start was not called', () {
    expect(() => PerfLog.mark('unknown', 'cache'), returnsNormally);
  });

  test('PerfLog.start then mark does not throw', () {
    expect(() {
      PerfLog.start('vehicles');
      PerfLog.mark('vehicles', 'cache');
      PerfLog.mark('vehicles', 'network');
    }, returnsNormally);
  });
}
