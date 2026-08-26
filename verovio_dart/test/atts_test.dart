import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/model/atts/atts_conversion.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart';
import 'package:xml/xml.dart';

class TestAccidental with AttAccidental {}

class TestCleffingLog with AttClefLog, AttCleffingLog {}

/// Writes attributes into a builder and returns the resulting element.
XmlElement writeWith(void Function(XmlBuilder) write, String name) {
  final b = XmlBuilder();
  b.element(name, nest: () {
    b.attribute('__placeholder__', '');
    write(b);
  });
  return b.buildDocument().rootElement;
}

void main() {
  group('Basic converters', () {
    test('strToInt mirrors atoi', () {
      expect(strToInt('42'), 42);
      expect(strToInt('-17'), -17);
      expect(strToInt('12abc'), 12);
      expect(strToInt('abc'), 0);
      expect(strToInt(''), 0);
    });

    test('strToDbl mirrors atof', () {
      expect(strToDbl('2.5'), 2.5);
      expect(strToDbl('-0.5vu'), -0.5);
      expect(strToDbl('abc'), 0.0);
    });

    test('dblToStr rounds to 4 decimals without trailing zeros', () {
      expect(dblToStr(2.0), '2');
      expect(dblToStr(2.5), '2.5');
      expect(dblToStr(1.23456), '1.2346');
    });

    test('hexnum roundtrip restricted to SMuFL range', () {
      expect(strToHexnum('U+E0A4'), 0xE0A4);
      expect(strToHexnum('#xE0A4'), 0xE0A4);
      expect(hexnumToStr(0xE0A4), 'U+E0A4');
      // Outside the private area:
      expect(strToHexnum('U+0041'), 0);
      // Missing prefix:
      expect(strToHexnum('E0A4'), 0);
    });

    test('boolean', () {
      expect(strToBoolean('true'), isTrue);
      expect(strToBoolean('false'), isFalse);
      expect(strToBoolean('yes'), isNull);
      expect(booleanToStr(true), 'true');
    });
  });

  group('Enum converters', () {
    test('accidental written', () {
      expect(strToAccidentalWritten('s'), AccidentalWritten.s);
      expect(accidentalWrittenToStr(AccidentalWritten.x), 'x');
      expect(strToAccidentalWritten('zz'), AccidentalWritten.none);
    });

    test('pitch name', () {
      expect(strToPitchname('c'), Pitchname.c);
      expect(pitchnameToStr(Pitchname.b), 'b');
      expect(strToPitchname('h'), Pitchname.none);
    });

    test('duration uses the canonical MeiDuration type', () {
      expect(strToDuration('4'), MeiDuration.dur4);
      expect(durationToStr(MeiDuration.dur8), '8');
      expect(strToDuration('bogus'), MeiDuration.none);
      expect(durationToStr(MeiDuration.none), '');
    });

    test('staffrel / placement composition', () {
      final p = strToPlacement('above');
      expect(p.type, PlacementType.staffRel);
      expect(p.staffRel, Staffrel.above);
      expect(placementToStr(p), 'above');
      // NMT token fallback accepts anything:
      final q = strToPlacement('somewhere-else');
      expect(q.type, PlacementType.nmtoken);
      expect(q.nmtoken, 'somewhere-else');
    });

    test('fontsize variants', () {
      final f = strToFontsize('24pt');
      expect(f.type, FontSizeType.fontSizeNumeric);
      expect(f.fontSizeNumeric, 24.0);
      expect(fontsizeToStr(f), contains('pt'));

      final t = strToFontsize('large');
      expect(t.type, FontSizeType.term);
      expect(t.term, Fontsizeterm.large);

      final pc = strToFontsize('150%');
      expect(pc.type, FontSizeType.percent);
      expect(pc.percent, 150.0);
    });

    test('keysignature', () {
      final ks = strToKeysignature('3s');
      expect(ks.sig, 3);
      expect(ks.accid, AccidentalWritten.s);
      expect(keysignatureToStr(ks), '3s');

      expect(strToKeysignature('mixed').sig, meiUnset);
      expect(keysignatureToStr(KeySignature(meiUnset, AccidentalWritten.none)),
          'mixed');
      expect(strToKeysignature('0').accid, AccidentalWritten.n);
      expect(strToKeysignature('13s').sig, -1); // unsupported -> unset
    });

    test('measurebeat', () {
      final mb = strToMeasurebeat('2m+1.5');
      expect(mb.measures, 2);
      expect(mb.beat, closeTo(1.5, 1e-9));
      expect(measurebeatToStr(mb), '2m+1.5');
    });

    test('metercount pair', () {
      final mc = strToMetercountPair('3+2');
      expect(mc.counts, [3, 2]);
      expect(mc.sign, MeterCountSign.plus);
      expect(metercountPairToStr(mc), '3+2');

      final ms = strToMetercountPair('3/4');
      expect(ms.sign, MeterCountSign.slash);
      expect(metercountPairToStr(ms), r'3\4');
    });

    test('bulge pairs', () {
      final b = strToBulge('0.5 10 1.0 20');
      expect(b.length, 2);
      expect(b[0].$1, 0.5);
      expect(b[1].$2, 20.0);
      expect(bulgeToStr(b), '0.5 10 1 20');
    });

    test('measurements px/vu', () {
      final m = strToMeasurementsigned('5px');
      expect(m.type, MeasurementType.px);
      expect(m.px, 50); // DEFINITION_FACTOR = 10
      expect(measurementsignedToStr(m), '5px');

      final v = strToMeasurementsigned('2.5vu');
      expect(v.type, MeasurementType.vu);
      expect(v.vu, 2.5);
    });
  });

  group('Generated att mixins', () {
    test('AttAccidental read/write roundtrip', () {
      final att = TestAccidental();
      final reader =
          MeiAttributeReader({'accid': 's', 'other': 'keep'});
      expect(att.readAccidental(reader), isTrue);
      expect(att.accid, AccidentalWritten.s);
      expect(att.hasAccid, isTrue);
      // The attribute is consumed; leftovers remain:
      expect(reader.unsupported.keys, ['other']);

      final out = writeWith((b) => att.writeAccidental(b), 'accid');
      expect(out.getAttribute('accid'), 's');
    });

    test('AttCleffingLog reads multiple attributes and flags presence', () {
      final att = TestCleffingLog();
      final reader = MeiAttributeReader({
        'cautionary': 'true',
        'clef.shape': 'G',
        'clef.line': '2',
        'unrelated': 'x',
      });
      expect(att.readClefLog(reader), isTrue);
      expect(att.readCleffingLog(reader), isTrue);
      expect(att.cautionary, isTrue);
      expect(att.clefShape, Clefshape.g);
      expect(att.clefLine, 2);
      expect(reader.unsupported.keys, ['unrelated']);

      final out = writeWith((b) {
        att.writeClefLog(b);
        att.writeCleffingLog(b);
      }, 'clef');
      expect(out.getAttribute('clef.shape'), 'G');
      expect(out.getAttribute('clef.line'), '2');
      expect(out.getAttribute('cautionary'), 'true');
    });

    test('read returns false when nothing matched', () {
      final att = TestAccidental();
      expect(att.readAccidental(MeiAttributeReader({})), isFalse);
      expect(att.hasAccid, isFalse);
      final out = writeWith(att.writeAccidental, 'accid');
      expect(out.attributes.map((a) => a.name.local), ['__placeholder__']);
    });
  });
}
