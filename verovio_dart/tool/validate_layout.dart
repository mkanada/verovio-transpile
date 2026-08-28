/// Phase 4 integration validation harness.
///
/// Runs the headless layout pipeline (MeiInput -> prepareData -> layOut) over
/// the whole corpus (`test/corpus/**.mei`, minus the two deliberately
/// non-UTF-8 files), extracts layout metrics, performs the structural sanity
/// checks that are possible without a rendering pass and, when the C++
/// reference binary is available, compares note onset times against its
/// `-t timemap` output.
///
/// The C++ timemap runs are executed concurrently (8 processes) and cached
/// under the system temp directory keyed by path + size + mtime, so repeated
/// runs only pay for changed corpus files.
///
/// Usage (from verovio_dart/):
/// ```
/// dart run tool/validate_layout.dart [--cpp <path-to-verovio>] \
///     [--out <markdown-report>] [--refresh-cache]
/// ```
///
/// The default output file is `tool/LAYOUT_VALIDATION.md`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/align_horizontally.dart'
    show AlignHorizontallyFunctor, ResetHorizontalAlignmentFunctor;
import 'package:verovio_dart/src/layout/calc_alignment_x_pos.dart'
    show CalcAlignmentXPosFunctor;
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingPositioner;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, MeasureAligner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Slur;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
import '../test/fixtures/cpp_fixture.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const String cppBinaryDefault = '../build/verovio';
const String cppResourcesDefault = 'assets/data';

/// Task id of the C++ fixtures produced by `cpp_probe` for this validation:
/// the definition-factor units block and the alignment times/positions.
const String kProbeTask = '04-00';

/// The two corpus files that are deliberately non-UTF-8 (CLAUDE.md gotchas):
/// the file reader rejects them, so they are skipped with a reason instead of
/// being counted as failures.
const List<String> kNonUtf8CorpusFiles = [
  'test/corpus/dir/dir-011.mei',
  'test/corpus/dir/dir-012.mei',
];

/// Corpus categories whose timemap is not comparable against the C++ CLI
/// (mensural cast-off segments and neume transcription layouts do not run the
/// same timemap machinery). They are classified as `skipped` with this reason.
const List<String> kTimemapSkippedCategories = [
  'mensural',
  'ligature',
  'neume'
];

const int kTimemapMaxNotes = 40;

/// Tolerance of the timemap comparison, in quarter units (do not loosen).
const double kTimemapTolerance = 0.01;

/// Concurrent C++ timemap processes (the corpus sweep spawns ~550 of them).
const int kCppConcurrency = 8;

// ---------------------------------------------------------------------------
// Result model
// ---------------------------------------------------------------------------

/// Outcome of the timemap comparison for one file.
enum TimemapOutcome { skipped, unavailable, compared, noSharedIds }

class FileResult {
  FileResult(this.path);

  final String path;

  bool importOk = false;
  bool laidOut = false;
  String? error;

  int pageCount = 0;
  int systemCount = 0;
  int staffCount = 0;
  int measureCount = 0;
  int positionerCount = 0;
  int positionerWithBBoxCount = 0;
  int slurCount = 0;
  int slurWithPositionerCount = 0;

  // Sanity checks.
  bool monotonicXOrder = true;
  bool measuresAppearOnce = true;
  bool noNegativeWidths = true;
  bool slursHavePositioners = true;
  String? checkNotes;

  bool get allChecksPass =>
      monotonicXOrder &&
      measuresAppearOnce &&
      noNegativeWidths &&
      slursHavePositioners;

  // Timemap comparison (CMN only).
  TimemapOutcome timemapOutcome = TimemapOutcome.skipped;
  String? timemapSkipReason;
  int timemapNotesCompared = 0;
  int timemapMismatches = 0;
  double? timemapFirstDivergenceQstamp;
  String? timemapFirstDivergenceId;

  bool get timemapMatch =>
      timemapOutcome == TimemapOutcome.compared && timemapMismatches == 0;
  bool get timemapDiffer =>
      timemapOutcome == TimemapOutcome.compared && timemapMismatches > 0;

