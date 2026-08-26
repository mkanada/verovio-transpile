import 'package:test/test.dart';
import 'package:verovio_dart/src/model/atts/atts_conversion.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';

/// Exhaustive round-trip checks for the generated enum converters: for every
/// table-backed enum, every string in the table must convert back to an
/// equivalent value.
void main() {
  test('every Accidentalwritten string value round-trips', () {
    for (final v in AccidentalWritten.values) {
      final s = accidentalWrittenToStr(v);
      if (v == AccidentalWritten.none) continue;
      expect(s, isNotEmpty,
          reason: 'missing table entry for $v');
      expect(strToAccidentalWritten(s), v, reason: 'roundtrip failed for $v');
    }
  });

  test('every Pitchname string value round-trips', () {
    for (final v in Pitchname.values) {
      final s = pitchnameToStr(v);
      if (v == Pitchname.none) continue;
      expect(s, isNotEmpty);
      expect(strToPitchname(s), v);
    }
  });

  test('clefshape values round-trip', () {
    for (final v in Clefshape.values) {
      final s = clefshapeToStr(v);
      if (v == Clefshape.none) continue;
      expect(s, isNotEmpty);
      expect(strToClefshape(s), v);
    }
  });
}
