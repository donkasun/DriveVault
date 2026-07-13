/**
 * Estimates the next odometer reading.
 * Parity with Flutter `features/fuel/domain/odometer_estimate.dart`.
 *
 * `recentOdometers` is expected in DESCENDING order (most recent first).
 * Averages the distance between consecutive readings over the last `maxSamples`
 * entries and adds it to the most recent reading, rounded to the nearest 10.
 *
 * Returns null when there are fewer than 2 readings, or when no positive delta
 * exists (e.g. the odometer never advanced).
 */
export function estimateNextOdometer(recentOdometers: number[], maxSamples = 5): number | null {
  if (recentOdometers.length < 2) return null;

  const samples = recentOdometers.slice(0, maxSamples);

  let totalDelta = 0;
  let count = 0;
  for (let i = 0; i < samples.length - 1; i++) {
    const delta = samples[i] - samples[i + 1];
    if (delta > 0) {
      totalDelta += delta;
      count++;
    }
  }

  if (count === 0) return null;

  const avgDelta = totalDelta / count;
  const estimate = samples[0] + avgDelta;

  return Math.round(estimate / 10) * 10;
}
