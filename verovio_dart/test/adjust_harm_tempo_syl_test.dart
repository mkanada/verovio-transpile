/// Parity of `AdjustHarmGrpsSpacingFunctor`, `AdjustTempoFunctor` and
/// `AdjustSylSpacingFunctor` against the instrumented C++ (`cpp_probe` task
/// `04e`).
///
/// The C++ fixtures for the four pinned corpus files were extracted with
/// `cpp_probe/patches/04e.patch` (fprintf only, zero removed lines, SVG
/// byte-identical to the clean binary).
///
/// Two of the three functors need the *rendered* content bounding box of
/// their `Harm`/`Tempo` positioners and `Syl` text runs, which this port's
/// headless text-extent approximation does not yet reproduce (see the
/// deviation note atop `adjust_harm_tempo_syl.dart`). Running the full
/// pipeline on the fixed corpus therefore cannot match the C++ numbers, and a
/// closer look at `harm/harm-001.mei` and `tempo/tempo-001.mei` in
/// production surfaced two further, pre-existing, out-of-scope gaps (an
/// initial-measure alignment offset and an upbeat-measure tstamp resolution
/// failure — both documented in `prompts/reports/04e.md`, neither introduced
/// by or fixable within this task).
///
/// So the comparisons here run in two registers:
/// - *Exact fixture parity (epsilon 0)*, wherever the port already has every
///   number the C++ used: [adjustVersePosition] against every `adjusted`/
///   `lastsyl` record of `lyric-001.mei` and `lyric-004.mei`;
///   [calcSylConnectorSpacing]'s default word-spacing branch (back-derived
///   from the same fixtures' `overlap` records); and `AdjustTempoFunctor`'s
///   scoreDef-meterSig branch, reconstructed on a small synthetic tree fed
///   the fixture's own alignment positions.
/// - *Decision-level parity (synthetic content boxes)*: for
///   `AdjustHarmGrpsSpacingFunctor`, every one of harm-001's 13 harms is
///   replayed with a positioner whose content box is exactly the fixture's
///   `contentLeft`/`contentRight`, and the *sign* of the resulting decision
///   (no harm's overlap in this file is ever positive, so no shift is ever
///   queued or applied — matching the fixture) is checked; the port has no
///   public hook exposing the intermediate `overlap` number itself (by
///   design — it is a local variable in the C++ too), so the queued/applied
///   branches are additionally exercised with one hand-derived,
///   fixture-independent case.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/adjust_harm_tempo_syl.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/floating_object.dart' show FloatingObject;
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04e';

int _maxPass(CppFixture fixture, String fn) {
  int maxPass = 0;
  for (final CppRecord rec in fixture.where(fn: fn)) {
    final int? pass = rec.pass;
    if (pass != null && pass > maxPass) maxPass = pass;
  }
  if (maxPass == 0) {
    throw CppFixtureError('${fixture.file}: nenhum registro "$fn"');
  }
  return maxPass;
}

Doc loadCorpusDoc(String path) {
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final String data =
      utf8.decode(File(path).readAsBytesSync(), allowMalformed: true);
  final bool ok = input.import(data);
  if (!ok) throw StateError('MEI import rejected: $path');
  return doc;
}

/// A doc/pages/page/system/measure tree with a single StaffAlignment, the
/// smallest tree in which `Harm`/`Tempo` positioners can be looked up by
/// [SystemAligner.findAllPositionerPointingTo].
(Doc, System, Measure, StaffAlignment) buildHarmTempoTree() {
  final Doc doc = Doc();
  final Pages pages = Pages();
  doc.addChild(pages);
  final Page page = Page();
  pages.addChild(page);
  final System system = System();
  page.addChild(system);
  final Measure measure = Measure();
  system.addChild(measure);
  final Staff staff = Staff()..n = 1;
  // Built directly rather than through `SystemAligner.getStaffAlignment`:
  // that helper also resolves the staff's spacing type against the current
  // scoreDef, which this minimal tree does not have.
  final StaffAlignment staffAlignment = StaffAlignment();
  staffAlignment.setStaff(staff, doc, SpacingType.staff);
  staffAlignment.setParentSystem(system);
  system.systemAligner.addChild(staffAlignment);
  return (doc, system, measure, staffAlignment);
}

/// A detached anchor note with content-box-free positioning: with no
/// Alignment and no Measure ancestor, `getDrawingX()` is 0 (the
/// `Object.getDrawingX()`/`LayerElement.getDrawingX()` fallback), so a
/// positioner's content box set via [FloatingPositioner.updateContentBBoxX]
/// with absolute fixture coordinates lands exactly on those coordinates.
Note detachedAnchor() => Note();

