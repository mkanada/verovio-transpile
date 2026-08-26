/// Port of `fraction.h/cpp`.
library;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/logging.dart';

/// Rational number with explicit numerator and denominator.
///
/// Mirrors `vrv::Fraction`. Instances are always kept reduced with a positive
/// denominator after construction.
class Fraction implements Comparable<Fraction> {
  /// Creates a fraction [num]/[denom] (default denom 1), reduced.
  Fraction(int num, [int denom = 1]) {
    if (denom == 0) {
      logDebug('Denominator cannot be zero.');
      denom = 1;
    }
    _numerator = num;
    _denominator = denom;
    _reduce();
  }

  /// Converts a duration value to a fraction (mirrors `Fraction(data_DURATION)`).
  factory Fraction.fromDuration(MeiDuration duration) {
    duration = MeiDuration.min(duration, MeiDuration.dur2048);
    duration = MeiDuration.max(duration, MeiDuration.maxima);
    final int den = 1 << (duration.value + 1);
    return Fraction(8, den);
  }

  int _numerator = 0;
  int _denominator = 1;

  int get numerator => _numerator;
  int get denominator => _denominator;

  Fraction operator +(Fraction other) => Fraction(
      _numerator * other._denominator + other._numerator * _denominator,
      _denominator * other._denominator);

  Fraction operator -(Fraction other) => Fraction(
      _numerator * other._denominator - other._numerator * _denominator,
      _denominator * other._denominator);

  Fraction operator *(Fraction other) => Fraction(
      _numerator * other._numerator, _denominator * other._denominator);

  Fraction operator /(Fraction other) {
    if (other._numerator == 0) {
      logDebug('Cannot divide by zero.');
      return this;
    }
    return Fraction(
        _numerator * other._denominator, _denominator * other._numerator);
  }

  /// Modulo operator (mirrors `operator%`).
  Fraction operator %(Fraction other) {
    if (other._numerator == 0) {
      logDebug('Cannot divide by zero.');
      return this;
    }

    final int commonDenominator = _denominator * other._denominator;
    final int leftNumerator = _numerator * other._denominator;
    final int rightNumerator = other._numerator * _denominator;

    // Integer quotient (truncated towards zero, like C++).
    final int quotient = leftNumerator ~/ rightNumerator;

    // Remainder as a fraction.
    final remainder =
        Fraction(leftNumerator - quotient * rightNumerator, commonDenominator);
    return remainder;
  }

  @override
  bool operator ==(Object other) =>
      other is Fraction &&
      _numerator * other._denominator == other._numerator * _denominator;

  @override
  int get hashCode => Object.hash(_numerator, _denominator);

  @override
  int compareTo(Fraction other) => (_numerator * other._denominator)
      .compareTo(other._numerator * _denominator);

  bool operator >(Fraction other) => compareTo(other) > 0;
  bool operator >=(Fraction other) => compareTo(other) >= 0;
  bool operator <(Fraction other) => compareTo(other) < 0;
  bool operator <=(Fraction other) => compareTo(other) <= 0;

  /// Convert fraction to a double.
  double toDouble() => _numerator / _denominator;

  /// Convert fraction to a string ("num/den").
  String toStr() => '$_numerator/$_denominator';

  /// Convert to a [MeiDuration] and the remaining fraction
  /// (mirrors `ToDur()`).
  (MeiDuration, Fraction) toDur() {
    if (_numerator == 0) return (MeiDuration.none, Fraction(0));

    // Smallest integer v with 2^v >= (_denominator * 8 / _numerator),
    // computed exactly in integer arithmetic; then -1 as in the C++:
    // value = ceil(log2((double)den / (double)num * 8)) - 1;
    final int target = _denominator * 8;
    int value = 0;
    int pow2 = 1;
    while (_numerator > 0 && _numerator * pow2 < target) {
      pow2 <<= 1;
      value++;
      if (pow2 <= 0) break; // overflow guard
    }
    if (_numerator <= 0) {
      value = -1;
    } else if (value > 0) {
      value--;
    }

    MeiDuration dur = MeiDuration.fromValue(value);
    dur = MeiDuration.max(MeiDuration.maxima, dur);
    dur = MeiDuration.min(MeiDuration.dur2048, dur);

    Fraction remainder = this - Fraction.fromDuration(dur);
    // Making sure we would not trigger an infinite loop when looping over
    // the remainder.
    if (remainder >= this || remainder < Fraction(0)) remainder = Fraction(0);
    return (dur, remainder);
  }

  /// Reduce the fraction represented by the two numbers in place.
  static void reducePair(List<int> pair) {
    final f = Fraction(pair[0], pair[1]);
    pair[0] = f.numerator;
    pair[1] = f.denominator;
  }

  void _reduce() {
    if (_denominator < 0) {
      // Keep the denominator positive.
      _numerator = -_numerator;
      _denominator = -_denominator;
    }
    final gcdVal = gcdSafe(_numerator.abs(), _denominator.abs());
    if (gcdVal != 1 && gcdVal != 0) {
      _numerator = _numerator ~/ gcdVal;
      _denominator = _denominator ~/ gcdVal;
    }
  }
}

/// Greatest common divisor (std::gcd equivalent; gcd(0, 0) == 0).
int gcdSafe(int a, int b) {
  while (b != 0) {
    final t = a % b;
    a = b;
    b = t;
  }
  return a;
}
