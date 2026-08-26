import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId;
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Clefshape, Stemdirection;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show StaffDef;

Doc loadCorpus(String relativePath) {
  final file = File('test/corpus/$relativePath');
  final doc = Doc();
  final input = MeiInput(doc);
  final ok = input.import(file.readAsStringSync());
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('prepareData (stems)', () {
    test('computes up stems for quarter notes below the middle line', () {
      // stem-001.mei holds quarter notes c4 d4 e4 f4 g4 without @stem.dir;
      // with a G2 clef all of them are below the middle line, so the
      // computed direction is up for every note.
      final doc = loadCorpus('stem/stem-001.mei');
      doc.prepareData();

      final notes = doc.findAllDescendantsByType(ClassId.note);
      expect(notes.length, 5);

      for (final Object object in notes) {
        final Note note = object as Note;
        // The stem part was instantiated by the preparation.
        final Stem? stem =
            note.findDescendantByType(ClassId.stem, deepness: 1) as Stem?;
        expect(stem, isNotNull, reason: 'a stem must exist for every note');

        // c4 d4 e4 f4 g4 are all below the middle line of a G2 staff.
        expect(note.getDrawingStemDir(), Stemdirection.up,
            reason: '${note.id} is below the middle line');
        if ((stem!.len?.vu ?? 0) != 0) {
          // Notes with an encoded non-zero stem length get a drawing
          // length (the first note encodes stem.len="0").
          expect(note.getDrawingStemLen(), isNonZero,
              reason: 'stems are drawn');
        }
      }
    });

    test('respects encoded stem directions (stem-005.mei)', () {
      final doc = loadCorpus('stem/stem-005.mei');
      doc.prepareData();

      var sawUp = false;
      var sawDown = false;
      for (final Object object in doc.findAllDescendantsByType(ClassId.note)) {
        final Note note = object as Note;
        if (note.stemDir == Stemdirection.up) {
          expect(note.getDrawingStemDir(), Stemdirection.up);
          sawUp = true;
        } else if (note.stemDir == Stemdirection.down) {
          expect(note.getDrawingStemDir(), Stemdirection.down);
          sawDown = true;
        }
      }
      expect(sawUp, isTrue, reason: 'stem-005 encodes stem.dir=up');
      expect(sawDown, isTrue, reason: 'stem-005 encodes stem.dir=down');
    });
  });

  group('prepareData (chords)', () {
    test('computes chord directions and shares stems with chord tones',
        () {
      final doc = loadCorpus('chord/chord-001.mei');
      doc.prepareData();

      final chords = doc.findAllDescendantsByType(ClassId.chord)
          .cast<Chord>()
          .toList();
      expect(chords.length, greaterThan(3));

      for (final Chord chord in chords) {
        // Every chord got a direction (up or down) without crashing and
        // shares its stem with all its notes.
        expect(
            chord.getDrawingStemDir(),
            anyOf(Stemdirection.up, Stemdirection.down));
        expect(chord.hasDrawingStem, isTrue);
        for (final Object child in chord.getList()) {
          final Note note = child as Note;
          expect(
              identical(note.getDrawingStem(), chord.getDrawingStem()),
              isTrue);
          expect(note.getDrawingStemDir(), chord.getDrawingStemDir());
        }

        // Dotted chords have a Dots child with dot locations.
        if ((chord.dots ?? 0) > 0) {
          final dots =
              chord.findDescendantByType(ClassId.dots, deepness: 1)
                  as Dots?;
          expect(dots, isNotNull);
          expect(dots!.dotLocs, isNotEmpty,
              reason: 'dot locations were computed');
        }
      }
    });
  });

  group('prepareData (dots)', () {
    test('counts dots for dotted durations (dot-001.mei)', () {
      final doc = loadCorpus('dot/dot-001.mei');
      doc.prepareData();

      final dottedNotes = doc.findAllDescendantsByType(ClassId.note)
          .cast<Note>()
          .where((Note note) => (note.dots ?? 0) > 0)
          .toList();
      expect(dottedNotes, isNotEmpty);

      for (final Note note in dottedNotes) {
        final dots =
            note.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
        expect(dots, isNotNull, reason: 'a Dots child exists on dotted notes');
        expect(dots!.dotLocs, isNotEmpty);
        for (final Set<int> locs in dots.dotLocs.values) {
          expect(locs, isNotEmpty);
        }
      }
    });
  });

  group('scoreDefSetCurrentDoc', () {
    test('propagates clef changes to the layer drawing values', () {
      final doc = loadCorpus('clef/clef-001.mei');
      doc.prepareData();

      expect(doc.scoreDefSetCurrentDoc(), isTrue);

      // Every staff received its drawing staffDef.
      final staves =
          doc.findAllDescendantsByType(ClassId.staff).cast<Staff>().toList();
      expect(staves, isNotEmpty);
      for (final Staff staff in staves) {
        expect(staff.drawingStaffDef, isNotNull,
            reason: 'staff ${staff.n} got its drawing staffDef');
        final StaffDef staffDef = staff.drawingStaffDef as StaffDef;
        // The current clef / keySig info was propagated from the encoded
        // scoreDef (G2 clef, keysig 2s in clef-001).
        expect(staffDef.getCurrentClef().hasShape, isTrue);
        expect(staffDef.getCurrentKeySig().hasSig, isTrue,
            reason: 'keysig propagated to the current values');
      }

      // Measure 6 of staff 2 contains two <clef> changes (to F4 and back
      // to G2). A drawing scoreDef is instantiated on the measure following
      // the change (mirroring ScoreDefSetCurrentFunctor::VisitMeasure),
      // while the layers of the system-start measure hold the staffDef
      // clefs.
      final measures = doc.findAllDescendantsByType(ClassId.measure)
          .cast<Measure>()
          .toList();
      expect(measures.length, 3);
      expect(measures[0].getDrawingScoreDef(), isNotNull,
          reason: 'first measure of the system holds a drawing scoreDef');
      expect(measures[1].getDrawingScoreDef(), isNull);
      final lastScoreDef = measures[2].getDrawingScoreDef();
      expect(lastScoreDef, isNotNull,
          reason: 'a drawing scoreDef follows the clef change');
      // The restored G2 clef (end of measure 6) is the current one.
      final StaffDef changedDef =
          lastScoreDef!.getStaffDef(2) as StaffDef;
      expect(changedDef.getCurrentClef().shape, Clefshape.g);

      // The layers of the first measure received their drawing values.
      final firstStaff = measures[0]
          .findAllDescendantsByType(ClassId.staff, deepness: 1)
          .cast<Staff>()
          .firstWhere((Staff staff) => staff.n == 2);
      final firstLayer = firstStaff.getFirst(ClassId.layer) as Layer;
      expect(firstLayer.staffDefClef, isNotNull,
          reason: 'layer of the system-start measure holds the current '
              'clef');
      expect(firstLayer.staffDefClef!.shape, Clefshape.g);
    });

    test('scoreDefSetCurrentDoc is idempotent unless forced', () {
      final doc = loadCorpus('clef/clef-001.mei');
      doc.prepareData();
      expect(doc.scoreDefSetCurrentDoc(), isTrue);

      final staves = doc.findAllDescendantsByType(ClassId.staff);
      // Second call without force does nothing (state kept).
      expect(doc.scoreDefSetCurrentDoc(), isTrue);
      for (final Object object in staves) {
        expect((object as Staff).drawingStaffDef, isNotNull);
      }
      // Forced call unsets and re-sets everything.
      expect(doc.scoreDefSetCurrentDoc(force: true), isTrue);
      for (final Object object in staves) {
        expect((object as Staff).drawingStaffDef, isNotNull);
      }
    });
  });

  group('calculateTimemap', () {
    test('produces monotonic measure onset times', () {
      final doc = loadCorpus('stem/stem-001.mei');
      doc.prepareData();
      doc.calculateTimemap();

      final measures = doc.findAllDescendantsByType(ClassId.measure)
          .cast<Measure>()
          .toList();
      expect(measures, isNotEmpty);

      double previousMs = -1.0;
      for (final Measure measure in measures) {
        final double onset = measure.getRealTimeOnsetMilliseconds();
        expect(onset, greaterThanOrEqualTo(previousMs),
            reason: 'measure onsets are monotonic');
        previousMs = onset;
      }

      // Note level onsets were computed (deviation note: the measure
      // alignment times stay 0 until the horizontal layout of Phase 4 fills
      // the measure aligners).
      final onsets = doc
          .findAllDescendantsByType(ClassId.note)
          .cast<Note>()
          .map((Note note) => note.scoreTimeOnset.toDouble())
          .toList()
        ..sort();
      expect(onsets.first, 0.0);
      if (onsets.length > 1) {
        expect(onsets.last, greaterThan(0.0));
      }
    });
  });

  group('setDrawingPage / resetDataPage', () {
    test('sets and unsets the current drawing page', () {
      final doc = loadCorpus('stem/stem-001.mei');
      doc.prepareData();

      final page = doc.setDrawingPage(0);
      expect(page, isNotNull);
      expect(identical(page, doc.drawingPage), isTrue);
      expect(doc.drawingPageHeight, greaterThan(0));
      expect(doc.setDrawingPage(42), isNull);

      doc.resetDataPage();
      expect(doc.drawingPage, isNull);
    });
  });
}
