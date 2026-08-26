import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/mensural_neume.dart'
    show CalcLigatureOrNeumePosFunctor;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Note;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show System;

Doc loadDoc(String relativePath) {
  final file = File('test/corpus/$relativePath');
  final doc = Doc();
  final input = MeiInput(doc);
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  final ok = input.import(data);
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('CalcLigatureOrNeumePosFunctor - ligatures', () {
    test('ligature notes get drawing shapes and increasing xRel', () {
      final doc = loadDoc('ligature/ligature-001.mei');
      doc.prepareData();
      final List<Object> ligatures =
          doc.findAllDescendantsByType(ClassId.ligature);
      expect(ligatures, isNotEmpty);

      // Run the functor directly on the root (as wired in layOutVertically).
      final functor = CalcLigatureOrNeumePosFunctor(doc);
      doc.process(functor);

      for (final Object object in ligatures) {
        final Ligature ligature = object as Ligature;
        final List<Object> notes = ligature.getList();
        // The corpus ligatures hold at least two notes.
        expect(notes.length, greaterThanOrEqualTo(2),
            reason: 'ligature ${ligature.id}');
        expect(ligature.drawingShapes.length, notes.length,
            reason: 'one shape per note');
        int? previousXRel;
        for (final Object noteObject in notes) {
          final Note note = noteObject as Note;
          if (previousXRel != null) {
            expect(note.drawingXRel, greaterThan(previousXRel),
                reason: 'note xRel must increase within a ligature '
                    '(got $previousXRel -> ${note.drawingXRel})');
          }
          previousXRel = note.drawingXRel;
          final int shape = ligature.getDrawingNoteShape(note);
          expect(shape, greaterThanOrEqualTo(0),
              reason: 'every list note has a shape');
        }
      }
    });

    test('B-B descending opening ligature gets oblique + left stem down',
        () {
      // First ligature of ligature-001.mei: c4 - a3 (brevis, brevis).
      final doc = loadDoc('ligature/ligature-001.mei');
      doc.prepareData();
      final functor = CalcLigatureOrNeumePosFunctor(doc);
      doc.process(functor);

      final Ligature ligature =
          doc.findDescendantByType(ClassId.ligature) as Ligature;
      // Mirrors the B - B rule: down + first note => OBLIQUE | STEM_LEFT_DOWN.
      expect(ligature.drawingShapes[0],
          ligatureOblique | ligatureStemLeftDown);
    });

    test('all ligature corpus files run through the full pipeline', () {
      final files = Directory('test/corpus/ligature')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mei'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      expect(files.length, greaterThanOrEqualTo(10));

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

          for (final Object object
              in doc.findAllDescendantsByType(ClassId.ligature)) {
            final Ligature ligature = object as Ligature;
            int? previousXRel;
            int index = 0;
            for (final Object noteObject in ligature.getList()) {
              final Note note = noteObject as Note;
              if (previousXRel != null) {
                // Non-decreasing only: stacked notes intentionally share
                // the x position of the previous note.
                expect(note.drawingXRel,
                    greaterThanOrEqualTo(previousXRel),
                    reason:
                        '${file.path}: ligature xRel must not decrease '
                        '(note $index of ${ligature.id})');
              }
              previousXRel = note.drawingXRel;
              ++index;
            }
          }
        } catch (e) {
          failures.add('${file.path}: $e');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  group('CalcLigatureOrNeumePosFunctor - neumes', () {
    test('neume ncs receive glyphs and ordered xRel positions', () {
      final doc = loadDoc('neume/neume-001.mei');
      doc.getOptions().breaks.setValue(Breaks.auto);
      doc.prepareData();
      doc.layOut(hasEncodedBreaks: false);

      final List<Object> neumes = doc.findAllDescendantsByType(ClassId.neume);
      expect(neumes.length, greaterThan(0));

      int ncCount = 0;
      for (final Object neumeObject in neumes) {
        final Neume neume = neumeObject as Neume;
        final List<Object> ncs =
            neume.findAllDescendantsByType(ClassId.nc, deepness: 1);
        expect(ncs.length, greaterThanOrEqualTo(1),
            reason: 'a neume holds at least one nc');

        int? previousXRel;
        for (final Object ncObject in ncs) {
          final Nc nc = ncObject as Nc;
          ++ncCount;
          // Every nc got its glyph(s) assigned by the functor.
          expect(nc.drawingGlyphs, isNotEmpty,
              reason: 'nc ${nc.id} must have a glyph');
          expect(nc.drawingGlyphs[0].fontNo, isNot(0),
              reason: 'nc ${nc.id} fontNo must be set');
          if (doc.hasFacsimile()) continue;
          if (previousXRel != null) {
            expect(nc.drawingXRel,
                greaterThanOrEqualTo(previousXRel),
                reason: 'nc xRel must be non-decreasing within a neume');
          }
          previousXRel = nc.drawingXRel;
        }
      }
      expect(ncCount, greaterThan(50),
          reason: 'neume-001.mei has many neume components');
    });

    test('all neume corpus files run without crashing', () {
      final files = Directory('test/corpus/neume')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mei'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

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
        } catch (e) {
          failures.add('${file.path}: $e');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  group('ConvertToCastOffMensural', () {
    test('unmeasured mensural staff is split into segments', () {
      // mensural-004.mei: one unmeasured staff with four longa/brevis notes.
      // Mirrors the C++ structure count: four segments (the C++ SVG output
      // renders one staff group per segment).
      final doc = loadDoc('mensural/mensural-004.mei');
      doc.prepareData();
      expect(doc.isMensuralMusicOnly(), isTrue);

      doc.convertToCastOffMensuralDoc(MensuralCastOffType.init);

      expect(doc.mensuralCastOff, isTrue);
      // Mirrors the C++: the conversion resets the data page at the end.
      final Page page = doc.setDrawingPage(0)!;
      final System system = page.getFirst(ClassId.system) as System;
      final List<Measure> segments =
          system.children.whereType<Measure>().toList();
      expect(segments.length, greaterThan(0),
          reason: 'segments are created from the unmeasured measure');
      expect(segments.length, 4,
          reason: 'one segment per note-aligned breakpoint '
              '(matches the C++ structure)');
      for (final Measure segment in segments) {
        expect(segment.measureType, MeasureType.unmeasured);
      }
    });

    test('ligature corpus file is split into multiple segments', () {
      // ligature-001.mei: two staves with four ligatures each; the C++
      // produces four segments (eight staff groups in the rendered SVG).
      final doc = loadDoc('ligature/ligature-001.mei');
      doc.prepareData();
      doc.convertToCastOffMensuralDoc(MensuralCastOffType.init);

      final Page page = doc.setDrawingPage(0)!;
      final System system = page.getFirst(ClassId.system) as System;
      final int segments = system.children.whereType<Measure>().length;
      expect(segments, greaterThan(0));
      expect(segments, 4,
          reason: 'mirrors the C++ structure count '
              '(8 staff groups / 2 staves)');
    });

    test('unset conversion reverts to a single unmeasured measure', () {
      final doc = loadDoc('mensural/mensural-004.mei');
      doc.prepareData();
      doc.convertToCastOffMensuralDoc(MensuralCastOffType.init);
      doc.convertToCastOffMensuralDoc(MensuralCastOffType.unset);

      final Page page = doc.setDrawingPage(0)!;
      final System system = page.getFirst(ClassId.system) as System;
      // After un-cast-off only one measure per section remains.
      expect(system.children.whereType<Measure>().length, 1);
    });
  });
}
