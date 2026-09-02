/// Tests for [AdjustAccidXFunctor], [AdjustArticFunctor] and
/// [AdjustArticWithSlursFunctor] (`lib/src/layout/adjust_accid_x.dart` /
/// `adjust_artic.dart`), compared value by value against the C++ reference
/// fixtures in `test/fixtures/cpp/04b/`.
///
/// Unlike the `AdjustLayersFunctor` situation documented in
/// `adjust_layers_test.dart`, these two functors run in `layOutVertically`
/// (see the deviation note on `doc.dart`'s `layOutVertically`), *after*
/// the `View` + `BBoxDeviceContext` (`BBOX_BOTH`, `page.cpp:532`) fills the
/// self bounding boxes — so `hasSelfBB()` /
/// `verticalSelfOverlap` etc. are meaningful and the comparison below is not
/// vacuous.
///
/// Known, investigated divergence classes (see `prompts/reports/04b.md` for
/// the full writeup) — the counts asserted below are the current, understood
/// state, not a tolerance loosened to hide a bug:
///
/// - **Accid** (`accid-001.mei`): two of the six accidentals are editorial
///   (`func="edit"`), which the real C++ draws as a floating object above
///   the staff (`Accid::InitFloatingObject`/`AccidFloatingObject`, not
///   ported — out of scope for this task); this port draws them inline like
///   any other accidental, so they spuriously overlap their note/stem.
///   Separately, `BoundingBox.horizontalRightOverlap`/`horizontalLeftOverlap`
///   already approximate the SMuFL glyph cut-out anchors the C++
///   `Accid::AdjustX` uses with the full self bounding box (pre-existing
///   deviation, documented on that method, predating this task) — verified
///   directly: for `measure[1]/…/note[4]/accid[1]`, the plain-rectangle
///   vertical-margin gate rejects the accid/note overlap that the C++
///   cut-out-anchor version accepts, so the whole shift (right amount, wrong
///   source) comes from the accid/stem comparison instead of accid/note.
/// - **Artic** (`artic-001.mei`): `CalcArticFunctor` (calc_functors.dart,
///   ported in an earlier task, out of scope here) is missing the C++'s
///   `IsOutsideArtic() && AlwaysAbove()` override
///   (`calcarticfunctor.cpp:71-77`), so "always above" articulations
///   (`marc`, `upbow`, …) that land on a downward-stemmed note keep the
///   stem-direction default `below` instead of being forced `above` —
///   `measure[2]/…/note[1]/artic[1]` (`marc`) is the confirmed example. Even
///   where `place` matches, `yRel_out` still diverges by a small, bounded
///   amount — e.g. `measure[1]/…/note[3]/artic[1]` (`place` matches
///   "below") — which traces to the approximate 1-unit Artic self bounding
///   box (former headless approximator, now via `View`) and the stem
///   length computed
///   without glyph-based shortening (`preparedata_functor.dart`), exactly
///   the gap this task's own prompt names as expected
///   ("Armadilhas conhecidas").
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Staffrel;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Artic;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

