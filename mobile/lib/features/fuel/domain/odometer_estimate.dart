/// Returns an estimated next odometer reading based on [recentOdometers],
/// which should be in descending order (most recent first), or any order
/// with at least the most recent values present.
///
/// Algorithm: average distance between consecutive readings over the last
/// [maxSamples] entries, then add that average to the last reading.
/// Result is rounded to the nearest 10.
///
/// Returns null when fewer than 2 readings exist (not enough data).
int? estimateNextOdometer(
  List<int> recentOdometers, {
  int maxSamples = 5,
}) {
  if (recentOdometers.length < 2) return null;

  // Take at most maxSamples readings (they are expected in descending order).
  final samples = recentOdometers.take(maxSamples).toList();

  double totalDelta = 0;
  int count = 0;
  for (int i = 0; i < samples.length - 1; i++) {
    final delta = samples[i] - samples[i + 1];
    if (delta > 0) {
      totalDelta += delta;
      count++;
    }
  }

  if (count == 0) return null;

  final avgDelta = totalDelta / count;
  final estimate = samples.first + avgDelta;

  // Round to the nearest 10.
  return ((estimate / 10).round() * 10).toInt();
}
