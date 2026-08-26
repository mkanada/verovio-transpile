/// Port of `runtimeclock.h/cpp`.
library;

/// A monotonic runtime clock used for measuring processing time.
class RuntimeClock {
  final Stopwatch _stopwatch = Stopwatch();

  RuntimeClock() {
    reset();
  }

  /// Resets the clock.
  void reset() {
    _stopwatch
      ..reset()
      ..start();
  }

  /// Get current runtime in seconds.
  double getSeconds() => _stopwatch.elapsedMicroseconds / 1e6;
}
