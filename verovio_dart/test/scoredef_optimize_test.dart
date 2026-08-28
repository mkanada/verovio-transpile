/// Parity of [ScoreDefOptimizeFunctor] and [ScoreDefSetOssiaFunctor]
/// (`lib/src/layout/setscoredef_functor.dart`) against the instrumented C++
/// (`cpp_probe` task `04h`).
///
/// **Corpus files.** `ossia/ossia-001.mei` is the file the task prompt fixes
/// for `ScoreDefSetOssiaFunctor` and is used as-is. For
/// `ScoreDefOptimizeFunctor` the prompt fixes `score/score-002.mei`, but that
/// file empirically never reaches the functor at all: `Doc::CastOffDocBase`
/// only calls `ScoreDefOptimizeDoc` when
/// `Score::ScoreDefNeedsOptimization(m_options->m_condense.GetValue())`
/// returns true, which — with the default `condense=auto` — requires either
/// `scoreDef/@optimize="true"` or more than one `<grpSym>`; score-002.mei has
/// neither (verified: its C++ fixture carries zero `ScoreDefOptimize*`
/// records). `section/section-004.mei` does have `scoreDef/@optimize="true"`
/// (twice — once per section, exercising a restart) and a staff (`n="2"`,
/// Clarinetto) that drops out entirely in its second section, giving the
/// hiding logic something real to do; it is otherwise unused by any Dart test
/// or fixture, so adopting it here does not disturb anything else. See
/// `prompts/reports/04h.md` for the full writeup — the precedent for
/// swapping out a prompt-suggested file that doesn't hold up empirically is
/// `adjust_ossia_neume_test.dart` / `prompts/reports/04g.md`.
///
/// **`--condense-first-page`.** Even with `@optimize="true"`,
/// section-004.mei lays out as a single system, and
/// `ScoreDefOptimizeFunctor::VisitSystem` unconditionally skips the *first*
/// system it ever sees unless `condenseFirstPage` is on (default: off) — so
/// the fixture was generated with `cpp_probe/run.sh --opt
/// --condense-first-page` (see `cpp_probe/run.sh`, extended by this task to
/// support passing extra CLI flags through to the instrumented binary). The
/// Dart side sets the same option before calling `doc.layOut()`. The
/// *default* value of all four `condense*` options is verified independently
/// below, unaffected by that override.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart' show Condense;
import 'package:verovio_dart/src/core/vrvdef.dart'
    show ClassId, VisibilityOptimization;
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Ossia, Staff;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/model/scoredef.dart' show StaffDef, StaffGrp;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04h';

const String kOptimizeCorpusFile = 'test/corpus/section/section-004.mei';
const String kOssiaCorpusFile = 'test/corpus/ossia/ossia-001.mei';

Doc _loadCorpus(String relativePath, {bool condenseFirstPage = false}) {
  final File file = File(relativePath);
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final bool ok = input.import(utf8.decode(file.readAsBytesSync()));
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  if (condenseFirstPage) {
    doc.getOptions().condenseFirstPage.value = true;
  }
  return doc;
}

/// Every object of the document, keyed by its `cppPath()` — mirrors how the
/// C++ side keys its own `probe::Path`-based records.
Map<String, model.Object> _byPath(Doc doc) {
  final Map<String, model.Object> map = {};
  void visit(model.Object object) {
    map[cppPath(object)] = object;
    for (final model.Object child in object.children) {
      visit(child);
    }
  }

  visit(doc);
  return map;
}

