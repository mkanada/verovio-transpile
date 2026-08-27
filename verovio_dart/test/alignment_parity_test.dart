/// Parity of the alignment times / positions against the instrumented C++
/// (`cpp_probe` task `04-00`).
///
/// Two families of fixture records are compared, both emitted during the
/// first `Page::ResetAligners` round of the binary:
///
/// - `{"fn":"AlignHorizontally",...}` — one per `LayerElement` that
///   `AlignHorizontallyFunctor::VisitLayerElement` processes, carrying the
///   duration and the cursor (`m_time`) before/after as fractions. The test
///   wraps the production functor and snapshots `timeCursor` around each
///   visit, mirroring the three `[cpp_probe]` emission points of the patch;
///   the fixture's own arithmetic (time_in + dur == time_out) is asserted on
///   every row.
/// - `{"fn":"CalcAlignmentXPos",...}` — one per `Alignment` visited by
///   `CalcAlignmentXPosFunctor::VisitAlignment`, carrying type, time
///   (num/den) and `xRel` before/after, keyed by `(mpath, al)` — the measure
///   path plus the index among the `MeasureAligner` children (the C++
///   `Alignment` class name is not registered, so `probe::Path` cannot key
///   them). The measure key replicates the `probe::SegmentKey` rule: the
///   `@n` when present, otherwise the 1-based index among same-class
///   siblings.
///
/// The comparison reproduces one captured round on the uncast-off document:
/// reset -> AlignHorizontally -> CalcAlignmentXPos, mirroring
/// `page.cpp:318-367` (`Page::ResetAligners`) with
/// `longestActualDur = DURATION_4` (`spacingDurDetection` false, the
/// default). The fixture pass compared against is pass 1: the later C++
/// rounds apply the justification-ratio estimation whose inputs arrive with
/// Phase 6 (see the deviation noted in `calc_alignment_x_pos.dart`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/align_horizontally.dart'
    show AlignHorizontallyFunctor, ResetHorizontalAlignmentFunctor;
import 'package:verovio_dart/src/layout/calc_alignment_x_pos.dart'
    show CalcAlignmentXPosFunctor;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, MeasureAligner;
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/object.dart' as model_object;

import 'fixtures/cpp_fixture.dart';

const String task = '04-00';

const List<String> kCorpusFiles = <String>[
  'test/corpus/note/note-001.mei',
  'test/corpus/beam/beam-001.mei',
  'test/corpus/rest/rest-001.mei',
  'test/corpus/dot/dot-001.mei',
  'test/corpus/score/score-002.mei',
];

class _CursorRow {
  _CursorRow(this.path, this.inNum, this.inDen, this.outNum, this.outDen);

  final String path;
  final int inNum, inDen, outNum, outDen;
}

/// Wraps the production functor recording the cursor around each processed
/// element — exactly what the C++ instrumentation emits (the scoreDef
/// early-return and graceGrp produce no C++ record, so they are skipped).
class _ProbedAlignHorizontally extends AlignHorizontallyFunctor {
  _ProbedAlignHorizontally(super.doc);

  final List<_CursorRow> rows = [];

  @override
  FunctorCode visitLayerElement(LayerElement element) {
    final bool records =
        !element.isScoreDefElement && element.classId != ClassId.graceGrp;
    final Fraction before = timeCursor;
    final FunctorCode code = super.visitLayerElement(element);
    if (!records) return code;
    final Fraction after = timeCursor;
    rows.add(_CursorRow(cppPath(element), before.numerator, before.denominator,
        after.numerator, after.denominator));
    return code;
  }
}

class _ProbedCalcXPos extends CalcAlignmentXPosFunctor {
  _ProbedCalcXPos(super.doc);

  /// Key `(mi, al)` -> `(xrelIn, xrelOut, type, timeNum, timeDen)` where
  /// `mi` is the 0-based sequence of the measure in traversal order (the
  /// C++ patch increments a static counter at `VisitMeasure`), and `al` the
  /// index among the `MeasureAligner` children.
  final Map<String, List<int>> captures = {};

  int _measureSeq = -1;

  @override
  FunctorCode visitMeasure(Measure measure) {
    ++_measureSeq;
    return super.visitMeasure(measure);
  }

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    final int xrelIn = alignment.getXRel();
    final FunctorCode code = super.visitAlignment(alignment);
    final int index = _indexAmongSiblings(alignment);
    if (index >= 0) {
      captures['$_measureSeq|$index'] = <int>[
        xrelIn,
        alignment.getXRel(),
        alignment.getType().value,
        alignment.getTime().numerator,
        alignment.getTime().denominator,
      ];
    }
    return code;
  }

  int _indexAmongSiblings(Alignment alignment) {
    final model_object.Object? parent = alignment.parent;
    if (parent is MeasureAligner) {
      for (int i = 0; i < parent.childCount; ++i) {
        if (identical(parent.getChild(i), alignment)) return i;
      }
    }
    return -1;
  }
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

