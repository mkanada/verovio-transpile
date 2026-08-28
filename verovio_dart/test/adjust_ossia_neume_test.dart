/// Parity of [AdjustOssiaStaffDefFunctor] and [AdjustNeumeXFunctor]
/// (`lib/src/layout/adjust_ossia_neume.dart`) against the instrumented C++
/// (`cpp_probe` task `04g`).
///
/// **AdjustOssiaStaffDefFunctor** never reaches its "real work" branch on any
/// of the three fixed corpus files, including `ossia/ossia-001.mei` — the
/// C++ fixture itself proves it (`nOssias: 0` on every `VisitMeasureEnd`
/// record, all three files). The reason: `Layer::DrawOssiaStaffDef` — the
/// flag that would make `AlignHorizontallyFunctor::VisitLayer` inject an
/// ossia's clef/keySig as ordinary (non-scoreDef) layer elements in the
/// first place — is set correctly by `ScoreDefSetOssiaFunctor` since task
/// 04h, but `AlignHorizontallyFunctor::VisitLayer` itself does not check it
/// yet (`align_horizontally.dart`); without that check,
/// `AdjustOssiaStaffDefFunctor::VisitLayerElement`'s `assert(ossia)`-guarded
/// branch stays unreachable in *this* port on *any* input, C++ included. So
/// the comparison here runs in two registers, like task 04f's:
/// - *Exact fixture parity (epsilon 0)*: the no-op path (`nOssias == 0`,
///   `hasKeySigAlignment == 0`, `hasClefAlignment == 0`) reproduced end to
///   end on the three fixed files.
/// - *Hand-derived parity*: the "real work" branch — `VisitLayerElement`'s
///   width accumulation and `VisitMeasureEnd`'s `SetXRel` — verified against
///   the C++ algorithm on a hand-built synthetic tree, not a fixture.
///
/// **AdjustNeumeXFunctor** does reach its real branches, but not on the
/// task's originally-named `neume/neume-001.mei`: that file carries
/// `<facsimile type="transcription">`, so `Doc::IsTranscription()` /
/// `IsFacs()` route the real C++ through `Page::LayOutTranscription`
/// (`view.cpp:60-65`) instead of `Page::LayOut` — a pipeline that never calls
/// `AdjustOssiaStaffDefFunctor` or `AdjustNeumeXFunctor` at all
/// (`page.cpp:249-316`). The C++ fixture for `neume-001.mei` confirms this
/// directly: zero `"fn":"AdjustNeumeX"` records. `neume/neume-002.mei` (no
/// facsimile) is used instead — see `prompts/reports/04g.md` for the full
/// writeup, including why the task prompt's file choice does not hold up
/// empirically.
///
/// `neume-002.mei` has no `<measure>` at all (unmeasured chant encoding); its
/// C++ fixture shows three passes — pass 1 is a single big unmeasured
/// "measure[1]" (the state before any cast-off split), passes 2/3 are the
/// final cast-off page (multiple system-measures). Passes 1 is used below.
///
/// Laying the file out end to end in this port and comparing absolute xRel
/// values against pass 1 does *not* work, though: horizontal spacing for
/// neume documents already diverges from the C++ upstream of this functor —
/// exactly the "a largura de sistema hoje sai w=0" state the task's own
/// "Armadilhas conhecidas" names as pre-existing, not a regression to chase
/// here. So the AdjustNeumeXFunctor comparison instead uses the
/// synthetic-per-record technique already established in
/// `adjust_beams_test.dart` / `adjust_x_overflow_test.dart`: each pass-1
/// record's own recorded "before" state seeds a minimal tree, and the
/// assertion is that the functor reproduces that record's "after" state —
/// independent of whatever upstream xRel this port's own pipeline would
/// have produced feeding into it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/adjust_ossia_neume.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Notationtype;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Clef, Layer, Measure, Ossia, Staff;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show KeySig, Neume, Syl, Syllable;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04g';

