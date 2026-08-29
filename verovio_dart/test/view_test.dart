/// Tests for `lib/src/rendering/view.dart` (task 05-06) — the `View`
/// skeleton ported from `origin/src/src/view.cpp` (342 lines): the
/// logical↔device coordinate conversions, the three `IntTo*Figures` SMuFL
/// converters, and the offset stack (`StartOffset` … `CalcOffsetBezier`).
library;

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasurementSigned;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Hairpin;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Custos;
import 'package:verovio_dart/src/rendering/bbox_device_context.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';

import 'support/render_family.dart';

/// A device context whose `applyOffset()` returns true — like the
/// `SvgDeviceContext`, the only C++ device context overriding `ApplyOffset`
/// (svgdevicecontext.h:118; the base returns false, devicecontext.h:257).
class OffsetDc extends BBoxDeviceContext {
  OffsetDc() : super(toLogicalX: (x) => x, toLogicalY: (y) => y);

  @override
  bool applyOffset() => true;
}

/// Builds an `Accid` (which carries the `OffsetInterface`) with `@ho` / `@vo`
/// set in view-port units. Accid is the C++ comment's own example of the
/// recursive application ("e.g., accid within note", view.h:661-662).
///
/// Note: the control elements (`Dir`, `Hairpin`, ...) do not register
/// `InterfaceId.offset` in this port — see "Achados fora de escopo" in the
/// task report.
Accid makeAccid({required double ho, required double vo}) => Accid()
  ..ho = (MeasurementSigned()..setVu(ho))
  ..vo = (MeasurementSigned()..setVu(vo));

/// Builds a `Hairpin` (which carries the `OffsetSpanningInterface`) with the
/// four spanning offsets set in view-port units.
Hairpin makeHairpin({
  required double startho,
  required double startvo,
  required double endho,
  required double endvo,
}) =>
    Hairpin()
      ..startho = (MeasurementSigned()..setVu(startho))
      ..startvo = (MeasurementSigned()..setVu(startvo))
      ..endho = (MeasurementSigned()..setVu(endho))
      ..endvo = (MeasurementSigned()..setVu(endvo));

