/// Phase 4 integration validation harness.
///
/// Runs the headless layout pipeline (MeiInput -> prepareData -> layOut) over
/// a diverse selection of corpus files, extracts layout metrics, performs the
/// structural sanity checks that are possible without a rendering pass and,
/// when the C++ reference binary is available, compares note onset times
/// against its `-t timemap` output.
///
/// Usage (from verovio_dart/):
/// ```
/// dart run tool/validate_layout.dart [--cpp <path-to-verovio>] \
///     [--out <markdown-report>]
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

/// Explicitly requested categories. Each entry lists a corpus sub-directory
/// and how many files (sorted alphabetically, evenly spaced) to take from it.
const Map<String, int> kSelection = <String, int>{
  // Core CMN categories (2 files each keeps the run diverse but bounded).
  'note': 2,
  'slur': 2,
  'tie': 1,
  'beam': 1,
  'chord': 1,
  'rest': 1,
  'keysig': 1,
  'metersig': 1,
  'clef': 1,
  'hairpin': 1,
  'dynam': 1,
  'lyric': 1,
  'gracenote': 1,
  'tuplet': 1,
  'barline': 1,
  'mrest': 1,
  'custos': 1,
  'dot': 1,
  'artic': 1,
  'accid': 1,
  'measure': 1,
  'layer': 1,
  'section': 1,
  // Special layouts.
  'cross-staff': 2,
  'ossia': 2,
  'editorial': 1,
  'repeats': 1,
  // Mensural / neume specifics.
  'mensural': 6,
  'ligature': 4,
  'neume': 6,
};

const int kTimemapMaxNotes = 40;

// ---------------------------------------------------------------------------
// Result model
// ---------------------------------------------------------------------------

class SystemMetrics {
  SystemMetrics(this.index, this.measureCount, this.totalWidth, this.staffCount,
      this.minStaffYRel, this.maxStaffYRel);

  final int index;
  final int measureCount;
  final int totalWidth;
  final int staffCount;
  final int minStaffYRel;
  final int maxStaffYRel;
}

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
  final List<SystemMetrics> systems = [];

  // Sanity checks.
  bool monotonicXOrder = true;
  bool measuresAppearOnce = true;
  bool noNegativeWidths = true;
  bool slursHavePositioners = true;
  String? checkNotes;

  // Timemap comparison (CMN only).
  bool? timemapCompared;
  int timemapNotesCompared = 0;
  int timemapMismatches = 0;
  double? timemapFirstDivergenceQstamp;

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

List<File> selectFiles() {
  final List<File> selected = [];
  final List<String> dirs = kSelection.keys.toList()..sort();
  for (final String dir in dirs) {
    final int count = kSelection[dir]!;
    final Directory directory = Directory('test/corpus/$dir');
    if (!directory.existsSync()) continue;
    final List<File> files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.mei'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (files.isEmpty) continue;
    if (files.length <= count) {
      selected.addAll(files);
    } else {
      for (int i = 0; i < count; ++i) {
        selected.add(files[(i * files.length) ~/ count]);
      }
    }
  }
  return selected;
}

bool isMensuralOrNeumeCategory(String path) =>
    path.contains('/mensural') ||
    path.contains('/ligature') ||
    path.contains('/neume');

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

      int minStaffYRel = 0;
      int maxStaffYRel = 0;
      bool first = true;
      final List<StaffAlignment> alignments =
          system.systemAligner.children.whereType<StaffAlignment>().toList();

      for (final StaffAlignment alignment in alignments) {
        // Positioners with bounding boxes.
        for (final positioner in alignment.getFloatingPositioners()) {
          result.positionerCount++;
          if (positioner.hasContentBB()) result.positionerWithBBoxCount++;
        }
        final int yRel = alignment.getYRel();
        if (first || yRel > maxStaffYRel) maxStaffYRel = yRel;
        if (first || yRel < minStaffYRel) minStaffYRel = yRel;
        first = false;
        result.staffCount++;
      }

      result.systems.add(SystemMetrics(
        result.systems.length,
        system.getChildCount(ClassId.measure),
        system.drawingTotalWidth,
        alignments.length,
        minStaffYRel,
        maxStaffYRel,
      ));
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