/// The staffDef that governs [staff]'s drawing visibility, mirrors
/// `Staff::DrawingIsVisible`'s own lookup: fresh, through the *current
/// system's* scoreDef — not through [Staff.drawingStaffDef], which points
/// into a separate per-measure `ScoreDef` copy that `ScoreDefOptimizeFunctor`
/// never touches (see `Doc.scoreDefOptimizeDoc`).
StaffDef? _visibilityStaffDefFor(Staff staff) {
  final System system = staff.getFirstAncestor(ClassId.system) as System;
  return system.drawingScoreDef?.getStaffDef(staff.n ?? 0);
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
    logLevel = LogLevel.error;
  });

  group('proveniência dos fixtures', () {
    for (final String path in [kOptimizeCorpusFile, kOssiaCorpusFile]) {
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
  // Options — defaults exatos do C++ (options.cpp)
  // ---------------------------------------------------------------------------
  group('condense* — defaults exatos do C++', () {
    test(
        'condense=auto, condenseFirstPage/NotLastSystem/TempoPages=false '
        '(mirrors options.cpp:1009-1025)', () {
      final Doc doc = Doc();
      expect(doc.getOptions().condense.value, Condense.auto);
      expect(doc.getOptions().condenseFirstPage.value, isFalse);
      expect(doc.getOptions().condenseNotLastSystem.value, isFalse);
      expect(doc.getOptions().condenseTempoPages.value, isFalse);
    });

    test(
        'option_CONDENSE enum order bate com options.h:62 '
        '(none, auto, all, encoded)', () {
      expect(Condense.values, [
        Condense.none,
        Condense.auto,
        Condense.all,
        Condense.encoded,
      ]);
    });

    test(
        'ScoreDefOptimizeDoc lê os 4 valores efetivos como o C++ '
        '(epsilon 0, pass 1)', () {
      final CppFixture fixture = CppFixture.load(task, kOptimizeCorpusFile);
      final CppRecord record =
          fixture.single(fn: 'ScoreDefOptimizeDoc', pass: 1);
      expect(record['condense'], Condense.auto.index);
      expect(record['condenseFirstPage'], 1,
          reason: 'fixado via --opt --condense-first-page ao gerar a '
              'fixture — ver o comentário de topo do arquivo');
      expect(record['condenseNotLastSystem'], 0);
      expect(record['condenseTempoPages'], 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ScoreDefOptimizeFunctor
  // ---------------------------------------------------------------------------
  group('ScoreDefOptimizeFunctor — section/section-004.mei', () {
    test(
        'drawingVisibility final de cada StaffDef bate com a fixture '
        '(último registro por staffN na pass 2, epsilon 0)', () {
      final CppFixture fixture = CppFixture.load(task, kOptimizeCorpusFile);
      final Doc doc = _loadCorpus(kOptimizeCorpusFile, condenseFirstPage: true);
      doc.prepareData();
      doc.layOut();

      final Map<String, model.Object> byPath = _byPath(doc);

      // The fixture's `path` keys the *Staff* that `VisitStaff` was called
      // for (`probe::Path(staff)`), but the field it measures
      // (`staffDef->GetDrawingVisibility()`) lives on a StaffDef the functor
      // looks up via `m_currentScoreDef->GetStaffDef(staff->GetN())` —
      // `m_currentScoreDef` there is `System::GetDrawingScoreDef()`, the same
      // lookup `Staff::DrawingIsVisible` itself uses (`staff.cpp:249`), and
      // *not* `Staff::m_drawingStaffDef` (a separate per-measure ScoreDef
      // copy `ScoreDefOptimizeFunctor` never touches — see
      // `_visibilityStaffDefFor`'s doc comment). That StaffDef is *shared*
      // across every measure of the system for a given staff `@n` (looked up
      // fresh each time, not cloned per measure), so only the *last*
      // VisitStaff record for a given `@n`, in file order, is the value
      // still standing once the system finishes — section-004.mei's staff
      // `n="1"` is visited twice (hidden in the rest-only first section,
      // then shown once the Trio section's note is reached) and only the
      // second visit's outcome survives. Resolving "last write wins" here,
      // from the raw fixture records, is not loosening the comparison: every
      // one of the fixture's `VisitStaff` records for this file is still
      // read and folded in, in the same order the C++ produced them.
      final Map<int, num> expectedByStaffN = {};
      for (final CppRecord record in fixture.where(
          fn: 'ScoreDefOptimize',
          pass: 2,
          test: (CppRecord r) => r['sub'] == 'VisitStaff')) {
        final model.Object? object = byPath[record.path];
        if (object is! Staff) continue;
        expectedByStaffN[object.n ?? 0] = record.require('visibilityAfter');
      }
      expect(expectedByStaffN, isNotEmpty);

      final List<String> divergences = [];
      for (final MapEntry<int, num> entry in expectedByStaffN.entries) {
        final model.Object anyStaffOfN = byPath.values
            .firstWhere((model.Object o) => o is Staff && o.n == entry.key);
        final int? actual = _visibilityStaffDefFor(anyStaffOfN as Staff)
            ?.getDrawingVisibility()
            .index;
        if (actual != entry.value) {
          divergences.add(
              'staff n=${entry.key}: C++=${entry.value} Dart=${actual ?? "<ausente>"}');
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });

    // Deviation from a fixture-based comparison: `VisitStaffGrpEnd`'s own
    // `path` keys a StaffGrp reached through `System::m_drawingScoreDef`
    // (`SetParent` without `AddChild` — an owned-but-not-a-child pointer,
    // same pattern as `Measure::m_leftBarLine`), which is a *different*,
    // transient ScoreDef instance per cast-off pass; `probe::Path`/`cppPath`
    // only walk *up* through `GetParent()`, so they still resolve the
    // StaffGrp's own path correctly, but section-004.mei's restart section
    // scoreDef (@n="2") is not addressable as a stable *sibling index* of
    // `System` in pass 2 in either implementation (both independently
    // produce a `scoreDef[?]` segment), so path-based matching cannot be
    // used to line up which Dart object corresponds to which C++ record.
    // Verified instead via the already fixture-verified StaffDef visibility
    // above: every visible staff's StaffGrp ancestors end up SHOW, and the
    // fixture confirms this is the outcome for real instances too (all 4
    // `VisitStaffGrpEnd` records show `visibilityAfter: 2` /
    // `OPTIMIZATION_SHOW`, both passes — see
    // `test/fixtures/cpp/04h/section-004.mei.jsonl`).
    test(
        'cada StaffGrp ancestral de uma staff visível também fica SHOW '
        '(produção; ver nota "Deviation" acima para o porquê de não ser '
        'comparado por fixture)', () {
      final Doc doc = _loadCorpus(kOptimizeCorpusFile, condenseFirstPage: true);
      doc.prepareData();
      doc.layOut();

      final Map<String, model.Object> byPath = _byPath(doc);
      for (final String path in [
        'measure[42]/staff[1]',
        'measure[42]/staff[3]',
        'measure[42]/staff[4]',
      ]) {
        final Staff staff = byPath[path] as Staff;
        model.Object? ancestor = _visibilityStaffDefFor(staff)!.parent;
        while (ancestor is StaffGrp) {
          expect(ancestor.drawingVisibility, VisibilityOptimization.show,
              reason: '$path ancestor $ancestor');
          ancestor = ancestor.parent;
        }
      }
    });

    test(
        'a staff n=2 (Clarinetto, ausente na seção Trio) fica escondida; '
        'as demais ficam visíveis (produção)', () {
      final Doc doc = _loadCorpus(kOptimizeCorpusFile, condenseFirstPage: true);
      doc.prepareData();
      doc.layOut();

      final Map<String, model.Object> byPath = _byPath(doc);
      final Staff staff2 = byPath['measure[42a]/staff[2]'] as Staff;
      expect(staff2.drawingIsVisible(), isFalse);
      expect(_visibilityStaffDefFor(staff2)!.getDrawingVisibility(),
          VisibilityOptimization.hidden);

      for (final String path in [
        'measure[42]/staff[1]',
        'measure[42]/staff[3]',
        'measure[42]/staff[4]',
      ]) {
        final Staff staff = byPath[path] as Staff;
        expect(staff.drawingIsVisible(), isTrue, reason: path);
        expect(_visibilityStaffDefFor(staff)!.getDrawingVisibility(),
            VisibilityOptimization.show,
            reason: path);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ScoreDefSetOssiaFunctor
  // ---------------------------------------------------------------------------
  group('ScoreDefSetOssiaFunctor — ossia/ossia-001.mei', () {
    test(
        'a Staff de ossia produzida (drawingLines/StaffSize/NotationType, '
        'clef herdado) bate com a fixture (pass 3, epsilon 0)', () {
      final CppFixture fixture = CppFixture.load(task, kOssiaCorpusFile);
      final Doc doc = _loadCorpus(kOssiaCorpusFile);
      doc.prepareData();
      doc.layOut();

      final Map<String, model.Object> byPath = _byPath(doc);
      bool isOssiaStaff(CppRecord r) => r['sub'] == 'VisitStaff';

      for (final (String field, int? Function(Staff) read) in [
        ('drawingLines', (Staff s) => s.drawingLines),
        ('drawingStaffSize', (Staff s) => s.drawingStaffSize),
        ('drawingNotationType', (Staff s) => s.drawingNotationtype?.index ?? 0),
        (
          'clefShape',
          (Staff s) =>
              ((s.drawingStaffDef as StaffDef?)
                  ?.getCurrentClef()
                  .shape
                  ?.index) ??
              0
        ),
        (
          'clefLine',
          (Staff s) =>
              (s.drawingStaffDef as StaffDef?)?.getCurrentClef().line ?? 0
        ),
      ]) {
        final divergences = fixture.compare(
          fn: 'ScoreDefSetOssia',
          pass: 3,
          field: field,
          test: isOssiaStaff,
          actual: (CppRecord record) {
            final model.Object? object = byPath[record.path];
            return object is Staff ? read(object) : null;
          },
        );
        expect(divergences, isEmpty,
            reason: '[$field] ${divergences.join('\n')}');
      }
    });

    test(
        'drawClef/drawKeySig finais da StaffDef produzida batem com a '
        'fixture (pass 3, epsilon 0)', () {
      final CppFixture fixture = CppFixture.load(task, kOssiaCorpusFile);
      final Doc doc = _loadCorpus(kOssiaCorpusFile);
      doc.prepareData();
      doc.layOut();

      final Map<String, model.Object> byPath = _byPath(doc);
      bool isOssiaStaff(CppRecord r) => r['sub'] == 'VisitStaff';

      for (final (String field, bool Function(StaffDef) read) in [
        ('drawClefAfter', (StaffDef d) => d.drawClef()),
        ('drawKeySigAfter', (StaffDef d) => d.drawKeySig()),
      ]) {
        final divergences = fixture.compare(
          fn: 'ScoreDefSetOssia',
          pass: 3,
          field: field,
          test: isOssiaStaff,
          actual: (CppRecord record) {
            final model.Object? object = byPath[record.path];
            final StaffDef? staffDef =
                object is Staff ? object.drawingStaffDef as StaffDef? : null;
            return staffDef == null ? null : (read(staffDef) ? 1 : 0);
          },
        );
        expect(divergences, isEmpty,
            reason: '[$field] ${divergences.join('\n')}');
      }
    });

    test(
        'Ossia.isFirst() permanece true (nenhuma ossia anterior com o '
        'mesmo conjunto de oStaffNs — foundPrevious=0 na fixture)', () {
      final CppFixture fixture = CppFixture.load(task, kOssiaCorpusFile);
      final CppRecord record = fixture.single(
          fn: 'ScoreDefSetOssia',
          pass: 3,
          test: (r) => r['sub'] == 'VisitOssia');
      expect(record['foundPrevious'], 0);
      expect(record['isFirstAfter'], 1);

      final Doc doc = _loadCorpus(kOssiaCorpusFile);
      doc.prepareData();
      doc.layOut();

      final Map<String, model.Object> byPath = _byPath(doc);
      final Ossia ossia = byPath[record.path] as Ossia;
      expect(ossia.isFirst(), isTrue);
      expect(ossia.isLast(), isTrue);
    });
  });
}