/// Registers a positioner for [object] on [staffAlignment], anchored at
/// [anchor] (a [detachedAnchor]), with content box `[left, right]` (absolute,
/// matching a fixture's `contentLeft`/`contentRight`) and an arbitrary
/// non-empty vertical box (`hasContentBB()` requires both axes).
FloatingPositioner registerPositioner(StaffAlignment staffAlignment,
    FloatingObject object, Note anchor, int left, int right) {
  staffAlignment.setCurrentFloatingPositioner(
      object, anchor, anchor, spanningStartEnd);
  final FloatingPositioner positioner =
      object.getCurrentFloatingPositioner() as FloatingPositioner;
  positioner.updateContentBBoxX(left, right);
  positioner.updateContentBBoxY(0, 1);
  return positioner;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
  });

  // ---------------------------------------------------------------------------
  // Provenance
  // ---------------------------------------------------------------------------
  group('proveniência dos fixtures', () {
    for (final String path in <String>[
      'test/corpus/harm/harm-001.mei',
      'test/corpus/tempo/tempo-001.mei',
      'test/corpus/lyric/lyric-001.mei',
      'test/corpus/lyric/lyric-004.mei',
    ]) {
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
  // adjustVersePosition (Verse::AdjustPosition) — exact fixture parity
  // ---------------------------------------------------------------------------
  group('adjustVersePosition — Verse::AdjustPosition (epsilon 0)', () {
    for (final String path in <String>[
      'test/corpus/lyric/lyric-001.mei',
      'test/corpus/lyric/lyric-004.mei',
    ]) {
      final String name = path.split('/').last;
      test('$name — registros "adjusted"', () {
        final CppFixture fixture = CppFixture.load(task, path);
        final int maxPass = _maxPass(fixture, 'AdjustSylSpacing');
        final List<CppRecord> records = fixture.where(
            fn: 'AdjustSylSpacing',
            pass: maxPass,
            test: (r) => r['branch'] == 'adjusted');
        expect(records, isNotEmpty);
        final List<String> divergences = <String>[];
        for (final CppRecord record in records) {
          final Doc doc = Doc();
          final Verse verse = Verse()
            ..drawingXRel = (record['drawingXRelBefore'] as num).toInt();
          // The overlap fed to AdjustPosition is the pre-mutation value
          // recorded by the matching "overlap" record; re-derive it from the
          // by-reference C++ semantics: overlapAfter is *the same variable*
          // AdjustPosition mutated, so the corresponding "overlap" record's
          // overlapBefore is exactly this call's input.
          final CppRecord overlapRecord = fixture.single(
              fn: 'AdjustSylSpacing',
              pass: maxPass,
              path: record.path,
              test: (r) => r['branch'] == 'overlap');
          final int overlapIn = (overlapRecord['overlapBefore'] as num).toInt();
          final int freeSpaceIn = (overlapRecord['freeSpace'] as num).toInt();

          final result = adjustVersePosition(verse, overlapIn, freeSpaceIn, doc);

          void check(String field, int actual, int expected) {
            if (actual != expected) {
              divergences.add(
                  '${record.path} (linha ${record.lineNumber}): $field '
                  'esperado $expected, obtido $actual');
            }
          }

          check('overlapAfter', result.overlap,
              (record['overlapAfter'] as num).toInt());
          check('nextFreeSpace', result.nextFreeSpace,
              (record['nextFreeSpace'] as num).toInt());
          check('drawingXRelAfter', verse.drawingXRel,
              (record['drawingXRelAfter'] as num).toInt());
        }
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });

      test('$name — registros "lastsyl" (VisitSystemEnd)', () {
        final CppFixture fixture = CppFixture.load(task, path);
        final int maxPass = _maxPass(fixture, 'AdjustSylSpacing');
        final List<CppRecord> records = fixture.where(
            fn: 'AdjustSylSpacing',
            pass: maxPass,
            test: (r) => r['branch'] == 'lastsyl');
        expect(records, isNotEmpty);
        final List<String> divergences = <String>[];
        for (final CppRecord record in records) {
          final Doc doc = Doc();
          final Verse verse = Verse()
            ..drawingXRel = (record['drawingXRelBefore'] as num).toInt();
          final int overlapIn = (record['overlapBefore'] as num).toInt();
          final int freeSpaceIn = (record['freeSpace'] as num).toInt();

          final result = adjustVersePosition(verse, overlapIn, freeSpaceIn, doc);

          if (result.overlap != (record['overlapAfter'] as num).toInt()) {
            divergences.add('${record.path}: overlapAfter esperado '
                '${record['overlapAfter']}, obtido ${result.overlap}');
          }
          if (verse.drawingXRel != (record['drawingXRelAfter'] as num).toInt()) {
            divergences.add('${record.path}: drawingXRelAfter esperado '
                '${record['drawingXRelAfter']}, obtido ${verse.drawingXRel}');
          }
        }
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });
    }
  });

  // ---------------------------------------------------------------------------
  // calcSylConnectorSpacing (Syl::CalcConnectorSpacing) — default branch,
  // back-derived from lyric-001's own numbers and cross-checked.
  // ---------------------------------------------------------------------------
  test(
      'calcSylConnectorSpacing — espaçamento padrão de palavras bate com o '
      'valor usado em todo lyric-001.mei (108 = 90 * 1.20)', () {
    final Doc doc = Doc();
    // doc.getDrawingUnit(100) itself matches the fixture's "syls" shift
    // field (90) for every verse of lyric-001.mei / lyric-004.mei.
    expect(doc.getDrawingUnit(100), 90);
    final Syl syl = Syl();
    expect(calcSylConnectorSpacing(syl, doc, 100), 108);
  });

  // ---------------------------------------------------------------------------
  // AdjustTempoFunctor — exact fixture parity (scoreDef meterSig branch)
  // ---------------------------------------------------------------------------
  test(
      'AdjustTempo — parity exata com o fixture (branch scoreDefMeterSig, '
      'epsilon 0)', () {
    final CppFixture fixture = CppFixture.load(task, 'test/corpus/tempo/tempo-001.mei');
    final int maxPass = _maxPass(fixture, 'AdjustTempo');
    final CppRecord enter = fixture.single(
        fn: 'AdjustTempo',
        pass: maxPass,
        test: (r) => r['branch'] == 'enter');
    final CppRecord staffRec = fixture.single(
        fn: 'AdjustTempo',
        pass: maxPass,
        test: (r) => r['branch'] == 'staff');

    expect(enter['hasStartid'], 0);
    expect(enter['hasScoreDefMeterSigAlignment'], 1);
    expect(staffRec['useScoreDefMeterSig'], 1);

    final (Doc doc, System system, Measure measure, StaffAlignment staffAlignment) =
        buildHarmTempoTree();
    measure.setDrawingXRel((enter['measureDrawingX'] as num).toInt());

    final Alignment meterSigAlign =
        Alignment(Fraction(0), AlignmentType.scoreDefMeterSig);
    measure.measureAligner.addAlignment(meterSigAlign);
    meterSigAlign.setXRel((enter['scoreDefMeterSigXRel'] as num).toInt());

    final Note startNote = Note();
    startNote.setParent(measure);
    final Alignment startAlign = Alignment(Fraction(1), AlignmentType.default_);
    measure.measureAligner.addAlignment(startAlign);
    startNote.setAlignment(startAlign);
    startAlign.setXRel((staffRec['start'] as num).toInt());

    final Tempo tempo = Tempo();
    tempo.setStart(startNote);
    tempo.setParent(measure);

    final int staffN = (staffRec['staffN'] as num).toInt();
    (staffAlignment.getStaff())?.n = staffN;
    system.setSystemCurrentFloatingPositioner(
        staffN, tempo, startNote, startNote);

    final AdjustTempoFunctor functor = AdjustTempoFunctor(doc);
    functor.visitSystem(system);
    functor.visitTempo(tempo);

    final int expectedDrawingXRel =
        (staffRec['left'] as num).toInt() - (staffRec['start'] as num).toInt();
    expect(tempo.drawingXRels[staffN], expectedDrawingXRel);
    expect(expectedDrawingXRel, -570,
        reason: 'valor do fixture: left=735, start=1305');
  });

  // ---------------------------------------------------------------------------
  // AdjustHarmGrpsSpacingFunctor
  // ---------------------------------------------------------------------------
  group('AdjustHarmGrpsSpacingFunctor', () {
    test(
        'decisão de push — nenhum harm de harm-001.mei tem overlap positivo '
        '(igual ao C++: nenhum "queued"/"appliedcross" no fixture)', () {
      final CppFixture fixture =
          CppFixture.load(task, 'test/corpus/harm/harm-001.mei');
      expect(
          fixture.where(fn: 'AdjustHarmGrpsSpacing', test: (r) => r['branch'] == 'queued'),
          isEmpty);
      expect(
          fixture.where(
              fn: 'AdjustHarmGrpsSpacing',
              test: (r) => r['branch'] == 'appliedcross'),
          isEmpty);

      final int maxPass = _maxPass(fixture, 'AdjustHarmGrpsSpacing');
      final List<CppRecord> picked = fixture.where(
          fn: 'AdjustHarmGrpsSpacing',
          pass: maxPass,
          test: (r) => r['branch'] == 'picked');
      expect(picked.length, 13, reason: 'harm-001.mei tem 13 <harm>');

      final (Doc doc, System system, Measure measure0, StaffAlignment staffAlignment) =
          buildHarmTempoTree();

      final AdjustHarmGrpsSpacingFunctor functor =
          AdjustHarmGrpsSpacingFunctor(doc);
      functor.visitSystem(system);
      functor.currentGrp = (picked.first['grpId'] as num).toInt();

      // The fixture's own cross-measure xShift (= the previous measure's
      // GetWidth(), i.e. its ALIGNMENT_MEASURE_END alignment) and right
      // barline alignment XRel for the three measures of this file, so the
      // synthetic measures reproduce the same frame the C++ overlap was
      // computed in (contentLeft/contentRight are measure-relative). The
      // measure-3 right barline XRel (5040) is back-derived from the
      // fixture's "lastharm" record: overlap(-906) = lastHarmContentRight
      // (4134) - rightBarLineXRel, both read straight off the fixture.
      final List<int> perMeasure = <int>[5, 5, 3];
      final List<int> widthAfterMeasure = <int>[5725, 4723, 0];
      final List<int> rightBarLineAfterMeasure = <int>[5712, 4710, 5040];
      int index = 0;
      Measure? lastMeasure;
      for (int m = 0; m < perMeasure.length; ++m) {
        Measure measure;
        if (index == 0) {
          measure = measure0;
        } else {
          measure = Measure();
          system.addChild(measure);
        }
        measure.measureAligner.getRightAlignment()!.setXRel(widthAfterMeasure[m]);
        final Alignment rightBarLineAlign =
            Alignment(Fraction(1), AlignmentType.default_);
        measure.measureAligner.addAlignment(rightBarLineAlign);
        measure.getRightBarLine().setAlignment(rightBarLineAlign);
        rightBarLineAlign.setXRel(rightBarLineAfterMeasure[m]);
        lastMeasure = measure;
        for (int i = 0; i < perMeasure[m]; ++i) {
          final CppRecord record = picked[index++];
          final Note anchor = detachedAnchor();
          anchor.setParent(measure);
          final Alignment alignment =
              Alignment(Fraction(i + 1), AlignmentType.default_);
          measure.measureAligner.addAlignment(alignment);
          anchor.setAlignment(alignment);
          final Harm harm = Harm()..drawingGrpId = functor.currentGrp;
          harm.setStart(anchor);
          harm.setParent(measure);
          registerPositioner(staffAlignment, harm, anchor,
              (record['contentLeft'] as num).toInt(),
              (record['contentRight'] as num).toInt());
          functor.visitHarm(harm);
        }
        functor.visitMeasureEnd(measure);
      }
      functor.visitSystemEnd(system); // currentGrp != 0: the "adjusting" branch

      expect(functor.overlappingHarm, isEmpty,
          reason: 'todo overlap de harm-001.mei é <= 0 (nenhum push)');
      expect(functor.previousMeasure, lastMeasure);
    });

    test(
        'push entre compassos — caso derivado à mão (não vem do fixture: '
        'harm-001.mei nunca exercita overlap > 0), confere a fórmula e a '
        'aplicação imediata via AdjustProportionally', () {
      final (Doc doc, System system, Measure measure1, StaffAlignment staffAlignment) =
          buildHarmTempoTree();
      final Measure measure2 = Measure();

      final AdjustHarmGrpsSpacingFunctor functor =
          AdjustHarmGrpsSpacingFunctor(doc);
      functor.visitSystem(system);
      functor.currentGrp = 1;

      // First harm of the system: content box [0, 400] (width 400).
      final Note anchor1 = detachedAnchor();
      anchor1.setParent(measure1);
      final Harm harm1 = Harm()..drawingGrpId = 1;
      harm1.setStart(anchor1);
      harm1.setParent(measure1);
      registerPositioner(staffAlignment, harm1, anchor1, 0, 400);
      functor.visitHarm(harm1);
      functor.visitMeasureEnd(measure1);

      expect(functor.previousHarmStart, anchor1);
      expect(functor.previousMeasure, measure1,
          reason: 'VisitMeasureEnd guarda a measure para o próximo harm '
              'cross-measure');
      system.addChild(measure2);

      // Second harm, in the next measure, whose content box starts before
      // the first harm's content box ends (by construction: overlap =
      // 400 - (100 + measure1.getWidth()) + wordSpace > 0 when
      // measure1.getWidth() is small). `MeasureAligner`'s own constructor
      // already creates the ALIGNMENT_MEASURE_END alignment `GetWidth()`
      // reads — just give it a XRel.
      measure1.measureAligner.getRightAlignment()!.setXRel(50);
      final Alignment rightBarLineAlign =
          Alignment(Fraction(1), AlignmentType.default_);
      measure1.measureAligner.addAlignment(rightBarLineAlign);
      measure1.getRightBarLine().setAlignment(rightBarLineAlign);
      rightBarLineAlign.setXRel(50);
      // The pushed-alignment start is harm1's own alignment; give it one.
      final Alignment harm1StartAlign =
          Alignment(Fraction(0), AlignmentType.default_);
      measure1.measureAligner.addAlignment(harm1StartAlign);
      anchor1.setAlignment(harm1StartAlign);
      harm1StartAlign.setXRel(0);

      final Note anchor2 = detachedAnchor();
      anchor2.setParent(measure2);
      final Harm harm2 = Harm()..drawingGrpId = 1;
      harm2.setStart(anchor2);
      harm2.setParent(measure2);
      registerPositioner(staffAlignment, harm2, anchor2, 100, 500);
      functor.visitHarm(harm2);

      // overlap = prevContentRight(400) - (currContentLeft(100) +
      // xShift(measure1.getWidth()=50)) + wordSpace(180) = 430 > 0.
      final int wordSpace = adjustToLyricSize(doc, 2 * doc.getDrawingUnit(100));
      final int expectedOverlap = 400 - (100 + 50) + wordSpace;
      expect(expectedOverlap, greaterThan(0));

      // Applied immediately (cross-measure): only the right barline
      // alignment (>= the pushed range's end) moves, by exactly the
      // overlap — AdjustProportionally's own math, already validated by
      // earlier tasks; this checks that AdjustHarmGrpsSpacingFunctor
      // assembled the right tuple and called it right away.
      expect(rightBarLineAlign.getXRel(), 50 + expectedOverlap);
      expect(harm1StartAlign.getXRel(), 0, reason: 'the start of the pushed range never moves');
      expect(functor.overlappingHarm, isEmpty,
          reason: 'cleared right after the immediate apply');
      expect(functor.previousHarmStart, anchor2);
    });
  });

  // ---------------------------------------------------------------------------
  // Production run: no crash, and the documented degradation of
  // AdjustSylSpacing (Syl never gets a content box in headless mode, so
  // every verse's syls list is always filtered down to empty).
  // ---------------------------------------------------------------------------
  group('execução em produção (documentação da degradação)', () {
    for (final String path in <String>[
      'test/corpus/harm/harm-001.mei',
      'test/corpus/tempo/tempo-001.mei',
      'test/corpus/lyric/lyric-001.mei',
      'test/corpus/lyric/lyric-004.mei',
    ]) {
      test('$path: doc.prepareData() + doc.layOut() não lança', () {
        final Doc doc = loadCorpusDoc(path);
        expect(() {
          doc.prepareData();
          doc.layOut();
        }, returnsNormally);
      });
    }

    test(
        'lyric-001.mei / lyric-004.mei: AdjustSylSpacingFunctor nunca visita '
        'nenhum Verse — bug pré-existente de AttNIntegerComparison/Filters '
        'documentado no relatório, não introduzido nem corrigível nesta '
        'tarefa (ambos os arquivos têm <verse> sem @n, e o casamento de '
        'filtro compara o int? nulo do atributo contra o inteiro '
        '`meiUnset` construído pela árvore de versos, que nunca são iguais '
        'em Dart)', () {
      for (final String path in <String>[
        'test/corpus/lyric/lyric-001.mei',
        'test/corpus/lyric/lyric-004.mei',
      ]) {
        final Doc doc = loadCorpusDoc(path);
        doc.prepareData();
        doc.layOut();

        int verses = 0;
        void walk(model.Object object) {
          if (object is Verse) {
            ++verses;
            expect(object.drawingXRel, 0,
                reason: '$path: ${object.className} nunca é visitado pelo '
                    'functor (veja o motivo acima), então fica no valor '
                    'default de LayerElement.drawingXRel');
          }
          for (final model.Object child in object.children) {
            walk(child);
          }
        }

        walk(doc);
        expect(verses, greaterThan(0));
      }
    });
  });
}
