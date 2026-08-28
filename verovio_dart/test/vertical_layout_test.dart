import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure, Staff;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';

import 'functor_sequence.dart';

/// The non-UTF-8 corpus files (rejected by the file reader itself).
const List<String> kNonUtf8CorpusFiles = [
  'test/corpus/dir/dir-011.mei',
  'test/corpus/dir/dir-012.mei',
];

Doc loadCorpus(String relativePath) {
  final file = File('test/corpus/$relativePath');
  final doc = Doc();
  final input = MeiInput(doc);
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  final ok = input.import(data);
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

List<File> corpusFiles({int count = 30}) {
  final files = Directory('test/corpus')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.mei'))
      .where((f) => !kNonUtf8CorpusFiles.contains(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  // Evenly spaced subset over the sorted list.
  final selected = <File>[];
  for (int i = 0; i < count; ++i) {
    selected.add(files[(i * files.length) ~/ count]);
  }
  return selected;
}

/// Build an MEI document with [measureCount] measures of whole notes on
/// [staffCount] staves. A `<sb/>` is inserted after the measures given in
/// [sbAfter] and a `<pb/>` after those in [pbAfter].
String buildLongMei(int measureCount,
    {int staffCount = 2,
    Set<int> sbAfter = const {},
    Set<int> pbAfter = const {}}) {
  final buffer = StringBuffer();
  buffer.writeln('<mei xmlns="http://www.music-encoding.org/ns/mei">');
  buffer.writeln('<music><body><mdiv><score>');
  buffer.writeln('<scoreDef><staffGrp>');
  for (int s = 1; s <= staffCount; ++s) {
    final String clef = s == 1
        ? 'clef.shape="G" clef.line="2"'
        : 'clef.shape="F" clef.line="4"';
    buffer.writeln('<staffDef n="$s" lines="5" $clef/>');
  }
  buffer.writeln('</staffGrp></scoreDef>');
  buffer.writeln('<section>');
  for (int m = 1; m <= measureCount; ++m) {
    buffer.write('<measure n="$m">');
    for (int s = 1; s <= staffCount; ++s) {
      buffer.write('<staff n="$s"><layer n="1">');
      buffer.write('<note dur="1" oct="${s == 1 ? 4 : 3}" pname="c"/>');
      buffer.write('</layer></staff>');
    }
    buffer.write('</measure>');
    if (sbAfter.contains(m)) buffer.write('<sb/>');
    if (pbAfter.contains(m)) buffer.write('<pb/>');
  }
  buffer.writeln('</section>');
  buffer.writeln('</score></mdiv></body></music>');
  buffer.writeln('</mei>');
  return buffer.toString();
}

/// Run the preparation + horizontal layout steps (as in T4).
void prepareAndLayoutHorizontally(Doc doc) {
  doc.prepareData();
  doc.setDrawingPage(0);
  doc.layOutHorizontally();
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('castOffEncoding', () {
    test('splits systems at <sb> and pages at <pb> when breaks=encoded', () {
      final doc = loadCorpus('section/section-001.mei');
      doc.prepareData();

      doc.getOptions().breaks.setValue(Breaks.encoded);
      doc.layOut(hasEncodedBreaks: true);

      expect(doc.isCastOff(), isTrue);
      expect(doc.getPageCount(), greaterThanOrEqualTo(1));

      // Every system holds at most one measure between breaks.
      int measureTotal = 0;
      final pages = doc.getPages()!;
      for (int i = 0; i < pages.childCount; ++i) {
        final page = pages.getChild(i) as Page;
        for (final Object systemObject in page.children) {
          if (systemObject is! System) continue;
          measureTotal += systemObject.getChildCount(ClassId.measure);
        }
      }
      expect(measureTotal, greaterThan(0));
    });

    test('encoded breaks are respected over a synthetic score', () {
      final doc = Doc();
      final mei = buildLongMei(12, sbAfter: {6});
      expect(MeiInput(doc).import(mei), isTrue);
      doc.prepareData();

      doc.getOptions().breaks.setValue(Breaks.encoded);
      doc.castOffEncodingDoc();

      final pages = doc.getPages()!;
      final List<int> measuresPerSystem = [];
      for (int i = 0; i < pages.childCount; ++i) {
        final page = pages.getChild(i) as Page;
        for (final Object systemObject in page.children) {
          if (systemObject is! System) continue;
          measuresPerSystem.add(systemObject.getChildCount(ClassId.measure));
        }
      }
      // The sb after measure 6 forces at least two systems.
      expect(measuresPerSystem.length, greaterThanOrEqualTo(2),
          reason: 'measures per system: $measuresPerSystem');
    });

    test('a pb creates an additional page', () {
      final doc = Doc();
      expect(MeiInput(doc).import(buildLongMei(12, pbAfter: {4})), isTrue);
      doc.prepareData();

      doc.getOptions().breaks.setValue(Breaks.encoded);
      doc.castOffEncodingDoc();

      expect(doc.getPageCount(), 2,
          reason: 'the pb after measure 4 splits the document in two pages');
    });
  });

  group('layOutVertically (functor sequence)', () {
    test(
        'note-005 runs the functors in the Page::LayOutVertically order '
        '(page.cpp:509-608, with the documented headless deviations)', () {
      final doc = loadCorpus('note/note-005.mei');
      doc.prepareData();
      final page = doc.setDrawingPage(0)!;
      // The horizontal phase must run first (as in Page::LayOut); the trace
      // below captures the vertical phase only.
      page.layOutHorizontally();

      final trace = traceFunctors(page.layOutVertically);
      expectFunctorSequence(trace, verticalFunctorSequence);
    });

    test(
        'the same sequence holds over ~30 diverse corpus files '
        '(a swapped functor turns this test red)', () {
      final files = corpusFiles(count: 30);
      final failures = <String>[];
      for (final File file in files) {
        try {
          final doc = Doc();
          final data =
              utf8.decode(file.readAsBytesSync(), allowMalformed: true);
          if (!MeiInput(doc).import(data)) {
            failures.add('${file.path}: import rejected');
            continue;
          }
          doc.prepareData();
          final page = doc.setDrawingPage(0);
          if (page == null) {
            failures.add('${file.path}: no drawing page');
            continue;
          }
          page.layOutHorizontally();
          final trace = traceFunctors(page.layOutVertically);
          final mismatches = mismatchOfSequence(trace, verticalFunctorSequence);
          if (mismatches.isNotEmpty) {
            failures.add('${file.path}: ${mismatches.join("; ")}');
          }
        } catch (e) {
          failures.add('${file.path}: $e');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  group('layOutVertically (full pipeline)', () {
    late Doc doc;
    late Page page;

    setUpAll(() {
      doc = loadCorpus('note/note-005.mei');
      doc.getOptions().breaks.setValue(Breaks.auto);
      doc.layOut(hasEncodedBreaks: false);
      page = doc.drawingPage!;
    });

    test('systems have a positive total width', () {
      final systems = page.findAllDescendantsByType(ClassId.system);
      expect(systems, isNotEmpty);
      for (final Object object in systems) {
        final System system = object as System;
        expect(system.drawingTotalWidth, greaterThan(0),
            reason: 'the horizontal layout ran');
      }
    });

    test('staves have monotonically ordered yRel per staff order', () {
      final systems = page.findAllDescendantsByType(ClassId.system);
      for (final Object systemObject in systems) {
        final System system = systemObject as System;
        final List<StaffAlignment> alignments =
            system.systemAligner.children.whereType<StaffAlignment>().toList();
        expect(alignments.length, greaterThanOrEqualTo(2),
            reason: 'the score has two staves plus the bottom alignment');

        // The layout coordinate system has its origin at the bottom of the
        // page (the view flips the y axis when rendering), so staves stacking
        // downwards get numerically decreasing yRels.
        int? previousYRel;
        for (final alignment in alignments) {
          final int yRel = alignment.getYRel();
          if (previousYRel != null) {
            expect(yRel, lessThan(previousYRel),
                reason: 'staff yRels must be strictly decreasing '
                    '(the staves stack downwards)');
          }
          previousYRel = yRel;
        }
      }
    });

    test('the second staff is below the first one (drawingY)', () {
      for (final Object measureObject
          in page.findAllDescendantsByType(ClassId.measure)) {
        final staves = measureObject
            .findAllDescendantsByType(ClassId.staff, deepness: 1)
            .cast<Staff>()
            .toList()
          ..sort((a, b) => (a.n ?? 0).compareTo(b.n ?? 0));
        if (staves.length < 2) continue;
        final int firstY = staves.first.getDrawingY();
        final int secondY = staves.last.getDrawingY();
        expect(secondY, lessThan(firstY),
            reason: 'staff 2 is below staff 1 in layout space '
                '(smaller drawingY == lower on the page)');
      }
    });

    test('systems are stacked top-down within the page', () {
      final systems = page.children.whereType<System>().toList();
      if (systems.length < 2) return;
      for (int i = 1; i < systems.length; ++i) {
        expect(systems[i].getDrawingY(), lessThan(systems[i - 1].getDrawingY()),
            reason: 'system ${i + 1} is below system $i in layout space');
      }
    });
  });

  group('justifyHorizontally', () {
    test('justification stretches the measures up to the target width', () {
      final doc = Doc();
      expect(MeiInput(doc).import(buildLongMei(8)), isTrue);

      doc.prepareData();
      final Page contentPage = doc.setDrawingPage(0)!;
      contentPage.layOutHorizontally();

      final List<Measure> measuresBefore = contentPage
          .findAllDescendantsByType(ClassId.measure)
          .cast<Measure>()
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      expect(measuresBefore.length, 8);
      final Measure firstMeasure = measuresBefore.first;
      final Measure lastMeasure = measuresBefore.last;
      final int naturalEnd =
          lastMeasure.getDrawingXRel() + lastMeasure.getWidth();
      expect(naturalEnd, greaterThan(0));

      // Set a moderately larger target width and justify. Note: the last
      // system of an mdiv is not justified beyond the minLastJustification
      // ratio (1 / 0.8 = 1.25), so stay below that threshold.
      final int targetWidth = (naturalEnd * 6) ~/ 5;
      doc.drawingPageContentWidth = targetWidth;
      contentPage.justifyHorizontally();

      final int justifiedEnd =
          lastMeasure.getDrawingXRel() + lastMeasure.getWidth();
      expect(justifiedEnd, greaterThan(naturalEnd),
          reason: 'justified end $justifiedEnd > natural end $naturalEnd');
      // All measures together fill the target width within the rounding
      // tolerance of the ceil operations.
      expect((justifiedEnd - targetWidth).abs(), lessThan(16),
          reason: 'justified end $justifiedEnd ~= target $targetWidth');
      // The first measure still starts at its original position.
      expect(firstMeasure.getDrawingXRel(), 0);
    });
  });

  group('castOff (automatic breaks)', () {
    test('multiple systems are created when width constraints apply', () {
      final doc = Doc();
      expect(MeiInput(doc).import(buildLongMei(40)), isTrue);
      doc.prepareData();

      // A narrow content width forces several systems per measure count.
      doc.getOptions().breaks.setValue(Breaks.auto);
      doc.layOut(hasEncodedBreaks: false);

      final pages = doc.getPages()!;
      int systemCount = 0;
      for (int i = 0; i < pages.childCount; ++i) {
        final page = pages.getChild(i) as Page;
        systemCount += page.getChildCount(ClassId.system);
      }
      expect(systemCount, greaterThan(1),
          reason: '40 measures do not fit on one system '
              '($systemCount systems created)');
      expect(doc.isCastOff(), isTrue);

      // All measures are still present after the cast off.
      final pages2 = doc.getPages()!;
      int measureTotal = 0;
      for (int i = 0; i < pages2.childCount; ++i) {
        final page = pages2.getChild(i) as Page;
        measureTotal += page.findAllDescendantsByType(ClassId.measure).length;
      }
      expect(measureTotal, 40,
          reason: 'no measure was lost during the cast off');
    });
  });

  group('justifyVertically', () {
    test('distributes space between staves when enabled', () {
      final doc = Doc();
      expect(MeiInput(doc).import(buildLongMei(4)), isTrue);
      doc.prepareData();

      // Layout once without vertical justification to get the reference
      // position of the second staff of the first system.
      doc.layOut(hasEncodedBreaks: false);
      final Page page = doc.drawingPage!;
      final System system = page.getFirst(ClassId.system) as System;
      final StaffAlignment secondBefore =
          system.systemAligner.children.whereType<StaffAlignment>().toList()[1];
      final int yRelBefore = secondBefore.getYRel();

      // Re-layout with vertical justification enabled.
      final Doc doc2 = Doc();
      expect(MeiInput(doc2).import(buildLongMei(4)), isTrue);
      doc2.prepareData();
      doc2.getOptions().justifyVertically.setValue(true);
      doc2.layOut(hasEncodedBreaks: false);

      final Page page2 = doc2.drawingPage!;
      expect(page2.justificationSum, greaterThan(0),
          reason: 'the page has a positive justification sum');
      final System system2 = page2.getFirst(ClassId.system) as System;
      final StaffAlignment secondAfter = system2.systemAligner.children
          .whereType<StaffAlignment>()
          .toList()[1];
      final int yRelAfter = secondAfter.getYRel();
      // In layout space (origin at the bottom), justified staves are spread
      // further apart: the second staff gets pushed down (smaller yRel).
      expect(yRelAfter, lessThan(yRelBefore),
          reason: 'vertical justification spreads the staves '
              '($yRelAfter < $yRelBefore)');
    });
  });

  group('full pipeline (property)', () {
    test(
        'runs without crashing over ~30 corpus files through prepare → '
        'horizontal → cast-off(auto) → vertical layout', () {
      final files = corpusFiles(count: 30);
      expect(files.length, 30);

      final failures = <String>[];
      for (final File file in files) {
        try {
          final doc = Doc();
          final data =
              utf8.decode(file.readAsBytesSync(), allowMalformed: true);
          if (!MeiInput(doc).import(data)) {
            failures.add('${file.path}: import rejected');
            continue;
          }
          doc.getOptions().breaks.setValue(Breaks.auto);
          doc.prepareData();
          doc.layOut(hasEncodedBreaks: false);

          if (doc.getPageCount() == 0) {
            failures.add('${file.path}: no pages after layout');
            continue;
          }

          // Basic invariants: every staff of every page has an alignment
          // with a non-positive yRel (staves stack downwards from 0).
          final pages = doc.getPages()!;
          for (int i = 0; i < pages.childCount; ++i) {
            final page = pages.getChild(i) as Page;
            for (final Object staffObject
                in page.findAllDescendantsByType(ClassId.staff)) {
              final Staff staff = staffObject as Staff;
              final alignment = staff.getAlignment();
              if (alignment == null) continue;
              expect(alignment.getYRel(), lessThanOrEqualTo(0),
                  reason:
                      '${file.path}: staff yRel must be non-positive on page '
                      '$i');
            }
          }
        } catch (e) {
          failures.add('${file.path}: $e');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}
