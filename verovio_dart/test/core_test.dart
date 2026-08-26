import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/crc.dart';
import 'package:verovio_dart/src/core/fraction.dart';

void main() {
  group('Fraction', () {
    test('construction and reduction', () {
      final f = Fraction(8, 32);
      expect(f.numerator, 1);
      expect(f.denominator, 4);
    });

    test('negative denominator is normalized', () {
      final f = Fraction(1, -2);
      expect(f.numerator, -1);
      expect(f.denominator, 2);
    });

    test('zero denominator falls back to 1', () {
      final f = Fraction(3, 0);
      expect(f.denominator, 1);
      expect(f.numerator, 3);
    });

    test('arithmetic', () {
      expect((Fraction(1, 2) + Fraction(1, 4)), Fraction(3, 4));
      expect((Fraction(1, 2) - Fraction(1, 4)), Fraction(1, 4));
      expect((Fraction(1, 2) * Fraction(2, 3)), Fraction(1, 3));
      expect((Fraction(1, 2) / Fraction(1, 4)), Fraction(2));
      // Truncated modulo like C++.
      expect((Fraction(7, 4) % Fraction(1, 2)), Fraction(1, 4));
    });

    test('comparison and equality', () {
      expect(Fraction(1, 2), Fraction(2, 4));
      expect(Fraction(1, 2) < Fraction(3, 4), isTrue);
      expect(Fraction(1, 2) >= Fraction(1, 2), isTrue);
    });

    test('fromDuration: DURATION_4 is a quarter', () {
      final f = Fraction.fromDuration(MeiDuration.dur4);
      expect(f.toDouble(), 0.25);
    });

    test('toDur roundtrip', () {
      var (dur, rem) = Fraction(1, 4).toDur();
      expect(dur, MeiDuration.dur4);
      expect(rem.toDouble(), 0.0);

      // 3/4 = half + quarter remainder (as in the C++ implementation)
      (dur, rem) = Fraction(3, 4).toDur();
      expect(dur, MeiDuration.dur2);
      expect(rem, Fraction(1, 4));

      // 1/1 = whole
      (dur, rem) = Fraction(1, 1).toDur();
      expect(dur, MeiDuration.dur1);
      expect(rem.toDouble(), 0.0);

      // Zero
      (dur, rem) = Fraction(0).toDur();
      expect(dur, MeiDuration.none);
      expect(rem.toDouble(), 0.0);
    });

    test('toString', () {
      expect(Fraction(1, 2).toStr(), '1/2');
    });
  });

  group('CRC', () {
    test('crcFast matches CRC-16/CCITT-FALSE of "123456789"', () {
      // Standard check value for CRC-16/CCITT-FALSE.
      final bytes = '123456789'.codeUnits;
      expect(crcFast(bytes), 0x29B1);
    });
  });
}
