import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show CurvatureCurvedir;
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

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

/// Collect all the descendants of [root] matching [match].
List<Object> collect(Object root, bool Function(ClassId) match) =>
    root.findAllDescendantsByClassIdPredicate(match);

/// Collect the floating positioners attached to the staff alignments below
/// [root].
void collectPositioners(Object root, List<FloatingPositioner> result) {
  if (root.isClass(ClassId.system)) {
    // The staff alignments hang off the system aligner which is a field of
    // the system, not a child in the object tree.
    final dynamic system = root;
    for (final Object alignment
        in system.systemAligner.childrenForModification) {
      collectPositioners(alignment, result);
    }
  }
  if (root.isClass(ClassId.staffAlignment)) {
    final alignment = root as dynamic;
    for (final FloatingPositioner positioner
        in alignment.getFloatingPositioners()) {
      result.add(positioner);
    }
  }
  for (final Object child in root.childrenForModification) {
    collectPositioners(child, result);
  }
}

/// Run the full layout pipeline over [doc].
void layout(Doc doc) {
  doc.prepareData();
  doc.layOut(hasEncodedBreaks: true);
}

/// Build an MEI document with one measure containing three notes on layer 1
/// and a slur above them; when [addUpperVoice] the second layer holds high
/// notes colliding with the slur.
String buildSlurMei({required bool addUpperVoice}) {
  final buffer = StringBuffer();
  buffer.writeln('<mei xmlns="http://www.music-encoding.org/ns/mei">');
  buffer.writeln('<music><body><mdiv><score>');
  buffer.writeln(
      '<scoreDef><staffGrp><staffDef n="1" lines="5" clef.shape="G" clef.line="2"/></staffGrp></scoreDef>');
  buffer.writeln('<section><measure n="1">');
  buffer.write('<staff n="1"><layer n="1">');
  buffer.write(
      '<note xml:id="n1" dur="4" oct="4" pname="c" stem.dir="up"/>');
  buffer.write('<note xml:id="n2" dur="4" oct="4" pname="e" stem.dir="up"/>');
  buffer.write(
      '<note xml:id="n3" dur="4" oct="4" pname="g" stem.dir="up"/>');
  buffer.writeln('</layer>');
  if (addUpperVoice) {
    // A second voice with notes right under the slur arc: their bounding
    // boxes collide with the initial curve and must be avoided.
    buffer.write('<layer n="2">');
    buffer.write(
        '<note dur="2" oct="4" pname="g" stem.dir="up"/>');
    buffer.write(
        '<note dur="2" oct="4" pname="a" stem.dir="up"/>');
    buffer.write(
        '<note dur="2" oct="4" pname="b" stem.dir="up"/>');
    buffer.writeln('</layer>');
  }
  buffer.writeln('</staff>');
  buffer.writeln(
      '<slur startid="#n1" endid="#n3" curvedir="above"/>');
  buffer.writeln('</measure></section>');
  buffer.writeln('</score></mdiv></body></music>');
  buffer.writeln('</mei>');
  return buffer.toString();
}