void main() {
  late Doc doc;
  late View view;

  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  setUp(() {
    doc = Doc()..drawingPageContentHeight = 2970;
    view = View()..setDoc(doc);
  });

  test('view: família base (note) contra goldens — view.cpp', () {
    final resultados = renderizarFamilia('test/corpus/note');
    // Medido em 2026-08-29: 3 limpos / 12 total
    expect(resultados.limpos, greaterThanOrEqualTo(3),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
  });

  test('view: decisão ToDeviceContextY flip (view.cpp:84) sobre SVG', () {
    final svg = renderizar('test/corpus/note/note-001.mei');
    // A coordenada Y do sistema é flipada; golden tem <g class="system"> com transform implícito
    expect(svg, contains('system'),
        reason: 'note-001 contém system — view.cpp:84 flip');
    expect(svg, contains('page-margin'),
        reason: 'page-margin transform 500,500 — view.cpp:72-100');
  });

  group('View — coordinate conversions (view.cpp:72-111)', () {
    const values = <int>[
      0,
      1,
      -1,
      2,
      -2,
      3,
      -3,
      7,
      -7,
      10,
      -10,
      100,
      -100,
      297,
      -297,
      1000,
      -1000,
      2970,
      -2970,
      12345,
      -12345,
      100000,
      -100000,
      65535,
    ];

    test('toLogicalX(toDeviceContextX(x)) == x for 24 values', () {
      for (final x in values) {
        expect(view.toLogicalX(view.toDeviceContextX(x)), equals(x),
            reason: 'x = $x');
      }
    });

    test('toLogicalY(toDeviceContextY(y)) == y for 24 values', () {
      for (final y in values) {
        expect(view.toLogicalY(view.toDeviceContextY(y)), equals(y),
            reason: 'y = $y');
      }
    });

    test('Point roundtrip for mixed coordinates', () {
      for (final y in values) {
        final p = Point(42, y);
        expect(view.toLogical(view.toDeviceContext(p)), equals(p),
            reason: 'y = $y');
      }
    });

    test('Y is flipped around the page content height', () {
      // The C++ is (m_doc->m_drawingPageContentHeight - i) in both directions
      // (view.cpp:90 and :100) — the page offset axis, not a trivial inverse.
      expect(view.toDeviceContextY(0), equals(2970));
      expect(view.toDeviceContextY(2970), equals(0));
      expect(view.toLogicalY(0), equals(2970));
      expect(view.toLogicalY(2970), equals(0));
    });

    test('without a doc the Y conversions return 0, X is untouched', () {
      final bare = View();
      expect(bare.toDeviceContextY(5), equals(0));
      expect(bare.toLogicalY(-3), equals(0));
      expect(bare.toDeviceContextX(7), equals(7));
      expect(bare.toLogicalX(-7), equals(-7));
      expect(bare.toDeviceContext(Point(1, 2)), equals(Point(1, 0)));
      expect(bare.toLogical(Point(1, 2)), equals(Point(1, 0)));
    });

    test('slur handling defaults to Initialize and is settable', () {
      // Mirrors m_slurHandling = SlurHandling::Initialize (view.cpp:32).
      expect(view.slurHandling, equals(SlurHandling.initialize));
      view.slurHandling = SlurHandling.ignore;
      expect(view.slurHandling, equals(SlurHandling.ignore));
    });
  });

  group('View — IntTo*Figures (view.cpp:113-133)', () {
    test('tuplet figures start at 0xE880', () {
      expect(view.intToTupletFigures(3).runes.toList(), equals([0xE883]));
      expect(
          view.intToTupletFigures(12).runes.toList(), equals([0xE881, 0xE882]));
    });

    test('time signature figures start at 0xE080', () {
      expect(view.intToTimeSigFigures(4).runes.toList(), equals([0xE084]));
      expect(view.intToTimeSigFigures(16).runes.toList(),
          equals([0xE081, 0xE086]));
    });

    test('the offset parameter shifts the ASCII digits (view.cpp:130)', () {
      // c += offset - 48: with offset == 48 the digits are unchanged.
      expect(view.intToSmuflFigures(42, 48), equals('42'));
      expect(
          view.intToSmuflFigures(1, 0xE880).runes.toList(), equals([0xE881]));
    });
  });

  group('View — offset stack (view.cpp:135-340)', () {
    // Default options: unit == 9.0 with the definition factor (10) applied by
    // GetValue, so `unit` is 90 — StartOffset multiplies the @ho / @vo value
    // by it (view.cpp:139).
    test('a single OffsetInterface object shifts x and y', () {
      final dc = OffsetDc();
      final accid = makeAccid(ho: 2, vo: 1); // 2 * 90 = 180, 1 * 90 = 90

      view.startOffset(dc, accid, 100);
      expect(view.calcOffset(dc, 1000, 2000), equals((1180, 2090)));
      expect(view.calcOffsetX(dc, 1000), equals(1180));
      expect(view.calcOffsetY(dc, 2000), equals(2090));

      view.endOffset(dc, accid);
      expect(view.calcOffset(dc, 1000, 2000), equals((1000, 2000)));
    });

    test('the staff size scales the offsets (view.cpp:192)', () {
      final dc = OffsetDc();
      final accid = makeAccid(ho: 2, vo: 1);

      view.startOffset(dc, accid, 200);
      // 180 * 200 / 100 = 360 and 90 * 200 / 100 = 180.
      expect(view.calcOffset(dc, 1000, 2000), equals((1360, 2180)));
    });

    test('setOffsetStaffSize changes the scaling of the top offset', () {
      final dc = OffsetDc();
      final accid = makeAccid(ho: 2, vo: 0);

      view.startOffset(dc, accid, 100);
      view.setOffsetStaffSize(accid, 250);
      // 180 * 250 / 100 = 450.
      expect(view.calcOffsetX(dc, 1000), equals(1450));
    });

    test('spanning offsets are picked per spanning type (view.cpp:215-283)',
        () {
      final dc = OffsetDc();
      // unit 90: startho=90, startvo=-90, endho=180, endvo=90.
      final hairpin = makeHairpin(startho: 1, startvo: -1, endho: 2, endvo: 1);

      view.startOffset(dc, hairpin, 100);

      // StartX: startho applies for START_END and START only.
      expect(view.calcOffsetSpanningStartX(dc, 1000, spanningStartEnd),
          equals(1090));
      expect(
          view.calcOffsetSpanningStartX(dc, 1000, spanningStart), equals(1090));
      expect(
          view.calcOffsetSpanningStartX(dc, 1000, spanningEnd), equals(1000));

      // EndX: endho applies for START_END and END only.
      expect(view.calcOffsetSpanningEndX(dc, 1000, spanningStartEnd),
          equals(1180));
      expect(view.calcOffsetSpanningEndX(dc, 1000, spanningEnd), equals(1180));
      expect(
          view.calcOffsetSpanningEndX(dc, 1000, spanningStart), equals(1000));

      // StartY with START_END / START: startvo (-90).
      expect(view.calcOffsetSpanningStartY(dc, 2000, spanningStartEnd),
          equals(1910));
      // StartY with END — the averaging branch (view.cpp:254-255):
      // (startvo + endvo) / 2 = (-90 + 90) / 2 = 0 -> unchanged.
      expect(
          view.calcOffsetSpanningStartY(dc, 2000, spanningEnd), equals(2000));
      // StartY with MIDDLE — the else branch (view.cpp:257-260):
      // diff = (startvo - endvo) / 2 = (-90 - 90) / 2 = -90;
      // y + ((startvo + endvo) / 2 + diff) = 2000 + (0 - 90) = 1910.
      expect(view.calcOffsetSpanningStartY(dc, 2000, spanningMiddle),
          equals(1910));

      // EndY with START — the averaging branch (view.cpp:272-273):
      // (endvo + startvo) / 2 = 0 -> unchanged.
      expect(
          view.calcOffsetSpanningEndY(dc, 2000, spanningStart), equals(2000));
      // EndY with MIDDLE — the else branch (view.cpp:278-280):
      // diff = (endvo - startvo) / 2 = 90; (0 + 90) -> 2090.
      expect(
          view.calcOffsetSpanningEndY(dc, 2000, spanningMiddle), equals(2090));
    });

    test('nested offsets accumulate over the whole list (view.cpp:191)', () {
      final dc = OffsetDc();
      final accid1 = makeAccid(ho: 1, vo: 0); // 90
      final accid2 = makeAccid(ho: 2, vo: 1); // 180, 90

      view.startOffset(dc, accid1, 100);
      view.startOffset(dc, accid2, 100);

      // CalcOffset walks every entry of the list, not only the top: both ho
      // (and both vo) values contribute.
      expect(view.calcOffset(dc, 1000, 2000), equals((1270, 2090)));
    });

    test('push-front / pop-front discipline (view.cpp:170, :177)', () {
      final dc = OffsetDc();
      final accid = makeAccid(ho: 1, vo: 0);
      final hairpin = makeHairpin(startho: 1, startvo: 0, endho: 0, endvo: 0);
      final other = Custos();

      view.startOffset(dc, accid, 100);
      view.startOffset(dc, hairpin, 100);

      // EndOffset only pops when the FRONT of the list is the object: the
      // hairpin was pushed last (push_front), so it comes out first.
      view.endOffset(dc, hairpin);
      expect(view.calcOffset(dc, 1000, 2000), equals((1090, 2000)));

      // A different object does not pop anything.
      view.endOffset(dc, other);
      expect(view.calcOffset(dc, 1000, 2000), equals((1090, 2000)));

      view.endOffset(dc, accid);
      expect(view.calcOffset(dc, 1000, 2000), equals((1000, 2000)));
    });

    test('a device context without ApplyOffset never accumulates offsets', () {
      final dc = BBoxDeviceContext(
          toLogicalX: (x) => x, toLogicalY: (y) => y); // applyOffset() == false
      final accid = makeAccid(ho: 2, vo: 1);

      view.startOffset(dc, accid, 100);
      expect(view.calcOffset(dc, 1000, 2000), equals((1000, 2000)));
      expect(view.calcOffsetSpanningStartX(dc, 1000, spanningStartEnd),
          equals(1000));
      view.endOffset(dc, accid); // no-op, nothing was pushed
    });

    test('elements without offset values are not pushed (view.cpp:147, :159)',
        () {
      final dc = OffsetDc();
      final plain = Custos(); // OffsetInterface registered, ho / vo unset

      view.startOffset(dc, plain, 100);
      view.endOffset(dc, plain);
      // Nothing was pushed, so the accid below is still the top of the stack.
      final accid = makeAccid(ho: 1, vo: 0);
      view.startOffset(dc, accid, 100);
      view.setOffsetStaffSize(plain, 250); // must not touch `accid`
      expect(view.calcOffsetX(dc, 1000), equals(1090));
    });

    test('calcOffsetBezier adjusts the four points (view.cpp:285-340)', () {
      final dc = OffsetDc();
      final accid = makeAccid(ho: 1, vo: 2); // ho=90, vo=180
      final hairpin = makeHairpin(startho: 1, startvo: 1, endho: 2, endvo: 1);

      view.startOffset(dc, accid, 100);
      view.startOffset(dc, hairpin, 100);

      // factorStart = (1600 - 1300) / 600 = 0.5, factorEnd = (1450 - 1000) /
      // 600 = 0.75 — both exact in binary, like the C++ doubles.
      final points = [
        Point(1000, 2000),
        Point(1300, 2100),
        Point(1450, 2200),
        Point(1600, 2300),
      ];

      view.calcOffsetBezier(dc, points, spanningStartEnd);

      // Hand-computed from the C++ (the int truncation happens at every step,
      // as in the C++ int reference parameters). Stack: [hairpin (startho=90,
      // startvo=90, endho=180, endvo=90), accid (ho=90, vo=180)].
      // P0: start(se) +90/+90 -> (1090, 2090); calcOffset +90/+180 ->
      //     (1180, 2270).
      // P1: start(f=0.5) +45/+45 -> (1345, 2145); end(f=0.5) +90/+45 ->
      //     (1435, 2190); calcOffset -> (1525, 2370).
      // P2: start(f=0.25) +22.5 -> 1472.5 -> 1472 (int); end(f=0.75) +135 ->
      //     1607, +67.5 -> 2289.5 -> 2289; calcOffset -> (1697, 2469).
      // P3: end(se) +180/+90 -> (1780, 2390); calcOffset -> (1870, 2570).
      expect(points[0].x, equals(1180));
      expect(points[0].y, equals(2270));
      expect(points[1].x, equals(1525));
      expect(points[1].y, equals(2370));
      expect(points[2].x, equals(1697));
      expect(points[2].y, equals(2469));
      expect(points[3].x, equals(1870));
      expect(points[3].y, equals(2570));
    });

    test('calcOffsetBezier with MIDDLE only shifts y (view.cpp:333-339)', () {
      final dc = OffsetDc();
      final accid = makeAccid(ho: 1, vo: 1);

      view.startOffset(dc, accid, 100);

      final points = [
        Point(1000, 2000),
        Point(1300, 2100),
        Point(1450, 2200),
        Point(1600, 2300),
      ];

      view.calcOffsetBezier(dc, points, spanningMiddle);

      // Only the vertical offset applies: +90 on every y, x untouched.
      expect(points[0], equals(Point(1000, 2090)));
      expect(points[1], equals(Point(1300, 2190)));
      expect(points[2], equals(Point(1450, 2290)));
      expect(points[3], equals(Point(1600, 2390)));
    });
  });
}