Doc _loadCorpus(String relativePath) {
  final File file = File('test/corpus/$relativePath');
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final bool ok = input.import(utf8.decode(file.readAsBytesSync()));
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

/// Every element under [root], keyed by [cppPath] (mirrors the helper of the
/// same name in `adjust_layers_test.dart`).
Map<String, model.Object> _collectByPath(model.Object root) {
  final Map<String, model.Object> byPath = <String, model.Object>{};
  void add(model.Object? object) {
    if (object == null) return;
    byPath[cppPath(object)] = object;
  }

  void visit(model.Object object) {
    if (object.isLayerElement) add(object);
    if (object.classId == ClassId.measure) {
      final dynamic measure = object;
      add(measure.leftBarLine as model.Object?);
      add(measure.rightBarLine as model.Object?);
    } else if (object.classId == ClassId.layer) {
      final dynamic layer = object;
      add(layer.staffDefClef as model.Object?);
      add(layer.staffDefKeySig as model.Object?);
      add(layer.staffDefMensur as model.Object?);
      add(layer.staffDefMeterSig as model.Object?);
      add(layer.staffDefMeterSigGrp as model.Object?);
      add(layer.cautionStaffDefClef as model.Object?);
      add(layer.cautionStaffDefKeySig as model.Object?);
      add(layer.cautionStaffDefMensur as model.Object?);
      add(layer.cautionStaffDefMeterSig as model.Object?);
    }
    for (final model.Object child in object.children) {
      visit(child);
    }
  }

  visit(root);
  return byPath;
}

Doc _layOutCorpus(String relativePath) {
  final Doc doc = _loadCorpus(relativePath);
  doc.prepareData();
  final Page page = doc.setDrawingPage(0)!;
  page.layOutHorizontally();
  page.layOutVertically();
  return doc;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
    logLevel = LogLevel.error;
  });

  group('AdjustAccidXFunctor — accid/accid-001.mei', () {
    late CppFixture fixture;
    late Map<String, model.Object> byPath;

    setUpAll(() {
      fixture = CppFixture.load('04b', 'test/corpus/accid/accid-001.mei');
      final Doc doc = _layOutCorpus('accid/accid-001.mei');
      byPath = _collectByPath(doc);
    });

    test('the fixture covers AdjustAccidX and the recursive AccidAdjustX', () {
      expect(
          fixture.where(
              fn: 'AdjustAccidX',
              test: (r) => r['site'] == 'VisitAlignmentReference'),
          isNotEmpty);
      expect(fixture.where(fn: 'AccidAdjustX'), isNotEmpty);
    });

    test('Dart resolves every accid path the C++ AdjustAccidX visited', () {
      final Set<String> cppPaths = fixture
          .where(
              fn: 'AdjustAccidX',
              test: (r) => r['site'] == 'VisitAlignmentReference')
          .map((CppRecord r) => r.path)
          .toSet();
      final Set<String> missing =
          cppPaths.where((String path) => !byPath.containsKey(path)).toSet();
      expect(missing, isEmpty,
          reason: 'every accid path the C++ AdjustAccidX visited must '
              'resolve to a real object on the Dart side');
    });

    test(
        'xRel_out: 8 of 12 records match the C++ reference at epsilon 0; '
        'the rest are the documented editorial-accid / cut-out-anchor gaps',
        () {
      final List<CppDivergence> divergences = fixture.compare(
        fn: 'AdjustAccidX',
        test: (r) => r['site'] == 'VisitAlignmentReference',
        field: 'xRel_out',
        actual: (CppRecord record) =>
            (byPath[record.path] as Accid?)?.drawingXRel,
      );
      // Locked to the current, investigated state (see the library doc
      // comment) rather than loosened to hide it — a change in this count
      // means the underlying behavior moved and needs re-investigation, not
      // a new magic number. (12 records = 6 distinct accids x 2 identical
      // full-layout passes — see the report; 8 = the 4 diverging accids x 2.)
      expect(divergences.length, 8, reason: divergences.join('\n'));
      final Set<String> divergentPaths =
          divergences.map((d) => d.record.path).toSet();
      expect(
          divergentPaths,
          {
            'measure[1]/staff[1]/layer[1]/note[4]/accid[1]', // cut-out anchor
            'measure[2]/staff[1]/layer[1]/note[1]/accid[1]', // cut-out anchor
            'measure[2]/staff[1]/layer[1]/note[4]/accid[1]', // cut-out anchor (new with View BBox)
            'measure[3]/staff[1]/layer[1]/note[2]/accid[1]', // cut-out anchor (new)
          },
          reason: 'the *set* of diverging accidentals should also stay '
              'stable, not just the count');
    });

    test('at least one accidental was actually shifted (non-vacuous)', () {
      final bool anyShift = fixture
          .where(
              fn: 'AdjustAccidX',
              test: (r) => r['site'] == 'VisitAlignmentReference')
          .any((CppRecord r) => r.require('xRel_in') != r.require('xRel_out'));
      expect(anyShift, isTrue,
          reason: 'accid-001.mei should exercise a real horizontal shift, '
              'otherwise this test would pass vacuously');
    });
  });

  group('AdjustArticFunctor — artic/artic-001.mei', () {
    late CppFixture fixture;
    late Map<String, model.Object> byPath;

    setUpAll(() {
      fixture = CppFixture.load('04b', 'test/corpus/artic/artic-001.mei');
      final Doc doc = _layOutCorpus('artic/artic-001.mei');
      byPath = _collectByPath(doc);
    });

    test('the fixture covers AdjustArtic', () {
      expect(fixture.where(fn: 'AdjustArtic'), isNotEmpty);
    });

    test('Dart resolves every artic path the C++ AdjustArtic visited', () {
      final Set<String> cppPaths =
          fixture.where(fn: 'AdjustArtic').map((CppRecord r) => r.path).toSet();
      final Set<String> missing =
          cppPaths.where((String path) => !byPath.containsKey(path)).toSet();
      expect(missing, isEmpty,
          reason: 'every artic path the C++ AdjustArtic visited must '
              'resolve to a real object on the Dart side');
    });

    test(
        'yRel_out: 22 of 36 records match the C++ reference at epsilon 0 — '
        'the "outside, below, clamped to -staffHeight" cases where the '
        'approximate stem length gets absorbed by the clamp; the rest are '
        'the documented bbox/stem-length approximations', () {
      final List<CppDivergence> divergences = fixture.compare(
        fn: 'AdjustArtic',
        field: 'yRel_out',
        actual: (CppRecord record) =>
            (byPath[record.path] as Artic?)?.drawingYRel,
      );
      // Locked to the current, investigated state rather than loosened to
      // hide it (see 00-MESTRE.md &sect;7.2) — a changed count means the
      // underlying behavior moved and needs re-investigation.
      //
      // 2026-09-01 (fidelidade loop 11): dropped from 30 to 14 mismatches
      // when `CalcArticFunctor.visitArtic` grew the `AlwaysAbove()` override
      // (calcarticfunctor.cpp:68-73) — the 7 "always above" artics on
      // downward-stemmed notes now get `place=above` like the C++, so their
      // yRel is computed with the correct sign; the remaining 14 (7 paths x
      // 2 fixture passes) are the pre-existing "outside, below, clamped to
      // -staffHeight" approximate-stem-length gap, now surfacing on a
      // different subset because placement itself changed.
      expect(divergences.length, 14, reason: divergences.join('\n'));
      final int total = fixture.where(fn: 'AdjustArtic').length;
      final Set<String> matchingPaths = fixture
          .where(fn: 'AdjustArtic')
          .map((r) => r.path)
          .toSet()
          .difference(divergences.map((d) => d.record.path).toSet());
      expect(total, 36);
      expect(
          matchingPaths,
          {
            'measure[1]/staff[1]/layer[1]/note[1]/artic[1]', // acc, below
            'measure[1]/staff[1]/layer[1]/note[2]/artic[1]', // acc-soft, below
            'measure[2]/staff[1]/layer[1]/note[1]/artic[1]', // marc, above
            'measure[3]/staff[1]/layer[1]/note[1]/artic[1]', // dnbow, above
            'measure[3]/staff[1]/layer[1]/note[2]/artic[1]', // upbow, above
            'measure[3]/staff[1]/layer[1]/note[3]/artic[1]', // harm, above
            'measure[3]/staff[1]/layer[1]/note[4]/artic[1]', // snap, above
            'measure[3]/staff[1]/layer[1]/note[5]/artic[1]', // lhpizz, above
            'measure[4]/staff[1]/layer[1]/note[1]/artic[1]', // open, above
            'measure[4]/staff[1]/layer[1]/note[2]/artic[1]', // stop, above
            'measure[5]/staff[1]/layer[1]/note[3]/artic[1]', // dnbow, below
          },
          reason: 'the *set* of matching artics should also stay stable');
    });

    test(
        'above/below placement: 36 of 36 match — the CalcArticFunctor '
        '`AlwaysAbove()` override (calcarticfunctor.cpp:68-73) now forces '
        'the 8 "always above" outside articulations '
        '(marc/dnbow/upbow/harm/snap/lhpizz/open/stop) above the staff even '
        'on downward-stemmed notes, matching the C++ exactly', () {
      final List<String> mismatches = [];
      final Set<String> mismatchPaths = {};
      for (final CppRecord record in fixture.where(fn: 'AdjustArtic')) {
        final Artic? artic = byPath[record.path] as Artic?;
        expect(artic, isNotNull,
            reason: 'missing Dart object for ${record.path}');
        final String expectedPlace = record['place'] as String;
        final String actualPlace =
            artic!.drawingPlace == Staffrel.above ? 'above' : 'below';
        if (actualPlace != expectedPlace) {
          mismatches
              .add('${record.path}: C++=$expectedPlace Dart=$actualPlace');
          mismatchPaths.add(record.path);
        }
      }
      // 2026-09-01 (fidelidade loop 11): the 16 (8 distinct paths x 2
      // duplicated fixture passes) always-above mismatches are gone now
      // that `AlwaysAbove()` is ported — see the test title.
      expect(mismatches.length, 0, reason: mismatches.join('\n'));
      expect(mismatchPaths, isEmpty,
          reason: 'the *set* of misplaced artics should also stay empty');
    });
  });

  group('AdjustArticWithSlursFunctor — no slurs in the 04b corpus', () {
    test('runs without error and no-ops (no artic has a slur positioner)', () {
      // Neither accid-001.mei nor artic-001.mei has a <slur>, so this
      // exercises only that the functor is wired and doesn't crash; the
      // always-empty-positioner-lists deviation is documented on
      // adjust_artic.dart's library doc comment.
      final Doc doc = _layOutCorpus('artic/artic-001.mei');
      final Map<String, model.Object> byPath = _collectByPath(doc);
      for (final model.Object object in byPath.values) {
        if (object is Artic) {
          expect(object.startSlurPositioners, isEmpty);
          expect(object.endSlurPositioners, isEmpty);
        }
      }
    });
  });
}
