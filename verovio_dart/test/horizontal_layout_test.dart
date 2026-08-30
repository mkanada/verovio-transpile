import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';

import 'functor_sequence.dart';

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
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  // Evenly spaced subset over the sorted list.
  final selected = <File>[];
  for (int i = 0; i < count; ++i) {
    selected.add(files[(i * files.length) ~/ count]);
  }
  return selected;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('layOutHorizontally (note-001)', () {
    late Doc doc;
    late Page page;

    setUpAll(() {
      doc = loadCorpus('note/note-001.mei');
      doc.prepareData();
      page = doc.setDrawingPage(0)!;
      page.layOutHorizontally();
    });

    test('measures have alignments with monotonically increasing xRel', () {
      final measures = page.findAllDescendantsByType(ClassId.measure);
      expect(measures, isNotEmpty);

      for (final Object object in measures) {
        final Measure measure = object as Measure;
        final aligner = measure.measureAligner;
        expect(aligner.childCount, greaterThan(0),
            reason: 'the measure aligner was filled');

        int previousX = -1 << 30;
        for (final Object child in aligner.children) {
          final Alignment? alignment = child is Alignment ? child : null;
          expect(alignment, isNotNull);
          expect(alignment!.getXRel(), greaterThanOrEqualTo(previousX),
              reason: 'alignment xRel must be monotonic within a measure');
          previousX = alignment.getXRel();
        }
        // The right barline / end of the measure are placed after the
        // content.
        expect(
            measure.measureAligner.getRightAlignment()!.getXRel(),
            greaterThan(
                measure.measureAligner.getLeftBarLineAlignment()!.getXRel()));
      }
    });

    test('notes have a non-zero position and increase within a layer', () {
      for (final Object staffObject
          in page.findAllDescendantsByType(ClassId.staff)) {
        final Staff staff = staffObject as Staff;
        int? previousX;
        for (final Object layerObject
            in staff.findAllDescendantsByType(ClassId.layer)) {
          final Layer layer = layerObject as Layer;
          for (final Object childObject in layer.children) {
            if (childObject is! Note) continue;
            final Note note = childObject;
            expect(note.getAlignment(), isNotNull,
                reason: 'every note was aligned');
            final int x = note.getDrawingX();
            expect(x, isNot(0), reason: 'notes have a non-zero position');
            if (previousX != null) {
              expect(x, greaterThan(previousX),
                  reason: 'second note xRel > first note xRel '
                      '(within the same layer)');
            }
            previousX = x;
          }
        }
      }
    });

    test('the right barline alignment is at or after the last note', () {
      for (final Object object
          in page.findAllDescendantsByType(ClassId.measure)) {
        final Measure measure = object as Measure;

        // Find the last note alignment on any staff.
        int? lastNoteX;
        for (final Object childObject in measure.measureAligner.children) {
          final Alignment alignment = childObject as Alignment;
          if (!alignment.hasTimestampOnly() &&
              alignment.getType() != AlignmentType.measureRightBarline &&
              alignment.getType() != AlignmentType.measureEnd) {
            lastNoteX = alignment.getXRel();
          }
        }

        final int rightBarLineX =
            measure.measureAligner.getRightBarLineAlignment()!.getXRel();
        expect(rightBarLineX, greaterThanOrEqualTo(lastNoteX ?? 0),
            reason: 'measure right barline x >= last note x');
      }
    });

    test('measures are aligned within their system (AlignMeasures)', () {
      final measures = page
          .findAllDescendantsByType(ClassId.measure)
          .cast<Measure>()
          .toList();
      for (int i = 1; i < measures.length; ++i) {
        expect(measures[i].getDrawingXRel(),
            greaterThan(measures[i - 1].getDrawingXRel()),
            reason: 'measures are laid out from left to right');
      }
    });
  });

  group('layOutHorizontally (gracenote-001)', () {
    test('grace notes are spaced narrower than full notes', () {
      final doc = loadCorpus('gracenote/gracenote-001.mei');
      doc.prepareData();
      doc.setDrawingPage(0)!.layOutHorizontally();

      // Collect the spacing between consecutive grace notes within each
      // grace group and between consecutive full notes.
      final List<int> graceSteps = [];
      final List<int> fullNoteSteps = [];

      int? previousFullNoteX;
      final graceGroupXs = <int>[];

      for (final Object object in doc.findAllDescendantsByType(ClassId.note)) {
        final Note note = object as Note;
        final Alignment? alignment = note.getAlignment();
        expect(alignment, isNotNull);
        final int x = note.getDrawingX();

        if (!note.isGraceNote()) {
          if (graceGroupXs.length >= 2) {
            for (int i = 1; i < graceGroupXs.length; ++i) {
              graceSteps.add(graceGroupXs[i] - graceGroupXs[i - 1]);
            }
          }
          graceGroupXs.clear();
          if (previousFullNoteX != null) {
            fullNoteSteps.add(x - previousFullNoteX);
          }
          previousFullNoteX = x;
        } else {
          graceGroupXs.add(x);
        }
      }
      if (graceGroupXs.length >= 2) {
        for (int i = 1; i < graceGroupXs.length; ++i) {
          graceSteps.add(graceGroupXs[i] - graceGroupXs[i - 1]);
        }
      }

      expect(graceSteps, isNotEmpty, reason: 'the corpus has grace groups');
      expect(fullNoteSteps, isNotEmpty);

      final int averageGraceStep =
          graceSteps.reduce((a, b) => a + b) ~/ graceSteps.length;
      final int averageFullStep =
          fullNoteSteps.reduce((a, b) => a + b) ~/ fullNoteSteps.length;

      expect(averageGraceStep, lessThan(averageFullStep),
          reason: 'grace notes are spaced narrower than full notes');
    });
  });

  group('layOutHorizontally (functor sequence)', () {
    test(
        'note-001 runs the functors in the Page::LayOutHorizontally order '
        '(page.cpp:396-497)', () {
      final doc = loadCorpus('note/note-001.mei');
      doc.prepareData();
      final page = doc.setDrawingPage(0)!;

      final trace = traceFunctors(page.layOutHorizontally);
      expectFunctorSequence(trace, horizontalFunctorSequence);
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
          final trace = traceFunctors(page.layOutHorizontally);
          final mismatches =
              mismatchOfSequence(trace, horizontalFunctorSequence);
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

  group('layOutHorizontally (property)', () {
    test(
        'runs without crashing over ~30 diverse corpus files and keeps '
        'x ordering per measure', () {
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
          doc.prepareData();
          final page = doc.setDrawingPage(0);
          if (page == null) {
            failures.add('${file.path}: no drawing page');
            continue;
          }
          page.layOutHorizontally();

          // Monotonic x ordering per staff: the alignments holding elements
          // of a staff appear in non-decreasing xRel order.
          for (final Object measureObject
              in page.findAllDescendantsByType(ClassId.measure)) {
            final Measure measure = measureObject as Measure;
            int previous = -1 << 30;
            for (final Object child in measure.measureAligner.children) {
              final Alignment alignment = child as Alignment;
              final int x = alignment.getXRel();
              expect(x, greaterThanOrEqualTo(previous),
                  reason:
                      '${file.path}: non-monotonic alignment xRel in measure '
                      '${measure.n}');
              previous = x;
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
