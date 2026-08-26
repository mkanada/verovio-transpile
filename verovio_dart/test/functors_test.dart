import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/reset_functor.dart' show ResetDataFunctor;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

Doc loadCorpusMei() {
  final file = File('test/corpus/bracketspan/bracketspan-001.mei');
  final doc = Doc();
  final input = MeiInput(doc);
  final ok = input.import(file.readAsStringSync());
  expect(ok, isTrue, reason: 'MEI import should succeed');
  return doc;
}

/// Builds Doc → Pages → Page → System → Section → Measure → Staff → Layer
/// with two notes; the first one sits inside an app/lem editorial wrapper.
Doc buildEditorialDoc() {
  final doc = Doc();
  final pages = Pages();
  final page = Page();
  final system = System();
  final section = Section();
  final measure = Measure();
  final staff = Staff();
  final layer = Layer();
  final app = App();
  final lem = Lem();
  final wrappedNote = Note();
  final plainNote = Note();

  doc.addChild(pages);
  pages.addChild(page);
  page.addChild(system);
  system.addChild(section);
  section.addChild(measure);
  measure.addChild(staff);
  staff.addChild(layer);
  layer.addChild(app);
  app.addChild(lem);
  lem.addChild(wrappedNote);
  layer.addChild(plainNote);

  return doc;
}

/// Records the objects visited through [Functor.visit].
class ProbeFunctor extends Functor {
  final List<Object> visited = [];

  @override
  FunctorCode visit(Object object) {
    visited.add(object);
    return super.visit(object);
  }
}

/// A functor returning FUNCTOR_SIBLINGS on measures.
class SiblingsAtMeasureFunctor extends Functor {
  int measuresVisited = 0;
  int notesVisited = 0;

  @override
  FunctorCode visitMeasure(Measure measure) {
    measuresVisited++;
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitNote(Note note) {
    notesVisited++;
    return FunctorCode.continue_;
  }
}

/// A functor recording end visits.
class EndProbeFunctor extends Functor {
  final List<String> events = [];

  @override
  FunctorCode visitLayer(Layer layer) {
    events.add('layer');
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    events.add('note');
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNoteEnd(Note note) {
    events.add('noteEnd');
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerEnd(Layer layer) {
    events.add('layerEnd');
    return FunctorCode.continue_;
  }
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('CountFunctor', () {
    test('counts measures, staves and notes of a corpus MEI file', () {
      final doc = loadCorpusMei();
      final counter = CountFunctor();
      doc.process(counter);

      expect(counter.count(ClassId.measure), greaterThan(0));
      expect(counter.count(ClassId.staff), greaterThan(0));
      expect(counter.count(ClassId.note), greaterThan(0));
      // Every node is counted exactly once: the total must match an
      // independent flat traversal of the tree (both include the doc).
      final List<Object> flat = [];
      doc.fillFlatList(flat);
      expect(counter.total, flat.length,
          reason: 'every tree node must be counted exactly once');
    });

    test('typed dispatch reaches the typed collectors', () {
      final doc = loadCorpusMei();
      final collector = MeasureStaffLayerCollector();
      doc.process(collector);

      expect(collector.measures.length, greaterThan(0));
      expect(collector.staves.length,
          doc.getDescendantCount(ClassId.staff));
      expect(collector.layers.length, greaterThan(0));
    });
  });

  group('traversal semantics', () {
    test('FUNCTOR_SIBLINGS on VisitMeasure skips its children', () {
      final doc = loadCorpusMei();

      final probe = ProbeFunctor();
      doc.process(probe);
      final noteCount =
          probe.visited.where((o) => o.classId == ClassId.note).length;
      expect(noteCount, greaterThan(0));

      final siblings = SiblingsAtMeasureFunctor();
      doc.process(siblings);
      expect(siblings.measuresVisited, greaterThan(0));
      expect(siblings.notesVisited, 0,
          reason: 'notes live below measures and must not be visited');
      // The siblings code must be reset once handled.
      expect(siblings.code, FunctorCode.continue_);
    });

    test('editorial elements do not count towards deepness', () {
      final doc = buildEditorialDoc();
      final layer =
          doc.findDescendantByType(ClassId.layer)!;

      // Deepness 1 from the layer reaches through app/lem to the note.
      final probe1 = ProbeFunctor();
      layer.process(probe1, deepness: 1);
      final notesAtDepthOne =
          probe1.visited.where((o) => o.classId == ClassId.note).length;
      expect(notesAtDepthOne, 2,
          reason: 'app/lem are editorial and must not consume depth');

      // Deepness 0 stops right at the layer children.
      final probe0 = ProbeFunctor();
      layer.process(probe0, deepness: 0);
      expect(
          probe0.visited.where((o) => o.classId == ClassId.note), isEmpty);

      // The same holds from the measure with deepness 3:
      // staff (2) → layer (1) → app/lem free → notes reached.
      final measure = doc.findDescendantByType(ClassId.measure)!;
      final probeMeasure = ProbeFunctor();
      measure.process(probeMeasure, deepness: 3);
      expect(
          probeMeasure.visited
              .where((o) => o.classId == ClassId.note)
              .length,
          2);
    });

    test('end visits run after the children (end interface)', () {
      final doc = buildEditorialDoc();
      final layer = doc.findDescendantByType(ClassId.layer)!;
      final endProbe = EndProbeFunctor();
      // Deepness 2: like in the C++, a node reached with deepness == 0 is
      // visited but does *not* get its end visit called.
      layer.process(endProbe, deepness: 2);

      expect(endProbe.events, [
        'layer',
        'note',
        'noteEnd',
        'note',
        'noteEnd',
        'layerEnd',
      ]);
    });

    test('direction backward visits children in reverse order', () {
      final doc = buildEditorialDoc();
      final layer = doc.findDescendantByType(ClassId.layer)!;

      final probeForward = ProbeFunctor();
      layer.process(probeForward, deepness: 1);

      final probeBackward = ProbeFunctor()..setDirection(backward);
      layer.process(probeBackward, deepness: 1);

      // The object itself is always visited first; the first child differs.
      expect(probeForward.visited.first.classId, ClassId.layer);
      expect(probeBackward.visited.first.classId, ClassId.layer);
      expect(probeForward.visited[1].classId, ClassId.app,
          reason: 'forward starts with the first child (the app)');
      expect(probeBackward.visited[1].classId, ClassId.note,
          reason: 'backward starts with the last child (a note)');
    });

    test('filters restrict child traversal', () {
      final doc = buildEditorialDoc();
      final measure = doc.findDescendantByType(ClassId.measure)!;
      final filters = Filters();
      filters.add(ClassIdsComparison([ClassId.staff]));

      final probe = ProbeFunctor();
      probe.setFilters(filters);
      measure.process(probe, deepness: 2);
      expect(
          probe.visited.where((o) => o.classId == ClassId.layer), isEmpty,
          reason: 'layers live below staves which are filtered out');
      expect(probe.visited.any((o) => o.classId == ClassId.staff), isTrue);
    });
  });

  group('ResetDataFunctor', () {
    test('resets the minimal drawing state of layer elements', () {
      final doc = buildEditorialDoc();
      final layer = doc.findDescendantByType(ClassId.layer)
          as Layer?;
      final note = layer!.getFirst(ClassId.note) as Note;
      note.drawingCueSize = true;
      note.crossStaff = Staff();
      note.crossLayer = Layer();

      final reset = ResetDataFunctor();
      doc.process(reset);

      expect(note.drawingCueSize, isFalse);
      expect(note.crossStaff, isNull);
      expect(note.crossLayer, isNull);
    });
  });
}