  // C++ parity of the 04-00 base (units + alignments), when a fixture
  // exists for the file.
  bool? unitsMatch;
  int unitValuesCompared = 0;
  bool? alignmentMatch;
  int alignmentValuesCompared = 0;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Stable FNV-1a over [s] (String.hashCode is not guaranteed stable across
/// VM versions; the cache key must be).
String fnv1a(String s) {
  int hash = 0x811c9dc5;
  for (int i = 0; i < s.length; ++i) {
    hash ^= s.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

List<File> selectFiles() => Directory('test/corpus')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.mei'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

bool isMensuralOrNeumeCategory(String path) =>
    kTimemapSkippedCategories.any((c) => path.contains('/$c/'));

Doc loadDoc(File file) {
  final doc = Doc();
  final input = MeiInput(doc);
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  input.import(data);
  return doc;
}

void collectSystemMetrics(Doc doc, FileResult result) {
  final pages = doc.getPages();
  if (pages == null) return;
  for (int i = 0; i < pages.childCount; ++i) {
    final Page page = pages.getChild(i)! as Page;
    result.pageCount++;
    for (final Object child in page.children) {
      if (child is! System) continue;
      final System system = child;
      result.systemCount++;
      final List<StaffAlignment> alignments =
          system.systemAligner.children.whereType<StaffAlignment>().toList();
      for (final StaffAlignment alignment in alignments) {
        // Positioners with bounding boxes.
        for (final positioner in alignment.getFloatingPositioners()) {
          result.positionerCount++;
          if (positioner.hasContentBB()) result.positionerWithBBoxCount++;
        }
        result.staffCount++;
      }
    }

    // Measures over the whole page tree.
    result.measureCount +=
        page.findAllDescendantsByType(ClassId.measure).length;
  }

  // Slurs over the whole document.
  for (final Object object in doc.findAllDescendantsByType(ClassId.slur)) {
    final Slur slur = object as Slur;
    result.slurCount++;
    if (slur.getCurrentFloatingPositioner() != null ||
        _hasPositionerInAligners(doc, slur)) {
      result.slurWithPositionerCount++;
    }
  }
}

bool _hasPositionerInAligners(Doc doc, Slur slur) {
  final pages = doc.getPages();
  if (pages == null) return false;
  for (int i = 0; i < pages.childCount; ++i) {
    final Page page = pages.getChild(i)! as Page;
    for (final Object object
        in page.findAllDescendantsByType(ClassId.staffAlignment)) {
      final StaffAlignment alignment = object as StaffAlignment;
      for (final FloatingPositioner positioner
          in alignment.getFloatingPositioners()) {
        if (identical(positioner.getObject(), slur)) return true;
      }
    }
  }
  return false;
}

void runSanityChecks(Doc doc, FileResult result) {
  final StringBuffer notes = StringBuffer();
  final pages = doc.getPages();
  if (pages == null) {
    result.monotonicXOrder = false;
    result.measuresAppearOnce = false;
    result.noNegativeWidths = false;
    return;
  }

  // 1. Monotonic x order of measures within every system + no negative
  //    widths (systems and measures).
  for (int i = 0; i < pages.childCount; ++i) {
    final Page page = pages.getChild(i)! as Page;
    if (page.getContentWidth() < 0) result.noNegativeWidths = false;
    for (final Object child in page.children) {
      if (child is! System) continue;
      if (child.drawingTotalWidth < 0) result.noNegativeWidths = false;
      int? previousX;
      for (final Object systemChild in child.children) {
        if (systemChild is! Measure) continue;
        final int x = systemChild.getDrawingX();
        if (previousX != null && x < previousX) {
          result.monotonicXOrder = false;
          notes.writeln(
              '${result.path}: measure x order broken ($previousX -> $x)');
        }
        previousX = x;
        if (systemChild.getWidth() < 0) result.noNegativeWidths = false;
      }
    }
  }

  // 2. Every visible measure appears exactly once across systems/pages.
  final Set<String> seenIds = {};
  for (int i = 0; i < pages.childCount; ++i) {
    final Page page = pages.getChild(i)! as Page;
    for (final Object object
        in page.findAllDescendantsByType(ClassId.measure)) {
      final Measure measure = object as Measure;
      final String id = measure.id;
      if (id.isEmpty) continue;
      if (!seenIds.add(id)) {
        result.measuresAppearOnce = false;
        notes.writeln('${result.path}: duplicate measure id "$id"');
      }
    }
  }

  result.checkNotes = notes.isEmpty ? null : notes.toString().trimRight();
}

// ---------------------------------------------------------------------------
// Timemap comparison against the C++ binary
// ---------------------------------------------------------------------------

/// The parsed `-t timemap` output of the C++ binary for one corpus file:
/// first onset (quarter units) per note id.
class CppTimemap {
  CppTimemap.ok(this.onsets) : failed = false;
  CppTimemap.failed()
      : onsets = const {},
        failed = true;

  final Map<String, double> onsets;
  final bool failed;
}

Map<String, double> parseCppTimemap(String jsonText) {
  final Map<String, double> onsets = {};
  final dynamic decoded = jsonDecode(jsonText);
  if (decoded is! List) return onsets;
  for (final dynamic entry in decoded) {
    if (entry is! Map) continue;
    final dynamic qstamp = entry['qstamp'];
    final dynamic on = entry['on'];
    if (qstamp is! num || on is! List) continue;
    for (final dynamic id in on) {
      if (id is String && !onsets.containsKey(id)) {
        onsets[id] = qstamp.toDouble();
      }
    }
  }
  return onsets;
}

/// Compute (or reuse from cache) the C++ timemap for [file], running up to
/// [concurrency] C++ processes at a time.
Future<Map<String, CppTimemap>> collectCppTimemaps(
  List<File> files,
  String cppBinary, {
  required bool refreshCache,
  required int concurrency,
}) async {
  final Directory cacheDir =
      Directory('${Directory.systemTemp.path}/validate_layout_timemap_cache');
  cacheDir.createSync(recursive: true);

  // Cache key: path + size + mtime, so changed corpus files are re-run.
  String cachePathFor(File file) {
    final stat = file.statSync();
    final String key = fnv1a(
        '${file.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}');
    return '${cacheDir.path}/$key.json';
  }

  final Map<String, CppTimemap> result = {};
  final Map<String, String> cachePaths = {};
  final List<File> pending = [];
  for (final File file in files) {
    final String cachePath = cachePathFor(file);
    cachePaths[file.path] = cachePath;
    final File cacheFile = File(cachePath);
    if (!refreshCache && cacheFile.existsSync()) {
      try {
        final dynamic decoded = jsonDecode(cacheFile.readAsStringSync());
        if (decoded is Map && decoded['failed'] == true) {
          result[file.path] = CppTimemap.failed();
          continue;
        } else if (decoded is Map && decoded['onsets'] is Map) {
          result[file.path] = CppTimemap.ok((decoded['onsets'] as Map)
              .map((k, v) => MapEntry(k as String, (v as num).toDouble())));
          continue;
        }
      } on FormatException {
        // Corrupt cache entry: recompute below.
      }
    }
    pending.add(file);
  }
  stdout.writeln('  timemap cache: ${files.length - pending.length} reused, '
      '${pending.length} to compute');

  int next = 0;
  int done = 0;
  Future<void> worker() async {
    while (next < pending.length) {
      final File file = pending[next++];
      final String tmpPath =
          '${Directory.systemTemp.path}/validate_layout_tm_${fnv1a(file.path)}.json';
      CppTimemap timemap;
      try {
        final ProcessResult process = await Process.run(cppBinary, [
          '-r',
          cppResourcesDefault,
          '-t',
          'timemap',
          '--breaks',
          'none',
          '-o',
          tmpPath,
          file.path,
        ]);
        if (process.exitCode != 0 || !File(tmpPath).existsSync()) {
          timemap = CppTimemap.failed();
        } else {
          try {
            timemap = CppTimemap.ok(
                parseCppTimemap(File(tmpPath).readAsStringSync()));
          } on FormatException {
            timemap = CppTimemap.failed();
          }
        }
      } catch (_) {
        timemap = CppTimemap.failed();
      }
      final File tmp = File(tmpPath);
      if (tmp.existsSync()) tmp.deleteSync();

      File(cachePaths[file.path]!).writeAsStringSync(jsonEncode({
        'failed': timemap.failed,
        'onsets': timemap.onsets,
      }));
      result[file.path] = timemap;
      ++done;
      if (done % 50 == 0) {
        stdout.writeln('  … C++ timemaps $done/${pending.length}');
      }
    }
  }

  await Future.wait(
      List.generate(concurrency, (_) => worker(), growable: false));
  return result;
}

/// Compare the doc's note onsets against the cached C++ timemap
/// ([timemap]); the C++ side is no longer spawned here.
void compareTimemap(Doc doc, FileResult result, CppTimemap timemap) {
  if (timemap.failed) {
    result.timemapOutcome = TimemapOutcome.unavailable;
    return;
  }
  if (timemap.onsets.isEmpty) {
    result.timemapOutcome = TimemapOutcome.unavailable;
    return;
  }

  // Our side first: global onset (quarter units) = measure onset + note
  // onset within the measure.
  doc.calculateTimemap();

  final List<(String, double)> ours = [];
  for (final Object object in doc.findAllDescendantsByType(ClassId.note)) {
    final Note note = object as Note;
    final DurationInterface durationInterface = note;
    final Object? measure = note.getFirstAncestor(ClassId.measure);
    final double measureOnset =
        measure is Measure ? measure.getScoreTimeOnset().toDouble() : 0.0;
    final double onset =
        measureOnset + durationInterface.scoreTimeOnset.toDouble();
    ours.add((note.id, onset));
  }
  ours.removeWhere((entry) => !timemap.onsets.containsKey(entry.$1));
  ours.sort((a, b) => a.$2.compareTo(b.$2));

  if (ours.isEmpty) {
    // No shared note ids (files whose ids are generated on both sides
    // cannot be matched): classified separately, not a match.
    result.timemapOutcome = TimemapOutcome.noSharedIds;
    return;
  }

  result.timemapOutcome = TimemapOutcome.compared;
  final List<(String, double)> compared = ours.take(kTimemapMaxNotes).toList();
  for (final (String id, double onset) in compared) {
    final double cppOnset = timemap.onsets[id]!;
    final double diff = (onset - cppOnset).abs();
    if (diff > kTimemapTolerance) {
      result.timemapMismatches++;
      result.timemapFirstDivergenceQstamp ??= cppOnset;
      result.timemapFirstDivergenceId ??= id;
    }
  }
  result.timemapNotesCompared = compared.length;
}

// ---------------------------------------------------------------------------
// 04-00 base parity: units block + alignment times / positions
// ---------------------------------------------------------------------------

/// Compares the option-level drawing values of a fresh [Doc] against the
/// `Units/kind=doc` fixture record (epsilon 0). Returns
/// `(ok, valuesCompared)`.
(bool, int) compareDocUnits(CppFixture fixture) {
  final CppRecord rec =
      fixture.single(fn: 'Units', test: (r) => r['kind'] == 'doc');
  final doc = Doc();
  final List<(num, num, String)> checks = [
    (doc.getOptions().unit.value, rec.require('unit'), 'unit'),
    (doc.getDrawingUnit(100), rec.require('drawingUnit100'), 'drawingUnit100'),
    (
      doc.getDrawingDoubleUnit(100),
      rec.require('drawingDoubleUnit100'),
      'drawingDoubleUnit100'
    ),
    (
      doc.getDrawingStaffSize(100),
      rec.require('drawingStaffSize100'),
      'drawingStaffSize100'
    ),
    (doc.getOptions().pageWidth.value, rec.require('pageWidth'), 'pageWidth'),
    (
      doc.getOptions().pageHeight.value,
      rec.require('pageHeight'),
      'pageHeight'
    ),
    (
      doc.getOptions().pageMarginBottom.value,
      rec.require('pageMarginBottom'),
      'pageMarginBottom'
    ),
    (
      doc.getOptions().pageMarginLeft.value,
      rec.require('pageMarginLeft'),
      'pageMarginLeft'
    ),
    (
      doc.getOptions().pageMarginRight.value,
      rec.require('pageMarginRight'),
      'pageMarginRight'
    ),
    (
      doc.getOptions().pageMarginTop.value,
      rec.require('pageMarginTop'),
      'pageMarginTop'
    ),
  ];
  for (final (num actual, num expected, String _) in checks) {
    if ((actual - expected).abs() > 0) return (false, checks.length);
  }
  return (true, checks.length);
}

/// Reproduces one `ResetAligners` round on a freshly prepared document and
/// compares every captured alignment against the fixture's pass-1 records.
/// Returns `(allMatch, valuesCompared)`.
(bool, int) compareAlignments(CppFixture fixture, File file) {
  final records = fixture.where(fn: 'CalcAlignmentXPos', pass: 1);
  if (records.isEmpty) throw CppFixtureError('sem registros pass 1');

  final doc = Doc();
  final input = MeiInput(doc);
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  if (!input.import(data)) throw CppFixtureError('MEI import rejected');
  doc.prepareData();
  final dynamic page = doc.setDrawingPage(0);
  page.process(ResetHorizontalAlignmentFunctor());
  page.process(AlignHorizontallyFunctor(doc));
  // Mirrors Doc::layOutHorizontally's caller: spacingDurDetection is false
  // by default, so the longest duration passed to the functor is DURATION_4.
  final probe = _ProbedCalcXPos(doc)..setLongestActualDur(MeiDuration.dur4);
  page.process(probe);

  final Set<String> expectedKeys =
      records.map((r) => '${r.require("mi")}|${r.require("al")}').toSet();
  if (!expectedKeys.containsAll(probe.captures.keys.toSet())) {
    return (false, records.length);
  }
  int compared = 0;
  for (final CppRecord rec in records) {
    final String key = '${rec.require("mi")}|${rec.require("al")}';
    final List<int>? got = probe.captures[key];
    if (got == null ||
        got[0] != rec.require('xrel_in') ||
        got[1] != rec.require('xrel_out') ||
        got[2] != rec.require('type') ||
        got[3] != rec.require('time_num') ||
        got[4] != rec.require('time_den')) {
      return (false, compared);
    }
    compared++;
  }
  return (true, compared);
}

class _ProbedCalcXPos extends CalcAlignmentXPosFunctor {
  _ProbedCalcXPos(super.doc);

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
    final Object? parent = alignment.parent;
    int index = -1;
    if (parent is MeasureAligner) {
      for (int i = 0; i < parent.childCount; ++i) {
        if (identical(parent.getChild(i), alignment)) {
          index = i;
          break;
        }
      }
    }
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
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

String categoryOf(String path) {
  // Paths are relative to test/corpus/ (e.g. `note/note-001.mei`); fall back
  // to the full form for absolute paths.
  final RegExpMatch? match =
      RegExp(r'(?:corpus/)?([a-zA-Z_-]+)/').firstMatch(path);
  return match?.group(1) ?? '?';
}

extension on File {
  String get short => path.replaceFirst('test/corpus/', '');
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

String _yesNo(bool? value) => value == null ? 'n/a' : (value ? 'PASS' : 'FAIL');

String _timemapCell(FileResult result) {
  switch (result.timemapOutcome) {
    case TimemapOutcome.compared:
      if (result.timemapMismatches == 0) {
        return 'match (${result.timemapNotesCompared})';
      }
      return '${result.timemapMismatches}/${result.timemapNotesCompared} differ'
          '@q=${result.timemapFirstDivergenceQstamp!.toStringAsFixed(2)} '
          '(${result.timemapFirstDivergenceId})';
    case TimemapOutcome.unavailable:
      return 'unavailable';
    case TimemapOutcome.noSharedIds:
      return 'no shared ids';
    case TimemapOutcome.skipped:
      return 'skipped';
  }
}

void writeReport(List<FileResult> results, List<String> nonUtf8Skipped,
    String outPath, bool hasCpp, String cacheDirPath) {
  final StringBuffer out = StringBuffer();

  final int layoutOk =
      results.where((r) => r.laidOut && r.error == null).length;
  final int checksOk = results
      .where((r) => r.laidOut && r.error == null && r.allChecksPass)
      .length;
  final int timemapMatch = results.where((r) => r.timemapMatch).length;
  final int timemapDiffer = results.where((r) => r.timemapDiffer).length;
  final int timemapCompared =
      results.where((r) => r.timemapOutcome == TimemapOutcome.compared).length;

  out.writeln('# Phase 4 layout validation');
  out.writeln();
  out.writeln('Headless pipeline: `MeiInput -> prepareData -> layOut` '
      '(breaks auto; encoded breaks honoured when the input provides '
      'layout information). Full-corpus sweep (task 04j).');
  out.writeln();
  out.writeln('- Corpus files scanned: **${results.length}** of '
      '${results.length + nonUtf8Skipped.length} '
      '(${nonUtf8Skipped.length} skipped: non-UTF-8 by design).');
  out.writeln('- C++ reference binary (`build/verovio`): '
      '${hasCpp ? "available" : "not available"} — timemap comparison '
      'runs on CMN files only; results cached under `$cacheDirPath`.');
  out.writeln();
  out.writeln('## Aggregate counts');
  out.writeln();
  out.writeln('| Metric | Files |');
  out.writeln('|---|---|');
  out.writeln('| Layout OK | **$layoutOk** / ${results.length} |');
  out.writeln('| All structural assertions passing | **$checksOk** / '
      '${results.length} |');
  out.writeln('| Timemap match | **$timemapMatch** |');
  out.writeln('| Timemap differ | **$timemapDiffer** |');
  out.writeln();
  out.writeln('Of ${results.length} files, $timemapCompared were compared '
      'against the C++ timemap (CMN categories); the rest: '
      '${results.where((r) => r.timemapOutcome == TimemapOutcome.skipped).length} '
      'skipped (${kTimemapSkippedCategories.join("/")} categories), '
      '${results.where((r) => r.timemapOutcome == TimemapOutcome.unavailable).length} '
      'unavailable (C++ produced no timemap), '
      '${results.where((r) => r.timemapOutcome == TimemapOutcome.noSharedIds).length} '
      'with no shared note ids.');
  out.writeln();

  // ---- 04-00 base parity (fixtures) --------------------------------------
  final List<FileResult> withFixture =
      results.where((r) => r.unitsMatch != null).toList();
  if (withFixture.isNotEmpty) {
    final int unitsOk = withFixture.where((r) => r.unitsMatch == true).length;
    final int alignOk =
        withFixture.where((r) => r.alignmentMatch == true).length;
    final int unitValues =
        withFixture.fold(0, (sum, r) => sum + r.unitValuesCompared);
    final int alignmentValues =
        withFixture.fold(0, (sum, r) => sum + r.alignmentValuesCompared);
    out.writeln('## Base numérica 04-00 vs C++ (epsilon 0)');
    out.writeln();
    out.writeln('- Arquivos com unidades batendo: **$unitsOk/'
        '${withFixture.length}** ($unitValues valores)');
    out.writeln('- Arquivos com todos os alinhamentos batendo: '
        '**$alignOk/${withFixture.length}** ($alignmentValues valores de '
        'type/time/xRel)');
    out.writeln();
  }

  // ---- Timemap divergences: the 05-12 work list --------------------------
  out.writeln('## Divergências de timemap');
  out.writeln();
  final List<FileResult> divergent = results
      .where((r) => r.timemapDiffer)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (divergent.isEmpty) {
    out.writeln('Nenhuma: todos os arquivos comparados batem '
        '(tolerância $kTimemapTolerance quarter units, primeiras '
        '$kTimemapMaxNotes notas compartilhadas).');
  } else {
    out.writeln('Primeira divergência por arquivo (o `@q` é o onset do C++ '
        'em quarter units; o id é a nota onde ela nasce) — material de '
        'trabalho da tarefa 05-12:');
    out.writeln();
    out.writeln(
        '| File | First divergence | Note id | Mismatches / compared |');
    out.writeln('|---|---|---|---|');
    for (final FileResult result in divergent) {
      out.writeln('| ${result.path} '
          '| @q=${result.timemapFirstDivergenceQstamp!.toStringAsFixed(2)} '
          '| ${result.timemapFirstDivergenceId} '
          '| ${result.timemapMismatches}/${result.timemapNotesCompared} |');
    }
  }
  out.writeln();

  // ---- Overall pass / fail per category --------------------------------
  out.writeln('## Summary per category');
  out.writeln();
  out.writeln('| Category | Files | Laid out | Sanity checks | '
      'Timemap |');
  out.writeln('|---|---|---|---|---|');

  final Map<String, List<FileResult>> byCategory = {};
  for (final FileResult result in results) {
    byCategory.putIfAbsent(categoryOf(result.path), () => []).add(result);
  }
  final List<String> categories = byCategory.keys.toList()..sort();

  for (final String category in categories) {
    final List<FileResult> group = byCategory[category]!;
    final int laidOut = group.where((r) => r.laidOut && r.error == null).length;
    final int sanityOk = group.where((r) => r.allChecksPass).length;
    String timemap;
    if (group.any((r) => r.timemapOutcome == TimemapOutcome.compared)) {
      final int ok = group.where((r) => r.timemapMatch).length;
      final int differ = group.where((r) => r.timemapDiffer).length;
      final int noIds = group
          .where((r) => r.timemapOutcome == TimemapOutcome.noSharedIds)
          .length;
      final int unavailable = group
          .where((r) => r.timemapOutcome == TimemapOutcome.unavailable)
          .length;
      timemap = '$ok match / $differ differ';
      if (noIds > 0) timemap += ' / $noIds no shared ids';
      if (unavailable > 0) timemap += ' / $unavailable unavailable';
    } else {
      timemap = group.first.timemapOutcome == TimemapOutcome.skipped
          ? 'skipped (${group.first.timemapSkipReason})'
          : _timemapCell(group.first);
    }
    out.writeln('| $category | ${group.length} | $laidOut | $sanityOk | '
        '$timemap |');
  }
  out.writeln();

  // ---- Detailed results --------------------------------------------------
  out.writeln('## Per-file details');
  out.writeln();
  out.writeln('| File | Layout | Pages | Systems | Measures | X order | '
      'Measures once | Widths ≥ 0 | Timemap |');
  out.writeln('|---|---|---|---|---|---|---|---|---|');

  for (final FileResult result in results) {
    if (!result.laidOut || result.error != null) {
      out.writeln('| ${result.path} | '
          '**${result.error ?? "layout failed"}** | | | | | | | |');
      continue;
    }
    out.writeln('| ${result.path} '
        '| OK '
        '| ${result.pageCount} '
        '| ${result.systemCount} '
        '| ${result.measureCount} '
        '| ${_yesNo(result.monotonicXOrder)} '
        '| ${_yesNo(result.measuresAppearOnce)} '
        '| ${_yesNo(result.noNegativeWidths)} '
        '| ${_timemapCell(result)} |');
  }
  out.writeln();

  // ---- Notes ---------------------------------------------------------------
  final List<String> notesLines = [];
  for (final FileResult result in results) {
    if (result.checkNotes != null) notesLines.add(result.checkNotes!);
  }
  out.writeln('## Check notes');
  if (notesLines.isEmpty) {
    out.writeln('None. All structural assertions passed.');
  } else {
    for (final String line in notesLines) {
      out.writeln('- $line');
    }
  }
  out.writeln();
  out.writeln('## Known limitations of the comparison');
  out.writeln();
  out.writeln('- SVG comparison is not possible yet (rendering is Phase 5); '
      'the C++ binary is only used for `-t timemap` onset times, which are '
      'independent of the visual layout.');
  out.writeln('- The C++ CLI cannot expose the mensural cast-off segment '
      'structure directly: segments are unmeasured measures which are not '
      'drawn as `measure` groups in SVG and are undone before MEI export. '
      'The structural counts quoted in the tests were derived from the C++ '
      'SVG staff-group counts (one staff group per segment per staff).');
  out.writeln('- Timemap comparisons use the first $kTimemapMaxNotes shared '
      'note ids per file with a tolerance of $kTimemapTolerance quarter '
      'units. Files where the two sides share no note id (ids generated '
      'independently) are reported as `no shared ids`, not as matches.');
  out.writeln('- Mensural / ligature / neume categories are skipped with '
      'reason (${kTimemapSkippedCategories.join(", ")}): the C++ CLI does '
      'not produce a comparable timemap for them.');

  File(outPath).writeAsStringSync(out.toString());
}

Future<void> main(List<String> args) async {
  registerModelClasses();
  logLevel = LogLevel.error;

  String cppBinary = cppBinaryDefault;
  String outPath = 'tool/LAYOUT_VALIDATION.md';
  bool refreshCache = false;
  for (int i = 0; i < args.length - 1; ++i) {
    if (args[i] == '--cpp') cppBinary = args[i + 1];
    if (args[i] == '--out') outPath = args[i + 1];
  }
  refreshCache = args.contains('--refresh-cache');
  final bool hasCpp = File(cppBinary).existsSync();

  final List<File> allFiles = selectFiles();
  final List<String> nonUtf8Skipped = allFiles
      .where((f) => kNonUtf8CorpusFiles.contains(f.path))
      .map((f) => f.path)
      .toList();
  final List<File> files =
      allFiles.where((f) => !kNonUtf8CorpusFiles.contains(f.path)).toList();
  stdout.writeln('Validating ${files.length} corpus files '
      '(${nonUtf8Skipped.length} skipped as non-UTF-8; '
      'C++ binary: ${hasCpp ? "found" : "not found"})…');

  // Phase A: C++ timemaps, concurrently and cached (skip the categories the
  // C++ timemap does not cover).
  Map<String, CppTimemap> timemaps = {};
  if (hasCpp) {
    final List<File> comparableFiles =
        files.where((f) => !isMensuralOrNeumeCategory(f.path)).toList();
    final stopwatch = Stopwatch()..start();
    timemaps = await collectCppTimemaps(comparableFiles, cppBinary,
        refreshCache: refreshCache, concurrency: kCppConcurrency);
    stopwatch.stop();
    stdout.writeln('  C++ timemaps ready in '
        '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s');
  }

  final List<FileResult> results = [];
  int done = 0;
  for (final File file in files) {
    final FileResult result = FileResult(file.short);
    results.add(result);
    try {
      // 04-00 base parity when the C++ fixture exists for this file. Run
      // BEFORE any full pipeline so unrelated process-global state cannot
      // contaminate the fresh docs.
      final String fixturePath =
          'test/fixtures/cpp/$kProbeTask/${file.uri.pathSegments.last}.jsonl';
      if (File(fixturePath).existsSync()) {
        final CppFixture fixture = CppFixture.load(kProbeTask, file.short);
        final (bool okU, int nU) = compareDocUnits(fixture);
        result.unitsMatch = okU;
        result.unitValuesCompared = nU;
        final (bool okA, int nA) = compareAlignments(fixture, file);
        result.alignmentMatch = okA;
        result.alignmentValuesCompared = nA;
      }

      final doc = Doc();
      final input = MeiInput(doc);
      final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
      result.importOk = input.import(data);
      if (!result.importOk) {
        result.error = 'MEI import rejected';
        continue;
      }

      // Mirrors Toolkit::LoadFile: honour encoded breaks when the input
      // provided layout information.
      final bool hasEncodedBreaks =
          input.layoutInformation == LayoutInformation.encoded;
      doc.getOptions().breaks.setValue(Breaks.auto);
      doc.prepareData();
      doc.layOut(hasEncodedBreaks: hasEncodedBreaks);
      result.laidOut = true;

      collectSystemMetrics(doc, result);
      runSanityChecks(doc, result);

      if (hasCpp && !isMensuralOrNeumeCategory(file.path)) {
        compareTimemap(doc, result, timemaps[file.path] ?? CppTimemap.failed());
      } else if (isMensuralOrNeumeCategory(file.path)) {
        result.timemapOutcome = TimemapOutcome.skipped;
        result.timemapSkipReason =
            'mensural/ligature/neume: timemap não comparável';
      }
    } catch (e) {
      result.error = e.toString();
    }
    ++done;
    if (done % 50 == 0) stdout.writeln('  … Dart layout $done/${files.length}');
  }

  final String cacheDirPath =
      '${Directory.systemTemp.path}/validate_layout_timemap_cache';
  writeReport(results, nonUtf8Skipped, outPath, hasCpp, cacheDirPath);
  stdout.writeln('Report written to $outPath');
}