const List<String> kFixedCorpusFiles = <String>[
  'test/corpus/ossia/ossia-001.mei',
  'test/corpus/neume/neume-002.mei',
  'test/corpus/note/note-009.mei',
];

Doc _loadCorpus(String relativePath) {
  final File file = File(relativePath);
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final bool ok = input.import(utf8.decode(file.readAsBytesSync()));
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

/// Attaches [leaf] under a fresh `Measure -> Staff -> Layer -> Syllable`
/// chain and returns the measure. `LayerElement::GetDrawingX` needs a real
/// `measure` ancestor to route through `alignment.getXRel()` at all — without
/// one it falls back to the (here always zero) `drawingXRel` field, which is
/// not what these tests want to control. Routing through a `Syllable`
/// (itself a `LayerElement`, but with no alignment of its own set here, so
/// `identical(parent.getAlignment(), alignment)` is false) also mirrors the
/// real neume/syl nesting instead of attaching directly to the staff.
Measure _attachToMeasure(LayerElement leaf) {
  final Measure measure = Measure();
  final Staff staff = Staff();
  measure.addChild(staff);
  final Layer layer = Layer();
  staff.addChild(layer);
  final Syllable syllable = Syllable();
  layer.addChild(syllable);
  syllable.addChild(leaf);
  return measure;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
    logLevel = LogLevel.error;
  });

  group('proveniência dos fixtures', () {
    for (final String path in kFixedCorpusFiles) {
      test(path, () {
        final CppFixture fixture = CppFixture.load(task, path);
        expect(fixture.meta.task, task);
        expect(fixture.meta.xmlIdSeed, 12345,
            reason: 'a semente fixa de cpp_probe/run.sh');
        expect(fixture.meta.patches, contains(task));
      });
    }
  });

  // ---------------------------------------------------------------------------
  // AdjustOssiaStaffDefFunctor
  // ---------------------------------------------------------------------------
  group('AdjustOssiaStaffDefFunctor', () {
    for (final String path in kFixedCorpusFiles) {
      final String name = path.split('/').last;
      test('$name — VisitMeasureEnd é sempre no-op no C++ (nOssias == 0, '
          'epsilon 0)', () {
        final CppFixture fixture = CppFixture.load(task, path);
        final List<CppRecord> records =
            fixture.where(fn: 'AdjustOssiaStaffDef', test: (r) => r['sub'] == 'VisitMeasureEnd');
        expect(records, isNotEmpty);
        for (final CppRecord record in records) {
          expect(record['nOssias'], 0, reason: record.toString());
          expect(record['hasKeySigAlignment'], 0, reason: record.toString());
          expect(record['hasClefAlignment'], 0, reason: record.toString());
        }
      });

      if (path.contains('/ossia/')) {
        // Was a documented gap through task 04g: `ScoreDefSetCurrentFunctor
        // ::VisitStaff` skips ossia staves on purpose
        // (`setscoredef_functor.dart`, mirroring the C++ guard that defers
        // them to `ScoreDefSetOssiaFunctor`), so an ossia's own
        // `Staff.drawingStaffDef` was never set and
        // `AlignHorizontallyFunctor.visitStaff`
        // (`align_horizontally.dart:714`) asserted `drawingStaffDef != null`
        // unconditionally and failed under `dart test`'s always-on
        // assertions. Task 04h ports `ScoreDefSetOssiaFunctor` and wires it
        // into `Doc.scoreDefSetCurrentDoc`, which sets
        // `staff.drawingStaffDef` for ossia staves too
        // (`setscoredef_functor.dart`, `ScoreDefSetOssiaFunctor.visitStaff`,
        // mirroring `setscoredeffunctor.cpp:755`), so the gap is closed.
        test('$name — produção: doc.layOut() não lança mais (gap fechado '
            'pela 04h) e toda Staff de ossia visível ganha drawingStaffDef',
            () {
          final Doc doc = _loadCorpus(path);
          doc.prepareData();
          doc.layOut();

          final List<Staff> ossiaStaves = [];
          void visit(model.Object object) {
            if (object is Staff && object.isOssia()) ossiaStaves.add(object);
            for (final model.Object child in object.children) {
              visit(child);
            }
          }

          visit(doc);
          expect(ossiaStaves, isNotEmpty);
          for (final Staff staff in ossiaStaves) {
            if (staff.isHidden) continue;
            expect(staff.drawingStaffDef, isNotNull,
                reason: 'ossia staff @n=${staff.n} should have a '
                    'drawingStaffDef set by ScoreDefSetOssiaFunctor');
          }
        });
        continue;
      }

      test('$name — produção: doc.prepareData() + doc.layOut() nunca seta '
          'clefAlignment/keySigAlignment de nenhuma Ossia', () {
        final Doc doc = _loadCorpus(path);
        doc.prepareData();
        doc.layOut();

        final List<Ossia> ossias = [];
        void visit(model.Object object) {
          if (object is Ossia) ossias.add(object);
          for (final model.Object child in object.children) {
            visit(child);
          }
        }

        visit(doc);
        for (final Ossia ossia in ossias) {
          expect(ossia.clefAlignment, isNull);
          expect(ossia.keySigAlignment, isNull);
          expect(ossia.getScoreDefShift(), 0);
        }
      });
    }

    test('Ossia.resetAlignments limpa clefAlignment/keySigAlignment '
        '(mirrors Ossia::ResetAlignments)', () {
      final Ossia ossia = Ossia();
      ossia.setClefAlignment(Alignment());
      ossia.setKeySigAlignment(Alignment());
      expect(ossia.clefAlignment, isNotNull);
      ossia.resetAlignments();
      expect(ossia.clefAlignment, isNull);
      expect(ossia.keySigAlignment, isNull);
    });

    test('Ossia.getScoreDefShift prefere o clef, depois o keySig, depois 0 '
        '(mirrors Ossia::GetScoreDefShift)', () {
      final Ossia ossia = Ossia();
      expect(ossia.getScoreDefShift(), 0);

      final Alignment keySig = Alignment()..setXRel(-40);
      ossia.setKeySigAlignment(keySig);
      expect(ossia.getScoreDefShift(), -40);

      final Alignment clef = Alignment()..setXRel(-90);
      ossia.setClefAlignment(clef);
      expect(ossia.getScoreDefShift(), -90, reason: 'clef takes precedence');
    });

    // ---------------------------------------------------------------------
    // Hand-derived parity: the "real work" branch no file in the fixed
    // corpus reaches (see the library doc comment above). Built directly
    // from `adjustossiastaffdeffunctor.cpp`'s algorithm, not a fixture.
    // ---------------------------------------------------------------------
    test('visitLayerElement acumula keySigWidth/clefWidth como o C++ '
        '(sintético, derivado à mão do algoritmo)', () {
      final Doc doc = Doc();
      final Ossia ossia = Ossia();
      final Staff staff = Staff();
      ossia.addChild(staff);
      final Layer layer = Layer();
      staff.addChild(layer);
      final KeySig keySig = KeySig();
      keySig.updateContentBBoxX(-10, 30); // GetContentX1=-10, GetContentX2=30
      layer.addChild(keySig);
      final Clef clef = Clef();
      clef.updateContentBBoxX(-5, 15);
      layer.addChild(clef);

      final functor = AdjustOssiaStaffDefFunctor(doc);
      // unit = getDrawingUnit(100) = options.unit.value (default 5, times
      // 100/100) — read it directly to keep the test option-agnostic.
      final int unit = doc.getDrawingUnit(functor.staffSize);

      functor.visitLayerElement(keySig);
      expect(functor.keySigWidth, keySig.getContentX1() + keySig.getContentX2() + unit);
      expect(functor.clefWidth, 0);
      expect(functor.ossias, [ossia]);

      functor.visitLayerElement(clef);
      expect(functor.clefWidth, clef.getContentX1() + clef.getContentX2() + unit);
      expect(functor.ossias, [ossia, ossia]);
    });

    test('visitMeasureEnd desloca keySig/clef pela largura acumulada e '
        'propaga para as Ossias, com dedup consecutivo (sintético)', () {
      final Doc doc = Doc();
      final Measure measure = Measure();
      final Ossia ossia = Ossia();
      measure.addChild(ossia);

      final functor = AdjustOssiaStaffDefFunctor(doc)
        ..keySigWidth = 40
        ..clefWidth = 90
        ..keySigAlignment = Alignment()
        ..clefAlignment = Alignment()
        ..ossias.addAll([ossia, ossia, ossia]); // consecutive duplicates

      functor.visitMeasureEnd(measure);

      expect(functor.keySigAlignment!.getXRel(), -40,
          reason: 'mirrors SetXRel(-m_keySigWidth)');
      expect(functor.clefAlignment!.getXRel(), -130,
          reason: 'mirrors SetXRel(-m_keySigWidth - m_clefWidth)');
      expect(functor.ossias, [ossia], reason: 'std::list::unique collapses consecutive duplicates');
      expect(ossia.clefAlignment, same(functor.clefAlignment));
      expect(ossia.keySigAlignment, same(functor.keySigAlignment));
    });

    test('visitAlignment filtra por ALIGNMENT_MEASURE_START e pelos dois '
        'tipos ossia (sintético)', () {
      final Doc doc = Doc();
      final functor = AdjustOssiaStaffDefFunctor(doc);
      final Measure measure = Measure();

      final Alignment keySigAlignment =
          Alignment(null, AlignmentType.scoreDefOssiaKeySig);
      measure.measureAligner.addChild(keySigAlignment);
      expect(functor.visitAlignment(keySigAlignment), FunctorCode.continue_);
      expect(functor.keySigAlignment, same(keySigAlignment));

      final Alignment clefAlignment =
          Alignment(null, AlignmentType.scoreDefOssiaClef);
      measure.measureAligner.addChild(clefAlignment);
      expect(functor.visitAlignment(clefAlignment), FunctorCode.continue_);
      expect(functor.clefAlignment, same(clefAlignment));

      final Alignment defaultAlignment = Alignment();
      expect(
          functor.visitAlignment(defaultAlignment), FunctorCode.siblings,
          reason: 'ALIGNMENT_DEFAULT >= ALIGNMENT_MEASURE_START');
    });
  });

  // ---------------------------------------------------------------------------
  // AdjustNeumeXFunctor
  // ---------------------------------------------------------------------------
  //
  // The C++ fixture's absolute xRel values are not directly reproducible by
  // laying out `neume-002.mei` end to end in this port: the task's own
  // "Armadilhas conhecidas" already flags that neume documents' horizontal
  // spacing diverges from the C++ upstream of this functor ("a largura de
  // sistema hoje sai w=0"), for reasons unrelated to AdjustNeumeXFunctor
  // itself. So — exactly like `adjust_beams_test.dart` / `adjust_x_overflow_
  // test.dart`'s synthetic-per-record technique — each record's own
  // recorded "before" state seeds a minimal synthetic tree, and the
  // assertion is that the *functor* reproduces the record's "after" state,
  // independent of whatever upstream state this port's own pipeline would
  // have produced.
  group('AdjustNeumeXFunctor — neume/neume-002.mei (reconstrução por '
      'registro, epsilon 0)', () {
    late CppFixture fixture;
    late Doc doc;
    late int unit;

    setUpAll(() {
      fixture = CppFixture.load(task, 'test/corpus/neume/neume-002.mei');
      doc = Doc();
      unit = doc.getDrawingUnit(100);
    });

    test('a passada 1 do fixture cobre VisitSyl, VisitNeume, VisitLayerEnd '
        'e VisitStaff', () {
      for (final String sub in [
        'VisitSyl',
        'VisitNeume',
        'VisitLayerEnd',
        'VisitStaff'
      ]) {
        expect(
            fixture.where(
                fn: 'AdjustNeumeX', pass: 1, test: (r) => r['sub'] == sub),
            isNotEmpty,
            reason: sub);
      }
    });

    test('VisitStaff — isNeume bate', () {
      final List<CppRecord> records = fixture.where(
          fn: 'AdjustNeumeX', pass: 1, test: (r) => r['sub'] == 'VisitStaff');
      final List<String> divergences = [];
      for (final CppRecord record in records) {
        final bool expected = record['isNeume'] == 1;
        final Staff staff = Staff()
          ..drawingNotationtype =
              expected ? Notationtype.neume : Notationtype.cmn;
        final functor = AdjustNeumeXFunctor(doc);
        final FunctorCode code = functor.visitStaff(staff);
        final FunctorCode expectedCode =
            expected ? FunctorCode.continue_ : FunctorCode.siblings;
        if (code != expectedCode) {
          divergences
              .add('${record.path}: esperado $expectedCode, obtido $code');
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    test('VisitSyl — xRelAfter e minPosAfter batem', () {
      final List<CppRecord> records = fixture.where(
          fn: 'AdjustNeumeX', pass: 1, test: (r) => r['sub'] == 'VisitSyl');
      expect(records, isNotEmpty);
      final List<String> divergences = [];
      for (final CppRecord record in records) {
        final int xRelBefore = record.require('xRelBefore').toInt();
        final int selfLeft = record.require('selfLeft').toInt();
        final int minPosAfter = record.require('minPosAfter').toInt();
        final int xRelAfterExpected = record.require('xRelAfter').toInt();

        final Syl syl = Syl();
        _attachToMeasure(syl);
        syl.setAlignment(Alignment()..setXRel(xRelBefore));
        // `updateContentBBoxX` takes absolute coordinates (it subtracts
        // `getDrawingX()` itself, evaluated *now* — i.e. against
        // `xRelBefore` — to store the relative content-box offset).
        // `getContentRight()` is read again *after* `visitSyl` may have
        // moved the alignment to `xRelAfter`, so the absolute right edge
        // that reproduces the fixture's `minPosAfter` from the *new*
        // drawingX is `xRelBefore + (minPosAfter - unit - xRelAfter)`.
        syl.updateContentBBoxX(
            selfLeft, xRelBefore + minPosAfter - unit - xRelAfterExpected);

        final functor = AdjustNeumeXFunctor(doc)
          ..minPos = record.require('minPosBefore').toInt();
        functor.visitSyl(syl);

        final int xRelAfter = syl.getAlignment()!.getXRel();
        if (xRelAfter != xRelAfterExpected) {
          divergences.add('${record.path}: xRelAfter esperado '
              '$xRelAfterExpected, obtido $xRelAfter');
        }
        if (functor.minPos != minPosAfter) {
          divergences.add('${record.path}: minPosAfter esperado '
              '$minPosAfter, obtido ${functor.minPos}');
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    test('VisitNeume — xRelAfter, neumeMinPosAfter e minPosAfter batem', () {
      final List<CppRecord> records = fixture.where(
          fn: 'AdjustNeumeX', pass: 1, test: (r) => r['sub'] == 'VisitNeume');
      expect(records, isNotEmpty);
      final List<String> divergences = [];
      for (final CppRecord record in records) {
        final int xRelBefore = record.require('xRelBefore').toInt();
        final int selfLeft = record.require('selfLeft').toInt();
        final int neumeMinPosAfter = record.require('neumeMinPosAfter').toInt();
        final int xRelAfterExpected = record.require('xRelAfter').toInt();

        final Neume neume = Neume();
        _attachToMeasure(neume);
        neume.setAlignment(Alignment()..setXRel(xRelBefore));
        // See the analogous comment in the VisitSyl test above: the content
        // right edge must be chosen so that, evaluated against the *new*
        // (post-mutation) drawingX, it reproduces the fixture's
        // `neumeMinPosAfter`.
        neume.updateContentBBoxX(selfLeft,
            xRelBefore + neumeMinPosAfter - unit - xRelAfterExpected);

        final functor = AdjustNeumeXFunctor(doc)
          ..neumeMinPos = record.require('neumeMinPosBefore').toInt()
          ..minPos = record.require('minPosBefore').toInt();
        functor.visitNeume(neume);

        final int xRelAfter = neume.getAlignment()!.getXRel();
        if (xRelAfter != xRelAfterExpected) {
          divergences.add('${record.path}: xRelAfter esperado '
              '$xRelAfterExpected, obtido $xRelAfter');
        }
        if (functor.neumeMinPos != neumeMinPosAfter) {
          divergences.add('${record.path}: neumeMinPosAfter esperado '
              '$neumeMinPosAfter, obtido ${functor.neumeMinPos}');
        }
        final int minPosAfterExpected = record.require('minPosAfter').toInt();
        if (functor.minPos != minPosAfterExpected) {
          divergences.add('${record.path}: minPosAfter esperado '
              '$minPosAfterExpected, obtido ${functor.minPos}');
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    test('VisitLayerEnd — xRel do alinhamento direito do compasso bate', () {
      final List<CppRecord> records = fixture.where(
          fn: 'AdjustNeumeX',
          pass: 1,
          test: (r) => r['sub'] == 'VisitLayerEnd');
      expect(records, isNotEmpty);
      final List<String> divergences = [];
      for (final CppRecord record in records) {
        final Measure measure = Measure();
        final Staff staff = Staff();
        measure.addChild(staff);
        final Layer layer = Layer();
        staff.addChild(layer);
        measure.measureAligner
            .getRightAlignment()!
            .setXRel(record.require('rightAlignmentXRelBefore').toInt());

        final functor = AdjustNeumeXFunctor(doc)
          ..minPos = record.require('minPos').toInt();
        functor.visitLayerEnd(layer);

        final int expected = record.require('rightAlignmentXRelAfter').toInt();
        final int obtained =
            measure.measureAligner.getRightAlignment()!.getXRel();
        if (obtained != expected) {
          divergences.add(
              '${record.path}: xRel esperado $expected, obtido $obtained');
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });
  });

  group('AdjustNeumeXFunctor — produção (documentação da degradação)', () {
    test('neume-002.mei: doc.prepareData() + doc.layOut() não lança', () {
      final Doc doc = _loadCorpus('test/corpus/neume/neume-002.mei');
      doc.prepareData();
      expect(() => doc.layOut(), returnsNormally);
    });
  });

  group('AdjustNeumeXFunctor — comportamento isolado (sintético)', () {
    test('visitLayer reseta minPos para VRV_UNSET', () {
      final Doc doc = Doc();
      final functor = AdjustNeumeXFunctor(doc)..minPos = 123;
      functor.visitLayer(Layer());
      expect(functor.minPos, meiUnset);
    });

    test('visitStaff é siblings para uma staff não-neume, continue para '
        'neume', () {
      final Doc doc = Doc();
      final functor = AdjustNeumeXFunctor(doc);
      final Staff cmn = Staff();
      expect(functor.visitStaff(cmn), FunctorCode.siblings);

      final Staff neumeStaff = Staff()
        ..drawingNotationtype = Notationtype.neume;
      expect(functor.visitStaff(neumeStaff), FunctorCode.continue_);
    });

    test('visitSyl desloca o alinhamento quando selfLeft < minPos e reseta '
        'neumeMinPos (sintético)', () {
      final Doc doc = Doc();
      final Syl syl = Syl();
      _attachToMeasure(syl);
      syl.setAlignment(Alignment()..setXRel(100));
      // `updateContentBBoxX` takes absolute coordinates: getContentLeft()
      // ends up 100 (== getDrawingX()), getContentRight() 150.
      syl.updateContentBBoxX(100, 150);

      final functor = AdjustNeumeXFunctor(doc)
        ..minPos = 200
        ..neumeMinPos = 77;

      functor.visitSyl(syl);

      expect(functor.neumeMinPos, meiUnset,
          reason: 'marks the next neume as the first of the syllable');
      expect(syl.getAlignment()!.getXRel(), 200,
          reason: '100 + (200 - 100) == 200');
      expect(functor.minPos, syl.getContentRight() + doc.getDrawingUnit(100));
    });
  });
}