Map<String, double> parseCppTimemap(String jsonPath) {
  final Map<String, double> onsets = {};
  final dynamic decoded = jsonDecode(File(jsonPath).readAsStringSync());
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

void compareTimemap(
    File file, Doc doc, FileResult result, String cppBinary, String tmpPath) {
  // Our side first: global onset (quarter units) = measure onset +
  // note onset within the measure.
  doc.calculateTimemap();

  final ProcessResult process = Process.runSync(cppBinary, [
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
    result.timemapCompared = false;
    return;
  }

  final Map<String, double> cppOnsets;
  try {
    cppOnsets = parseCppTimemap(tmpPath);
  } on FormatException {
    result.timemapCompared = false;
    return;
  }
  if (cppOnsets.isEmpty) {
    result.timemapCompared = false;
    return;
  }

  // Our side: global onset (quarter units) = measure onset + note onset.
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
  ours.removeWhere((entry) => !cppOnsets.containsKey(entry.$1));
  ours.sort((a, b) => a.$2.compareTo(b.$2));

  result.timemapCompared = true;
  final List<(String, double)> compared = ours.take(kTimemapMaxNotes).toList();
  for (final (String id, double onset) in compared) {
    final double cppOnset = cppOnsets[id]!;
    final double diff = (onset - cppOnset).abs();
    if (diff > 0.01) {
      result.timemapMismatches++;
      result.timemapFirstDivergenceQstamp ??= cppOnset;
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
  final RegExpMatch? match = RegExp(r'corpus/([a-zA-Z_-]+)/').firstMatch(path);
  return match?.group(1) ?? '?';
}

extension on File {
  String get short => path.replaceFirst('test/corpus/', '');
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

String _yesNo(bool? value) => value == null ? 'n/a' : (value ? 'PASS' : 'FAIL');

void writeReport(List<FileResult> results, String outPath, bool hasCpp) {
  final StringBuffer out = StringBuffer();

  out.writeln('# Phase 4 layout validation');
  out.writeln();
  out.writeln('Headless pipeline: `MeiInput -> prepareData -> layOut` '
      '(breaks auto; encoded breaks honoured when the input provides '
      'layout information).');
  out.writeln();
  out.writeln('- Files validated: **${results.length}**');
  out.writeln('- C++ reference binary (`build/verovio`): '
      '${hasCpp ? "available" : "not available"} — timemap comparison '
      'runs on CMN files only.');
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

  // ---- Overall pass / fail per category --------------------------------
  out.writeln('## Summary per category');
  out.writeln();
  out.writeln('| Category | Files | Laid out | Sanity checks | '
      'Timemap vs C++ |');
  out.writeln('|---|---|---|---|---|');

  final Map<String, List<FileResult>> byCategory = {};
  for (final FileResult result in results) {
    byCategory.putIfAbsent(categoryOf(result.path), () => []).add(result);
  }
  final List<String> categories = byCategory.keys.toList()..sort();

  for (final String category in categories) {
    final List<FileResult> group = byCategory[category]!;
    final int laidOut = group.where((r) => r.laidOut && r.error == null).length;
    final int sanityOk = group
        .where((r) =>
            r.monotonicXOrder &&
            r.measuresAppearOnce &&
            r.noNegativeWidths &&
            r.slursHavePositioners)
        .length;
    String timemap = 'n/a';
    if (group.any((r) => r.timemapCompared != null)) {
      final int ok = group
          .where((r) => r.timemapCompared == true && r.timemapMismatches == 0)
          .length;
      final int total = group.where((r) => r.timemapCompared != null).length;
      timemap = '$ok/$total clean';
    }
    out.writeln('| $category | ${group.length} | $laidOut | $sanityOk | '
        '$timemap |');
  }
  out.writeln();

  // ---- Detailed results --------------------------------------------------
  out.writeln('## Per-file details');
  out.writeln();
  out.writeln('| File | Layout | Pages | Systems | Staves | Measures | '
      'Positioners (w/ bbox) | Slurs (positioned) | X order | Measures once | '
      'Widths ≥ 0 | Timemap |');
  out.writeln('|---|---|---|---|---|---|---|---|---|---|---|---|');

  for (final FileResult result in results) {
    if (!result.laidOut || result.error != null) {
      out.writeln('| ${result.path} | '
          '**${result.error ?? "layout failed"}** | | | | | | | | | | |');
      continue;
    }
    String? timemapCell;
    if (result.timemapCompared == true) {
      timemapCell = result.timemapMismatches == 0
          ? 'match (${result.timemapNotesCompared})'
          : '${result.timemapMismatches}/${result.timemapNotesCompared} differ'
              '${result.timemapFirstDivergenceQstamp != null ? " @q=${result.timemapFirstDivergenceQstamp!.toStringAsFixed(2)}" : ""}';
    } else if (result.timemapCompared == false) {
      timemapCell = 'unavailable';
    } else {
      timemapCell = 'skipped';
    }
    out.writeln('| ${result.path} '
        '| OK '
        '| ${result.pageCount} '
        '| ${result.systemCount} '
        '| ${result.staffCount} '
        '| ${result.measureCount} '
        '| ${result.positionerCount} (${result.positionerWithBBoxCount}) '
        '| ${result.slurCount} (${result.slurWithPositionerCount}) '
        '| ${_yesNo(result.monotonicXOrder)} '
        '| ${_yesNo(result.measuresAppearOnce)} '
        '| ${_yesNo(result.noNegativeWidths)} '
        '| $timemapCell |');
  }
  out.writeln();

  // ---- System level metrics ----------------------------------------------
  out.writeln('## System metrics (first system per file)');
  out.writeln();
  out.writeln('| File | Systems | First system: measures / width / staves / '
      'yRel range |');
  out.writeln('|---|---|---|');
  for (final FileResult result in results) {
    if (!result.laidOut || result.systems.isEmpty) continue;
    final SystemMetrics first = result.systems.first;
    out.writeln('| ${result.path} '
        '| ${result.systems.length} '
        '| ${first.measureCount} m / w=${first.totalWidth} / '
        '${first.staffCount} st / y∈[$first.minStaffYRel, $first.maxStaffYRel] |');
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
      'note ids per file with a tolerance of 0.01 quarter units.');

  File(outPath).writeAsStringSync(out.toString());
}

Future<void> main(List<String> args) async {
  registerModelClasses();
  logLevel = LogLevel.error;

  String cppBinary = cppBinaryDefault;
  String outPath = 'tool/LAYOUT_VALIDATION.md';
  for (int i = 0; i < args.length - 1; ++i) {
    if (args[i] == '--cpp') cppBinary = args[i + 1];
    if (args[i] == '--out') outPath = args[i + 1];
  }
  final bool hasCpp = File(cppBinary).existsSync();

  final List<File> files = selectFiles();
  stdout.writeln('Validating ${files.length} corpus files '
      '(C++ binary: ${hasCpp ? "found" : "not found"})…');

  final List<FileResult> results = [];
  final String tmpPath =
      '${Directory.systemTemp.path}/validate_layout_timemap.json';

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
        compareTimemap(file, doc, result, cppBinary, tmpPath);
      }
    } catch (e) {
      result.error = e.toString();
    }
    ++done;
    if (done % 10 == 0) stdout.writeln('  … $done/${files.length}');
  }
  final File tmp = File(tmpPath);
  if (tmp.existsSync()) tmp.deleteSync();

  writeReport(results, outPath, hasCpp);
  stdout.writeln('Report written to $outPath');
}
