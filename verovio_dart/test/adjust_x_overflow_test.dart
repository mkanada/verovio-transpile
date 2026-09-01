/// Parity of `AdjustXOverflowFunctor`, `CacheHorizontalLayoutFunctor` and
/// `CalcSpanningBeamSpansFunctor` against the instrumented C++ (`cpp_probe`
/// task `04f`).
///
/// The C++ fixtures for the four pinned corpus files were extracted with
/// `cpp_probe/patches/04f.patch` (fprintf only, zero removed lines, SVG
/// byte-identical to the clean binary).
///
/// None of the three functors ever reaches its "real work" branch in the
/// fixed corpus, under this project's plain rendering invocation
/// (`-x 12345 -o out.svg`, no forced narrow page / `--breaks`):
/// - `AdjustXOverflowFunctor` never finds an actual overflow (its
///   `VisitSystemEnd` only ever takes `noop_nocandidate`/`noop_nooverflow`).
/// - `CacheHorizontalLayoutFunctor` only ever runs with `restore=false` (a
///   single load/render pass never triggers the restore branch).
/// - `CalcSpanningBeamSpansFunctor`'s one `beamSpan` file
///   (`beamspan/beamspan-001.mei`) never actually crosses a system boundary
///   under this invocation (both its measures land in the same system), so
///   it only ever takes `noop_samesystem`.
///
/// So the comparisons here run in two registers, exactly like task 04e's:
/// - *Exact fixture parity (epsilon 0)*: every early-return / bookkeeping
///   branch the corpus does exercise, reconstructed on synthetic trees fed
///   the fixture's own recorded values.
/// - *Hand-derived parity*: the "real work" branches no file in the corpus
///   reaches — `AdjustXOverflowFunctor`'s overflow-applied branch,
///   `CacheHorizontalLayoutFunctor`'s restore branch, and
///   `BeamSpan.addSpanningSegment`'s segment creation — verified against the
///   C++ algorithm on hand-built synthetic state, not a fixture.
///
/// See `prompts/reports/04f.md` for the full analysis.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/adjust_x_overflow.dart';
import 'package:verovio_dart/src/layout/cache_horizontal_layout.dart'
    show CacheHorizontalLayoutFunctor;
import 'package:verovio_dart/src/layout/calc_spanning_beam_spans.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show SpacingType, StaffAlignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Horizontalalignment;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/beam_segment.dart'
    show BeamElementCoord, BeamSpanSegment;
import 'package:verovio_dart/src/model/control_element.dart' show ControlElement;
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/floating_object.dart' show FloatingObject;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Rend;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04f';

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

/// The `measure[N]` prefix of a fixture `path` (everything up to and
/// including the first `/`-delimited segment) — the grouping key for
/// `AdjustXOverflowFunctor`'s per-measure `currentWidest` reset.
String _measureOf(String path) => path.split('/').first;

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
/// smallest tree in which control-element positioners can be looked up by
/// `SystemAligner.findAllPositionerPointingTo` (same shape as task 04e's
/// `buildHarmTempoTree`).
(Doc, System, Measure, StaffAlignment) buildTree() {
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
  final StaffAlignment staffAlignment = StaffAlignment();
  staffAlignment.setStaff(staff, doc, SpacingType.staff);
  staffAlignment.setParentSystem(system);
  system.systemAligner.addChild(staffAlignment);
  return (doc, system, measure, staffAlignment);
}

/// A detached anchor note: with no Alignment and no Measure ancestor,
/// `getFirstAncestor(ClassId.measure)` is null.
Note detachedAnchor() => Note();