void main() {
  setUpAll(() {
    registerModelClasses();
  });

  for (final String path in kCorpusFiles) {
    group('paridade de alinhamento — ${path.split('/').last}', () {
      late CppFixture fixture;
      late Doc doc;
      late List<_CursorRow> cursorRows;
      late Map<String, List<int>> captures;

      setUpAll(() {
        fixture = CppFixture.load(task, path);
        doc = loadCorpusDoc(path);
        doc.prepareData();
        final Page page = doc.setDrawingPage(0)!;
        page.process(ResetHorizontalAlignmentFunctor());
        final _ProbedAlignHorizontally alignProbe =
            _ProbedAlignHorizontally(doc);
        page.process(alignProbe);
        cursorRows = alignProbe.rows;
        if (!doc.getOptions().evenNoteSpacing.value) {
          final _ProbedCalcXPos probe = _ProbedCalcXPos(doc)
            ..setLongestActualDur(MeiDuration.dur4);
          page.process(probe);
          captures = probe.captures;
        } else {
          // Mirrors the production guard: without the spacing pass there is
          // no CalcAlignmentXPos data; the parity test below fails loudly on
          // the missing captures instead of passing silently.
          captures = {};
        }
      });

      test('a duração e o cursor de cada elemento batem com o C++', () {
        final List<CppRecord> records =
            fixture.where(fn: 'AlignHorizontally', pass: 1);
        if (records.isEmpty) {
          throw CppFixtureError(
              '${fixture.file}: nenhum registro AlignHorizontally pass 1');
        }

        final List<String> divergences = [];
        final int n = records.length < cursorRows.length
            ? records.length
            : cursorRows.length;
        if (records.length != cursorRows.length) {
          divergences.add('o Dart visitou ${cursorRows.length} elementos na '
              'passada; o C++ emitiu ${records.length} registros');
        }
        int compared = 0;
        for (int i = 0; i < n; ++i) {
          final CppRecord rec = records[i];
          final _CursorRow row = cursorRows[i];
          final String where =
              rec.path == row.path ? rec.path : '#$i ${rec.path} ↔ ${row.path}';
          void eq(int actual, int expected, String what) {
            if (actual != expected) {
              divergences.add('$where: $what $actual ≠ $expected');
            }
          }

          eq(row.inNum, rec.require('time_in_num').toInt(), 'time_in_num');
          eq(row.inDen, rec.require('time_in_den').toInt(), 'time_in_den');
          eq(row.outNum, rec.require('time_out_num').toInt(), 'time_out_num');
          eq(row.outDen, rec.require('time_out_den').toInt(), 'time_out_den');

          // Fixture self-consistency as an extra guard: time_in + dur ==
          // time_out proves the recorded fractions are the duration the
          // GetAlignmentDuration of the C++ returned.
          final int durNum = rec.require('dur_num').toInt();
          final int durDen = rec.require('dur_den').toInt();
          final Fraction advanced = Fraction(rec.require('time_in_num').toInt(),
                  rec.require('time_in_den').toInt()) +
              Fraction(durNum, durDen);
          final bool consistent = advanced.numerator * row.outDen ==
              row.outNum * advanced.denominator;
          if (!consistent && divergences.isEmpty) {
            divergences.add('$where: time_in + dur ≠ time_out no fixture');
          }
          compared++;
        }
        stdout.writeln('04-00 durações [$path]: $compared elementos '
            'comparados, ${compared - divergences.length} batem');
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });

      test('cada Alignment tem type, time e xRel idênticos ao C++', () {
        final List<CppRecord> records =
            fixture.where(fn: 'CalcAlignmentXPos', pass: 1);
        if (records.isEmpty) {
          throw CppFixtureError(
              '${fixture.file}: nenhum registro CalcAlignmentXPos pass 1');
        }

        int compared = 0;
        final List<String> divergences = [];
        for (final CppRecord rec in records) {
          final String key = '${rec.require('mi')}|${rec.require('al')}';
          final List<int>? got = captures[key];
          if (got == null) {
            divergences.add('mi#$key: o Dart não capturou este alinhamento');
            continue;
          }
          if (got[0] != rec.require('xrel_in').toInt()) {
            divergences.add('$key: xRel_in ${got[0]} ≠ '
                '${rec.require('xrel_in')}');
            continue;
          }
          if (got[1] != rec.require('xrel_out').toInt()) {
            divergences.add('$key: xRel_out ${got[1]} ≠ '
                '${rec.require('xrel_out')}');
            continue;
          }
          if (got[2] != rec.require('type')) {
            divergences.add('$key: type ${got[2]} ≠ ${rec.require('type')}');
            continue;
          }
          if (got[3] != rec.require('time_num') ||
              got[4] != rec.require('time_den')) {
            divergences.add('$key: time ${got[3]}/${got[4]} ≠ '
                '${rec.require('time_num')}/${rec.require('time_den')}');
            continue;
          }
          compared++;
        }
        stdout.writeln('04-00 alinhamentos [$path]: $compared comparados, '
            '${compared - divergences.length} batem');
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });
    });
  }
}