Doc loadMeiString(String mei) {
  final doc = Doc();
  final input = MeiInput(doc);
  expect(input.import(mei), isTrue);
  return doc;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
    Resources.defaultPath = 'assets/data';
  });

  group('control event positioners', () {
    test('every visible slur gets a floating positioner with a non trivial '
        'bounding box', () {
      for (final name in ['slur/slur-001.mei', 'slur/slur-005.mei']) {
        final doc = loadCorpus(name);
        layout(doc);

        final slurs = <Object>[
          ...collect(doc, (id) => id == ClassId.slur),
        ];
        expect(slurs, isNotEmpty, reason: name);

        final positioners = <FloatingPositioner>[];
        collectPositioners(doc, positioners);
        for (final Object slurObject in slurs) {
          final slur = slurObject as Slur;
          if (!slur.hasStartAndEnd) continue;
          final positioner = slur.getCurrentFloatingPositioner();
          expect(positioner, isNotNull, reason: name);
          expect(positioner!.hasContentBB(), isTrue, reason: name);
          final int width =
              positioner.getContentRight() - positioner.getContentLeft();
          expect(width, greaterThan(0), reason: name);
          positioners.remove(positioner);
        }
      }
    });

    test('every visible hairpin gets a floating positioner with a non trivial '
        'bounding box', () {
      for (final name in [
        'hairpin/hairpin-001.mei',
        'hairpin/hairpin-002.mei',
      ]) {
        final doc = loadCorpus(name);
        layout(doc);

        final hairpins = collect(doc, (id) => id == ClassId.hairpin);
        expect(hairpins, isNotEmpty, reason: name);
        for (final Object hairpinObject in hairpins) {
          final hairpin = hairpinObject as Hairpin;
          if (!hairpin.hasStartAndEnd) continue;
          final positioner = hairpin.getCurrentFloatingPositioner();
          expect(positioner, isNotNull, reason: name);
          expect(positioner!.hasContentBB(), isTrue, reason: name);
          final int width =
              positioner.getContentRight() - positioner.getContentLeft();
          expect(width, greaterThan(0), reason: name);
        }
      }
    });

    test('the slur curve direction matches the calculated drawing direction',
        () {
      final doc = loadCorpus('slur/slur-013.mei');
      layout(doc);

      final positioners = <FloatingPositioner>[];
      collectPositioners(doc, positioners);
      final curves = positioners.whereType<FloatingCurvePositioner>().toList();
      expect(curves.length, greaterThanOrEqualTo(2));

      bool hasDir(CurvatureCurvedir dir) =>
          curves.any((curve) => curve.getDir() == dir);
      // slur-013 connects plain notes (slur above) and chords (slur below).
      expect(hasDir(CurvatureCurvedir.above), isTrue);
      expect(hasDir(CurvatureCurvedir.below), isTrue);
    });

    test('the positioner x range covers the boundary elements', () {
      final doc = loadCorpus('slur/slur-001.mei');
      layout(doc);

      final slurs = collect(doc, (id) => id == ClassId.slur).cast<Slur>();
      expect(slurs, isNotEmpty);
      for (final Slur slur in slurs) {
        final positioner = slur.getCurrentFloatingPositioner();
        expect(positioner, isNotNull);
        final Object? start = slur.getStart();
        final Object? end = slur.getEnd();
        expect(start, isNotNull);
        expect(end, isNotNull);
        // Structural invariant: the ordered x range covers the boundary
        // elements (the endpoints are adjusted by the notehead radii, so the
        // curve may start slightly right of the start element).
        final int startX = start!.getDrawingX();
        final int endX = end!.getDrawingX();
        expect(positioner!.getContentLeft(),
            lessThanOrEqualTo(math.max(startX, endX)));
        expect(positioner.getContentRight(),
            greaterThanOrEqualTo(math.min(startX, endX)));
      }
    });
  });

  group('slur collision adjustment', () {
    /// The apex (max y) of the first slur curve of the document.
    double apexOf(Doc doc) {
      layout(doc);
      final positioners = <FloatingPositioner>[];
      collectPositioners(doc, positioners);
      final curves = positioners.whereType<FloatingCurvePositioner>().toList();
      expect(curves, isNotEmpty);
      final List<Point> points = curves.first.getPoints();
      double apex = points.first.y.toDouble();
      for (final Point point in points) {
        apex = math.max(apex, point.y.toDouble());
      }
      return apex;
    }

    test('a slur is bent away from colliding elements of another voice', () {
      // Hand derived expectation from the C++ algorithm structure: the
      // spanned elements of the upper voice collide with the initial curve,
      // so AdjustSlursFunctor applies endpoint and control point shifts
      // moving the curve upwards (away from the obstacles).
      final baseline = loadMeiString(buildSlurMei(addUpperVoice: false));
      final colliding = loadMeiString(buildSlurMei(addUpperVoice: true));

      final double baselineApex = apexOf(baseline);
      final double collidingApex = apexOf(colliding);

      expect(collidingApex, greaterThan(baselineApex));
    });

    test('spanned elements are collected for collision avoidance', () {
      final colliding = loadMeiString(buildSlurMei(addUpperVoice: true));
      layout(colliding);

      final positioners = <FloatingPositioner>[];
      collectPositioners(colliding, positioners);
      final curves = positioners.whereType<FloatingCurvePositioner>().toList();
      expect(curves, isNotEmpty);
      // The three notes of the lower voice (plus their stems) are spanned.
      expect(curves.first.getSpannedElements().length, greaterThanOrEqualTo(3));
    });
  });

  group('full pipeline property run', () {
    test('doc.layOut runs without crashing over ~30 corpus files', () {
      final files = Directory('test/corpus')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.mei'))
          .where((f) => !kNonUtf8CorpusFiles.contains(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      const int count = 30;
      var checked = 0;
      for (int i = 0; i < count; ++i) {
        final file = files[(i * files.length) ~/ count];
        final doc = Doc();
        final input = MeiInput(doc);
        final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
        if (!input.import(data)) continue;
        doc.prepareData();
        // The whole pipeline: cast-off, horizontal and vertical layout with
        // the floating positioner passes.
        doc.layOut(hasEncodedBreaks: false);
        checked++;
      }
      expect(checked, greaterThan(20));
    });
  });
}