/// Registers a positioner for [object] on [staffAlignment], anchored at
/// [anchor], with content box `[left, right]` and an arbitrary non-empty
/// vertical box (`hasContentBB()` requires both axes) — same helper shape as
/// task 04e's `registerPositioner`.
FloatingPositioner registerPositioner(StaffAlignment staffAlignment,
    FloatingObject object, model.Object anchor, int left, int right) {
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
      'test/corpus/section/section-001.mei',
      'test/corpus/beamspan/beamspan-001.mei',
      'test/corpus/dir/dir-001.mei',
      'test/corpus/dynam/dynam-001.mei',
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
  // AdjustXOverflowFunctor
  // ---------------------------------------------------------------------------
  group('AdjustXOverflowFunctor', () {
    test('getChildRendAlignment — right aligned rend', () {
      final Dir dir = Dir();
      final Rend rend = Rend()..halign = Horizontalalignment.right;
      dir.addChild(rend);
      expect(dir.getChildRendAlignment(), Horizontalalignment.right);
    });

    test('getChildRendAlignment — no rend', () {
      expect(Dir().getChildRendAlignment(), Horizontalalignment.none);
    });

    for (final String name in <String>['dir-001', 'dynam-001']) {
      test('$name — VisitControlElement (bookkeeping do maior positioner, '
          'epsilon 0)', () {
        final String path = name.startsWith('dir')
            ? 'test/corpus/dir/dir-001.mei'
            : 'test/corpus/dynam/dynam-001.mei';
        final CppFixture fixture = CppFixture.load(task, path);
        final int maxPass = _maxPass(fixture, 'AdjustXOverflow');
        final List<CppRecord> records = fixture.where(
            fn: 'AdjustXOverflow',
            pass: maxPass,
            test: (r) => r['sub'] == 'VisitControlElement');
        expect(records, isNotEmpty);

        final (doc, system, measure, staffAlignment) = buildTree();
        final adjustXOverflow = AdjustXOverflowFunctor(90)
          ..currentSystem = system;
        expect(doc, isNotNull); // keeps `doc` reachable/documented in scope

        final List<String> divergences = <String>[];
        String? currentMeasureGroup;
        for (final CppRecord record in records) {
          // `VisitMeasure` resets `currentWidest` at each measure boundary
          // (dynam-001's final pass spans three measures) — the fixture has
          // no explicit boundary marker, so the `measure[N]` prefix of the
          // path is the grouping key.
          final String group = _measureOf(record.path);
          if (group != currentMeasureGroup) {
            currentMeasureGroup = group;
            adjustXOverflow.visitMeasure(measure);
          }

          final ClassId classId =
              name.startsWith('dir') ? ClassId.dir : ClassId.dynam;
          final ControlElement element =
              classId == ClassId.dir ? Dir() : Dynam();
          measure.addChild(element);
          // Each fixture record's `widestContentRight` is already the
          // running max after this element — within one measure group both
          // dir-001 and dynam-001's sequences are strictly increasing, so
          // giving this element's own positioner exactly that content-right
          // reproduces the running max faithfully.
          registerPositioner(staffAlignment, element, detachedAnchor(), 0,
              (record['widestContentRight'] as num).toInt());

          final FunctorCode code = adjustXOverflow.visitControlElement(element);
          if (code != FunctorCode.continue_) {
            divergences.add('${record.path}: esperado FunctorCode.continue_, '
                'obtido $code');
          }
          final int? widest = adjustXOverflow.currentWidest?.getContentRight();
          if (widest != (record['widestContentRight'] as num).toInt()) {
            divergences.add('${record.path}: widestContentRight esperado '
                '${record['widestContentRight']}, obtido $widest');
          }
        }
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });
    }

    test(
        'dir-001 / dynam-001 / section-001 — VisitSystemEnd "noop_nooverflow" '
        '(measureRightX, epsilon 0)', () {
      final List<String> divergences = <String>[];
      for (final String path in <String>[
        'test/corpus/dir/dir-001.mei',
        'test/corpus/dynam/dynam-001.mei',
        'test/corpus/section/section-001.mei',
      ]) {
        final CppFixture fixture = CppFixture.load(task, path);
        final List<CppRecord> records = fixture.where(
            fn: 'AdjustXOverflow',
            test: (r) =>
                r['sub'] == 'VisitSystemEnd' &&
                r['branch'] == 'noop_nooverflow');
        expect(records, isNotEmpty, reason: path);
        for (final CppRecord record in records) {
          // Reconstruct exactly the precondition this branch reads:
          // `measureRightX = lastMeasure.getDrawingX() + getRightBarLineLeft() - margin`,
          // with the measure's own drawingXRel at 0 (system too) so
          // `getRightBarLineLeft()` alone carries the fixture's number.
          const int margin = 90;
          final int rightBarLineLeft =
              (record['measureRightX'] as num).toInt() + margin;
          final (_, system, measure, staffAlignment) = buildTree();
          measure.setDrawingXRel(0);
          measure.measureAligner
              .getRightBarLineAlignment()!
              .setXRel(rightBarLineLeft);

          final int widest = (record['widestContentRight'] as num).toInt();
          final Dynam dynam = Dynam();
          measure.addChild(dynam);
          registerPositioner(staffAlignment, dynam, detachedAnchor(), 0, widest);

          final adjustXOverflow = AdjustXOverflowFunctor(margin)
            ..currentSystem = system
            ..lastMeasure = measure
            ..currentWidest = dynam.getCurrentFloatingPositioner() as FloatingPositioner;

          final int computedMeasureRightX =
              measure.getDrawingX() + measure.getRightBarLineLeft() - margin;
          if (computedMeasureRightX != (record['measureRightX'] as num).toInt()) {
            divergences.add('${record.path}: measureRightX esperado '
                '${record['measureRightX']}, obtido $computedMeasureRightX');
          }

          final int rightXBefore =
              measure.measureAligner.getRightBarLineAlignment()!.getXRel();
          adjustXOverflow.visitSystemEnd(system);
          final int rightXAfter =
              measure.measureAligner.getRightBarLineAlignment()!.getXRel();
          if (rightXAfter != rightXBefore) {
            divergences.add('${record.path}: noop_nooverflow não deveria '
                'ajustar a barra direita (antes $rightXBefore, depois '
                '$rightXAfter)');
          }
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    test('section-001 — VisitSystemEnd "noop_nocandidate" (estrutural)', () {
      final CppFixture fixture = CppFixture.load(
          task, 'test/corpus/section/section-001.mei');
      final List<CppRecord> records = fixture.where(
          fn: 'AdjustXOverflow',
          test: (r) =>
              r['sub'] == 'VisitSystemEnd' && r['branch'] == 'noop_nocandidate');
      expect(records, isNotEmpty);
      for (final CppRecord record in records) {
        expect(record['hasLastMeasure'], anyOf(0, 1));
        // hasWidest is always 0 in every fixture record of this branch: no
        // candidate means the widest-positioner tracking never ran.
        expect(record['hasWidest'], 0);
      }

      final (_, system, measure, _) = buildTree();
      final adjustXOverflow = AdjustXOverflowFunctor(90)
        ..currentSystem = system
        ..lastMeasure = measure
        ..currentWidest = null;
      expect(adjustXOverflow.visitSystemEnd(system), FunctorCode.continue_);
    });

    test(
        'branch "applied" — overflow > 0 desloca a barra direita (sintético, '
        'derivado à mão do algoritmo do C++, não do fixture)', () {
      final (_, system, measure, staffAlignment) = buildTree();
      const int margin = 90;

      // Link the barlines to their measureAligner alignments (normally done
      // by AlignHorizontallyFunctor, which this synthetic tree skips).
      measure.getLeftBarLine().setAlignment(
          measure.measureAligner.getLeftBarLineAlignment());
      measure.getRightBarLine().setAlignment(
          measure.measureAligner.getRightBarLineAlignment());
      measure.measureAligner.getRightBarLineAlignment()!.setXRel(1000);
      measure.setDrawingXRel(0);

      final Dir dir = Dir();
      measure.addChild(dir);
      // A detached anchor -> objectXMeasure is null -> "cross measure"
      // branch: left = measure.getLeftBarLine().getAlignment() (xRel 0).
      registerPositioner(staffAlignment, dir, detachedAnchor(), 0, 1200);

      final adjustXOverflow = AdjustXOverflowFunctor(margin)
        ..currentSystem = system
        ..lastMeasure = measure
        ..currentWidest = dir.getCurrentFloatingPositioner() as FloatingPositioner;

      // measureRightX = 0 + 1000 - 90 = 910; overflow = 1200 - 910 = 290.
      final int measureRightX =
          measure.getDrawingX() + measure.getRightBarLineLeft() - margin;
      expect(measureRightX, 910);

      adjustXOverflow.visitSystemEnd(system);

      expect(measure.measureAligner.getLeftBarLineAlignment()!.getXRel(), 0,
          reason: 'left of the (left, right, overflow) tuple is unshifted');
      expect(measure.measureAligner.getRightBarLineAlignment()!.getXRel(), 1290,
          reason: 'right barline shifts by exactly the overflow (290)');
    });

    test('Measure.getDrawingOverflow — reusa AdjustXOverflowFunctor '
        '(sintético)', () {
      final (_, system, measure, staffAlignment) = buildTree();
      // Unlike `AdjustXOverflowFunctor::VisitSystemEnd` (which reads
      // `GetRightBarLineLeft()`), `Measure::GetDrawingOverflow` computes
      // `measureRightX` from `GetWidth()` — the *measureEnd* alignment, not
      // the right-barline one.
      measure.measureAligner.getRightAlignment()!.setXRel(1000);
      measure.setDrawingXRel(0);
      expect(system, isNotNull);

      // No control element yet: no candidate -> 0.
      expect(measure.getDrawingOverflow(), 0);

      final Dynam dynam = Dynam();
      measure.addChild(dynam);
      registerPositioner(staffAlignment, dynam, detachedAnchor(), 0, 1150);
      // measureRightX (margin 0, per Measure::GetDrawingOverflow's own
      // `AdjustXOverflowFunctor(0)`) = getDrawingX()(0) + getWidth()(1000) = 1000;
      // overflow = 1150 - 1000 = 150.
      expect(measure.getDrawingOverflow(), 150);
    });
  });

  // ---------------------------------------------------------------------------
  // CacheHorizontalLayoutFunctor
  // ---------------------------------------------------------------------------
  group('CacheHorizontalLayoutFunctor', () {
    test('section-001 — VisitMeasure, todos os registros (restore=false, '
        'epsilon 0)', () {
      final CppFixture fixture = CppFixture.load(
          task, 'test/corpus/section/section-001.mei');
      final List<CppRecord> records = fixture.where(
          fn: 'CacheHorizontalLayout',
          test: (r) => r['sub'] == 'VisitMeasure' && r['restore'] == 0);
      expect(records, isNotEmpty);
      final List<String> divergences = <String>[];
      for (final CppRecord record in records) {
        final System system = System();
        final Measure measure = Measure();
        system.addChild(measure);
        measure.setDrawingXRel((record['xRelBefore'] as num).toInt());

        measure.cacheXRel();

        void check(String field, int actual, num expected) {
          if (actual != expected) {
            divergences.add('${record.path}: $field esperado $expected, '
                'obtido $actual');
          }
        }

        check('xRelAfter', measure.getDrawingXRel(), record['xRelAfter']);
        check('cachedAfter', measure.getCachedXRel(), record['cachedAfter']);
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    test('section-001 — VisitLayerElement, todos os registros (restore=false, '
        'epsilon 0)', () {
      final CppFixture fixture = CppFixture.load(
          task, 'test/corpus/section/section-001.mei');
      final List<CppRecord> records = fixture.where(
          fn: 'CacheHorizontalLayout',
          test: (r) => r['sub'] == 'VisitLayerElement' && r['restore'] == 0);
      expect(records, isNotEmpty);
      final List<String> divergences = <String>[];
      for (final CppRecord record in records) {
        final LayerElement element = LayerElement();
        element.drawingXRel = (record['xRelBefore'] as num).toInt();
        element.drawingYRel = (record['yRelBefore'] as num).toInt();

        element.cacheXRel();
        element.cacheYRel();

        void check(String field, int actual, num expected) {
          if (actual != expected) {
            divergences.add('${record.path}: $field esperado $expected, '
                'obtido $actual');
          }
        }

        check('xRelAfter', element.drawingXRel, record['xRelAfter']);
        check('yRelAfter', element.drawingYRel, record['yRelAfter']);
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    test('CacheHorizontalLayoutFunctor.visitMeasure dispara cacheXRel do '
        'próprio functor (visitBarLine incluso)', () {
      final Doc doc = Doc();
      final System system = System();
      final Measure measure = Measure();
      system.addChild(measure);
      measure.setDrawingXRel(123);
      measure.getLeftBarLine().drawingXRel = 5;
      measure.getRightBarLine().drawingXRel = 7;

      final cacheHorizontalLayout = CacheHorizontalLayoutFunctor(doc);
      expect(cacheHorizontalLayout.visitMeasure(measure), FunctorCode.continue_);

      expect(measure.getCachedXRel(), 123);
      expect(measure.getLeftBarLine().drawingXRel, 5); // cacheXRel doesn't
      // mutate drawingXRel on the store pass — the barLine visit is only
      // observable once restore=true is exercised.

      cacheHorizontalLayout.restore = true;
      measure.setDrawingXRel(999);
      measure.getLeftBarLine().drawingXRel = 999;
      cacheHorizontalLayout.visitMeasure(measure);
      expect(measure.getDrawingXRel(), 123);
      expect(measure.getLeftBarLine().drawingXRel, 5,
          reason: 'visitBarLine(leftBarLine) restored it too');
    });

    test('CacheXRel/CacheYRel — restore=true restaura o valor gravado '
        '(sintético, derivado à mão do algoritmo do C++)', () {
      final LayerElement element = LayerElement()
        ..drawingXRel = 42
        ..drawingYRel = -7;
      element.cacheXRel(); // store: cachedXRel = 42
      element.cacheYRel(); // store: cachedYRel = -7
      element.drawingXRel = 999;
      element.drawingYRel = 999;
      element.cacheXRel(restore: true);
      element.cacheYRel(restore: true);
      expect(element.drawingXRel, 42);
      expect(element.drawingYRel, -7);

      final Measure measure = Measure();
      final System system = System()..addChild(measure);
      expect(system, isNotNull);
      measure.setDrawingXRel(42);
      measure.cacheXRel(); // store
      measure.setDrawingXRel(999);
      measure.cacheXRel(restore: true);
      expect(measure.getDrawingXRel(), 42);

      final Arpeg arpeg = Arpeg()..drawingXRel = 15;
      arpeg.cacheXRel(); // store
      arpeg.drawingXRel = 999;
      arpeg.cacheXRel(restore: true);
      expect(arpeg.drawingXRel, 15);
    });
  });

  // ---------------------------------------------------------------------------
  // CalcSpanningBeamSpansFunctor
  // ---------------------------------------------------------------------------
  group('CalcSpanningBeamSpansFunctor', () {
    test('beamspan-001.mei — nunca cruza sistema sob esta invocação: só o '
        'ramo "noop_samesystem" (epsilon 0, produção)', () {
      final CppFixture fixture = CppFixture.load(
          task, 'test/corpus/beamspan/beamspan-001.mei');
      final List<CppRecord> records =
          fixture.where(fn: 'CalcSpanningBeamSpans');
      expect(records, isNotEmpty);
      expect(records.every((r) => r['branch'] == 'noop_samesystem'), isTrue,
          reason: 'se isto falhar, o corpus passou a cruzar sistema e a '
              'suíte precisa de um caso real de segmentação');

      final Doc doc = loadCorpusDoc('test/corpus/beamspan/beamspan-001.mei');
      doc.prepareData();
      final List<BeamSpan> beamSpans = doc
          .findAllDescendantsByType(ClassId.beamSpan)
          .cast<BeamSpan>();
      expect(beamSpans, hasLength(1));
      // Matches the fixture: the beamSpan never leaves its single initial
      // segment (InitBeamSegments' seed), because start/end share a system.
      expect(beamSpans.single.getSegmentCount(), 1);
    });

    test('addSpanningSegment — cria um segmento por sistema (sintético, '
        'nenhum arquivo do corpus fixado cruza sistema sob esta invocação)',
        () {
      final Doc doc = Doc();
      final Pages pages = Pages();
      doc.addChild(pages);
      final Page page = Page();
      pages.addChild(page);

      final System system1 = System();
      final System system2 = System();
      page.addChild(system1);
      page.addChild(system2);

      Measure buildMeasure(System system, List<Note> notes) {
        final Measure measure = Measure();
        system.addChild(measure);
        final Staff staff = Staff()..n = 1;
        measure.addChild(staff);
        final Layer layer = Layer()..n = 1;
        staff.addChild(layer);
        for (final Note note in notes) {
          layer.addChild(note);
        }
        return measure;
      }

      final List<Note> notes1 = [Note(), Note()];
      final List<Note> notes2 = [Note(), Note()];
      final Measure measure1 = buildMeasure(system1, notes1);
      buildMeasure(system2, notes2);

      final BeamSpan beamSpan = BeamSpan();
      measure1.addChild(beamSpan);
      beamSpan.start = notes1.first;
      beamSpan.end = notes2.last;
      final List<model.Object> beamedElements = [...notes1, ...notes2];
      beamSpan.setBeamedElements(beamedElements);

      // Simulates what `BeamDrawingInterface::InitCoords`
      // (`CalcStemFunctor::VisitBeamSpan`, calcstemfunctor.cpp:80) would
      // have populated: one coord per beamed element, in order, `element`
      // pointing back at it. Production now calls `initCoords` for real
      // (task 05-40 loop 05); this synthetic doc has no layout pass, so the
      // test still seeds the coords by hand.
      for (final model.Object element in beamedElements) {
        beamSpan.beamElementCoordsOwned
            .add(BeamElementCoord()..element = element);
      }

      expect(beamSpan.getSegmentCount(), 1,
          reason: 'InitBeamSegments seeds exactly one segment');

      final calcSpanningBeamSpans = CalcSpanningBeamSpansFunctor(doc);
      calcSpanningBeamSpans.visitBeamSpan(beamSpan);

      // Two systems -> two segments: the initial one (reused, index 0) for
      // beamSpan's own system (system1, where it is encoded), and one new
      // segment appended for system2.
      expect(beamSpan.getSegmentCount(), 2);

      final BeamSpanSegment ownSegment = beamSpan.getSegment(0);
      expect(ownSegment.staff, isNotNull);
      expect(ownSegment.layer, isNotNull);
      expect(identical(ownSegment.beginCoord?.element, notes1.first), isTrue);
      expect(identical(ownSegment.endCoord?.element, notes1.last), isTrue);
      expect(ownSegment.spanningType, spanningStart);
      expect(identical(ownSegment.measure, measure1), isTrue);

      final BeamSpanSegment otherSegment = beamSpan.getSegment(1);
      expect(identical(otherSegment.beginCoord?.element, notes2.first), isTrue);
      expect(identical(otherSegment.endCoord?.element, notes2.last), isTrue);
      expect(otherSegment.spanningType, spanningEnd);
      expect(identical((otherSegment.layer as Layer).getFirstAncestor(ClassId.system), system2),
          isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Production run doesn't throw
  // ---------------------------------------------------------------------------
  group('execução em produção (documentação da degradação)', () {
    for (final String path in <String>[
      'test/corpus/section/section-001.mei',
      'test/corpus/beamspan/beamspan-001.mei',
      'test/corpus/dir/dir-001.mei',
      'test/corpus/dynam/dynam-001.mei',
    ]) {
      test('$path: doc.prepareData() + doc.layOut() não lança', () {
        final Doc doc = loadCorpusDoc(path);
        doc.prepareData();
        expect(() => doc.layOut(), returnsNormally);
      });
    }
  });
}
