/// Parity of the beam adjustment functor against the instrumented C++
/// (`cpp_probe` task `04d`).
///
/// The C++ fixtures for the four pinned corpus files were extracted with
/// `cpp_probe/patches/04d.patch` (fprintf only, zero removed lines, SVG
/// byte-identical to the clean binary). Three families of comparisons run
/// here, all in epsilon 0:
///
/// 1. *Beam-level parity (synthetic tree).* For every fixture
///    `VisitBeam branch=top` record the test rebuilds the functor inputs —
///    the two segment extremes (`y1/y2/x1/x2`), the slope, the drawing place
///    and the beam widths — on a real [Beam] inside a small
///    doc/page/measure/staff/layer tree, runs the ported functor and compares
///    the captured state and the `VisitBeamEnd branch=applied` outputs
///    (`overlap_margin`, `y1_out`/`y2_out`, first/last coord overlap) with the
///    fixture values.
/// 2. *Element-level parity (synthetic tree).* For every fixture
///    `VisitLayerElement branch=evaluated` record (the clef-004 accidentals)
///    the test rebuilds the element bbox and compares the functor's
///    `m_overlapMargin` in/out around the visit.
/// 3. *Rest-level parity (synthetic tree).* For every fixture
///    `VisitRest branch=no_overlap` record (the beam-061 rests inside beams)
///    the test rebuilds the rest bbox and compares `beamIntersects` (the port
///    of the beam-aware `BoundingBox::Intersects`, boundingbox.cpp:781) and
///    the margin in/out.
///
/// The headless port still lacks `BeamSegment::CalcBeam` (pending task), so
/// in production the segment coord lists stay empty and the functor degrades
/// through the C++'s own empty-coords guard. The degradation itself is pinned
/// by the last group: after a full `doc.layOut()` of each corpus file, no
/// beam carries coord overlap margins and every `VisitBeam` took the skip
/// path — the same final outcome the C++ fixtures record (every `applied`
/// row has `overlap_margin == 0`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/adjust_beams.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Beamplace;
import 'package:verovio_dart/src/model/beam_segment.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04d';

const List<String> kCorpusFiles = <String>[
  'test/corpus/beam/beam-001.mei',
  'test/corpus/beam/beam-061.mei',
  'test/corpus/cross-staff/cross-staff-001.mei',
  'test/corpus/clef/clef-004.mei',
];

Doc loadCorpusDoc(String path) {
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final String data =
      utf8.decode(File(path).readAsBytesSync(), allowMalformed: true);
  final bool ok = input.import(data);
  if (!ok) throw StateError('MEI import rejected: $path');
  return doc;
}

Beamplace _placeOf(num place) => Beamplace.values[place.toInt()];

/// A doc/pages/page/system/measure/staff/layer tree with everything at the
/// origin, the smallest tree in which the functor runs for real.
Doc buildTree() {
  final Doc doc = Doc();
  final Pages pages = Pages();
  doc.addChild(pages);
  final Page page = Page();
  pages.addChild(page);
  final System system = System();
  page.addChild(system);
  final Measure measure = Measure();
  system.addChild(measure);
  final Staff staff = Staff();
  measure.addChild(staff);
  final Layer layer = Layer();
  staff.addChild(layer);
  return doc;
}

/// The [Page] of a tree built by [buildTree].
Page pageOf(Doc doc) =>
    (doc.children.first as Pages).children.first as Page;

/// The [Measure] of a tree built by [buildTree].
Measure measureOf(Doc doc) =>
    (pageOf(doc).children.first as System).children.first as Measure;

/// The [Layer] of a tree built by [buildTree].
Layer layerOf(Doc doc) =>
    (measureOf(doc).children.first as Staff).children.first as Layer;

/// Rebuilds the beam segment state of a fixture `VisitBeam branch=top`
/// record on [beam]: `ncoords` coords with the recorded first / last
/// extremes (middle coords linearly interpolated), slope, place and widths.
void populateBeamSegment(Beam beam, CppRecord record) {
  final int ncoords = record.require('ncoords').toInt();
  final int y1 = record.require('y1').toInt();
  final int y2 = record.require('y2').toInt();
  final int x1 = record.require('x1').toInt();
  final int x2 = record.require('x2').toInt();
  beam.drawingPlace = _placeOf(record.require('place'));
  beam.beamWidth = record.require('beam_width').toInt();
  beam.beamWidthBlack = record.require('beam_width_black').toInt();
  beam.beamSegment.beamSlope = record.require('slope').toDouble();
  final List<BeamElementCoord> coords = <BeamElementCoord>[];
  for (int i = 0; i < ncoords; ++i) {
    final double t = ncoords == 1 ? 0.0 : i / (ncoords - 1);
    coords.add(BeamElementCoord()
      ..x = (x1 + (x2 - x1) * t).round()
      ..yBeam = (y1 + (y2 - y1) * t).round()
      ..dur = MeiDuration.dur8);
  }
  beam.beamSegment.initCoordRefs(coords);
  // The C++ guard `!beam->GetChildCount()` (adjustbeamsfunctor.cpp:45) skips
  // beams without children: give the synthetic beam its notes back. They are
  // own-beam children for the functor (skip branch) — only their count
  // matters here.
  for (int i = 0; i < ncoords; ++i) {
    beam.addChild(Note());
  }
}

/// The ported functor instrumented the same way the C++ patch instruments the
/// original: captures, without touching it, the state before / after each
/// visit (`test/cpp_fixture_test.dart` pattern).
///
/// The synthetic trees hold a single beam / element each, so the fixture path
/// cannot be re-derived with [cppPath]; the test tags every object with its
/// fixture path in [tags] instead.
class _ProbedAdjustBeams extends AdjustBeamsFunctor {
  _ProbedAdjustBeams(super.doc);

  /// Fixture path per visited object (set by the test when building the
  /// tree); falls back to [cppPath].
  final Map<model.Object, String> tags = <model.Object, String>{};

  String _tagOf(model.Object object) => tags[object] ?? cppPath(object);

  /// `VisitBeam branch=top` outcome per beam path, after the visit.
  final Map<String, Map<String, int>> beamTop = <String, Map<String, int>>{};
  final Map<String, double> beamTopSlope = <String, double>{};

  /// `VisitBeamEnd branch=applied` outcome per beam path: the overlap margin
  /// written and the coord overlap values of the first / last coord.
  final Map<String, Map<String, int>> beamEnd = <String, Map<String, int>>{};

  /// The functor margin at `VisitBeamEnd` entry, read before the visit resets
  /// it (the C++ fixture records it as `overlap_margin`).
  int beamEndMargin = 0;

  /// `VisitLayerElement branch=evaluated` outcome per element path: the
  /// functor margin before / after the visit.
  final Map<String, Map<String, int>> elementMargin =
      <String, Map<String, int>>{};

  /// `VisitRest` outcome per rest path: margin before / after the visit.
  final Map<String, Map<String, int>> restMargin = <String, Map<String, int>>{};

  @override
  FunctorCode visitBeam(Beam beam) {
    final bool wasOuter = outerBeam == null;
    final FunctorCode code = super.visitBeam(beam);
    if (wasOuter && outerBeam == beam) {
      // The visit took the `top` branch and captured the segment state.
      final String path = _tagOf(beam);
      beamTop[path] = <String, int>{
        'y1': y1,
        'y2': y2,
        'x1': x1,
        'x2': x2,
        'bias': directionBias,
        'overlap_margin': overlapMargin,
      };
      beamTopSlope[path] = beamSlope;
    }
    return code;
  }

  @override
  FunctorCode visitBeamEnd(Beam beam) {
    final bool wasOuter = outerBeam == beam;
    beamEndMargin = overlapMargin;
    final FunctorCode code = super.visitBeamEnd(beam);
    if (wasOuter) {
      final List<BeamElementCoord> coords =
          beam.beamSegment.beamElementCoordRefs;
      beamEnd[_tagOf(beam)] = <String, int>{
        'overlap_margin': beamEndMargin,
        'y1_out': coords.isEmpty ? 0 : coords.first.yBeam,
        'y2_out': coords.isEmpty ? 0 : coords.last.yBeam,
        'first_coord_overlap': coords.isEmpty ? 0 : coords.first.overlapMargin,
        'last_coord_overlap': coords.isEmpty ? 0 : coords.last.overlapMargin,
      };
    }
    return code;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    final int before = overlapMargin;
    final FunctorCode code = super.visitLayerElement(layerElement);
    if (layerElement.classId == ClassId.accid && tags.containsKey(layerElement)) {
      elementMargin[tags[layerElement]!] = <String, int>{
        'overlap_margin_in': before,
        'overlap_margin_out': overlapMargin,
      };
    }
    return code;
  }

  @override
  FunctorCode visitRest(Rest rest) {
    final int before = overlapMargin;
    final FunctorCode code = super.visitRest(rest);
    if (tags.containsKey(rest)) {
      restMargin[tags[rest]!] = <String, int>{
        'overlap_margin_in': before,
        'overlap_margin_out': overlapMargin,
      };
    }
    return code;
  }
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
  });

  // ---------------------------------------------------------------------------
  // adjustOverlapToHalfUnit — the integer rounding the C++ fixtures could not
  // exercise (no record fires on the pinned corpus); expectations derived from
  // the C++ expression `(abs(overlap) + halfUnit/2) / halfUnit * halfUnit *
  // sign` with unit 45 (staffSize 100), checked by hand.
  // ---------------------------------------------------------------------------
  group('AdjustOverlapToHalfUnit — expressão do C++ (adjustbeamsfunctor.cpp:426)',
      () {
    final AdjustBeamsFunctor functor = AdjustBeamsFunctor(buildTree());
    final List<(int, int, int)> cases = <(int, int, int)>[
      (0, 45, 0),
      (10, 45, 0),
      (11, 45, 22),
      (22, 45, 22),
      (23, 45, 22),
      (33, 45, 44),
      (34, 45, 44),
      (556, 45, 550),
      (-10, 45, 0),
      (-11, 45, -22),
      (-556, 45, -550),
      (100, 45, 110),
    ];
    for (final (int overlap, int unit, int expected) in cases) {
      test('($overlap, $unit) -> $expected', () {
        expect(functor.adjustOverlapToHalfUnit(overlap, unit), expected);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Beam-level + element-level + rest-level parity over the four fixed files
  // ---------------------------------------------------------------------------
  for (final String path in kCorpusFiles) {
    final String name = path.split('/').last;
    group('ajuste de beams — $name', () {
      late CppFixture fixture;

      setUpAll(() {
        fixture = CppFixture.load(task, path);
      });

      test('o fixture tem a proveniência esperada', () {
        expect(fixture.meta.task, task);
        expect(fixture.meta.xmlIdSeed, 12345,
            reason: 'a semente fixa de cpp_probe/run.sh');
        expect(fixture.meta.patches, contains(task));
      });

      test(
          'VisitBeam top: extremos, slope, bias e margins batem com o C++ '
          '(epsilon 0)', () {
        // One record per beam and pass; the values repeat per pass, so the
        // first pass pins them all.
        final List<CppRecord> records = fixture
            .where(
                fn: 'AdjustBeams',
                test: (CppRecord rec) =>
                    rec['sub'] == 'VisitBeam' && rec['branch'] == 'top')
            .toList();
        final Map<String, CppRecord> byPath = <String, CppRecord>{};
        for (final CppRecord rec in records) {
          byPath.putIfAbsent(rec.path, () => rec);
        }
        if (byPath.isEmpty) {
          // cross-staff-001: every beam is mixed and requests staff space —
          // a legitimate C++ outcome, nothing to pin here.
          return;
        }

        int compared = 0;
        final List<String> divergences = <String>[];
        byPath.forEach((String path, CppRecord rec) {
          final Doc doc = buildTree();
          final Page page = pageOf(doc);
          final Layer layer = layerOf(doc);
          final Beam beam = Beam();
          layer.addChild(beam);
          populateBeamSegment(beam, rec);

          final _ProbedAdjustBeams functor = _ProbedAdjustBeams(doc);
          functor.tags[beam] = path;
          page.process(functor);

          final Map<String, int>? top = functor.beamTop[path];
          if (top == null) {
            divergences.add('$path: a visita não tomou o ramo top no Dart');
            return;
          }
          void expectField(String field, int actual) {
            ++compared;
            final int expected = rec.require(field).toInt();
            if (expected != actual) {
              divergences.add('$path.$field: C++ $expected, Dart $actual');
            }
          }

          expectField('y1', top['y1']!);
          expectField('y2', top['y2']!);
          expectField('x1', top['x1']!);
          expectField('x2', top['x2']!);
          expectField('bias', top['bias']!);
          expectField('overlap_margin', top['overlap_margin']!);
          // The C++ emits the CalcLayerOverlap return twice (dedicated field
          // and the resulting m_overlapMargin); the Dart degraded substitute
          // returns 0 for both (see adjust_beams.dart deviation note).
          ++compared;
          if (rec.require('calc_layer_overlap').toInt() !=
              top['overlap_margin']) {
            divergences.add('$path.calc_layer_overlap: C++ '
                '${rec.require('calc_layer_overlap')}, Dart '
                '${top['overlap_margin']}');
          }
          ++compared;
          final double slopeExpected = rec.require('slope').toDouble();
          final double slopeActual = functor.beamTopSlope[path] ?? double.nan;
          if ((slopeExpected - slopeActual).abs() > 1e-6) {
            divergences.add('$path.slope: C++ $slopeExpected, Dart '
                '$slopeActual');
          }
        });
        expect(compared, greaterThan(0));
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });

      test(
          'VisitBeamEnd applied: margem escrita nos coords e extremos imóveis '
          '(epsilon 0)', () {
        final List<CppRecord> records = fixture
            .where(
                fn: 'AdjustBeams',
                test: (CppRecord rec) =>
                    rec['sub'] == 'VisitBeamEnd' && rec['branch'] == 'applied')
            .toList();
        final Map<String, CppRecord> byPath = <String, CppRecord>{};
        for (final CppRecord rec in records) {
          byPath.putIfAbsent(rec.path, () => rec);
        }
        if (byPath.isEmpty) {
          // cross-staff-001: every beam is mixed and exits through
          // `not_outer` — a legitimate C++ outcome, nothing to pin here.
          return;
        }

        int compared = 0;
        final List<String> divergences = <String>[];
        byPath.forEach((String path, CppRecord rec) {
          final Doc doc = buildTree();
          final Page page = pageOf(doc);
          final Layer layer = layerOf(doc);
          final Beam beam = Beam();
          layer.addChild(beam);
          final List<CppRecord> tops = fixture
              .where(
                  fn: 'AdjustBeams',
                  path: path,
                  test: (CppRecord rec) =>
                      rec['sub'] == 'VisitBeam' && rec['branch'] == 'top')
              .toList();
          if (tops.isEmpty) return;
          populateBeamSegment(beam, tops.first);

          final _ProbedAdjustBeams functor = _ProbedAdjustBeams(doc);
          functor.tags[beam] = path;
          page.process(functor);

          final Map<String, int>? end = functor.beamEnd[path];
          if (end == null) {
            divergences.add('$path: a visita final não tomou o ramo applied');
            return;
          }
          void expectField(String field, int actual) {
            ++compared;
            final int expected = rec.require(field).toInt();
            if (expected != actual) {
              divergences.add('$path.$field: C++ $expected, Dart $actual');
            }
          }

          expectField('overlap_margin', end['overlap_margin']!);
          expectField('y1_out', end['y1_out']!);
          expectField('y2_out', end['y2_out']!);
          expectField('first_coord_overlap', end['first_coord_overlap']!);
          expectField('last_coord_overlap', end['last_coord_overlap']!);
        });
        expect(compared, greaterThan(0));
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });

      test(
          'VisitLayerElement evaluated: margem antes/depois bate com o C++ '
          '(epsilon 0)', () {
        final List<CppRecord> records = fixture
            .where(
                fn: 'AdjustBeams',
                test: (CppRecord rec) =>
                    rec['sub'] == 'VisitLayerElement' &&
                    rec['branch'] == 'evaluated' &&
                    rec['other_layer'] == 0)
            .toList();
        final Map<String, CppRecord> byPath = <String, CppRecord>{};
        for (final CppRecord rec in records) {
          byPath.putIfAbsent(rec.path, () => rec);
        }
        if (byPath.isEmpty) return;

        int compared = 0;
        final List<String> divergences = <String>[];
        byPath.forEach((String path, CppRecord rec) {
          // The evaluated elements of the corpus are accidentals attached to
          // a note inside the beam: rebuild the exact bbox the C++ saw.
          final List<String> segments = path.split('/');
          final String beamPath = segments.sublist(0, segments.length - 2).join('/');
          final List<CppRecord> tops = fixture
              .where(
                  fn: 'AdjustBeams',
                  path: beamPath,
                  test: (CppRecord rec) =>
                      rec['sub'] == 'VisitBeam' && rec['branch'] == 'top')
              .toList();
          if (tops.isEmpty) {
            divergences.add('$path: sem registro VisitBeam top para $beamPath');
            return;
          }

          final Doc doc = buildTree();
          final Page page = pageOf(doc);
          final Layer layer = layerOf(doc);
          final Beam beam = Beam();
          layer.addChild(beam);
          populateBeamSegment(beam, tops.first);
          final Note note = Note();
          beam.addChild(note);
          final Accid accid = Accid();
          note.addChild(accid);
          accid.drawingXRel = rec.require('x').toInt();
          // The note sits at the same x: its own-beam-child skip must not
          // depend on position.
          note.drawingXRel = 0;
          accid.updateContentBBoxX(
              rec.require('content_left').toInt(),
              rec.require('content_right').toInt());
          accid.updateContentBBoxY(
              rec.require('content_bottom').toInt(),
              rec.require('content_top').toInt());

          final _ProbedAdjustBeams functor = _ProbedAdjustBeams(doc);
          functor.tags[beam] = beamPath;
          functor.tags[accid] = path;
          page.process(functor);

          final Map<String, int>? margins = functor.elementMargin[path];
          if (margins == null) {
            divergences.add('$path: o elemento não foi avaliado no Dart');
            return;
          }
          void expectField(String field, int actual) {
            ++compared;
            final int expected = rec.require(field).toInt();
            if (expected != actual) {
              divergences.add('$path.$field: C++ $expected, Dart $actual');
            }
          }

          expectField('overlap_margin_in', margins['overlap_margin_in']!);
          expectField('overlap_margin_out', margins['overlap_margin_out']!);
        });
        expect(compared, greaterThan(0));
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });

      test(
          'VisitRest no_overlap: interseção e margem antes/depois batem com o '
          'C++ (epsilon 0)', () {
        final List<CppRecord> records = fixture
            .where(
                fn: 'AdjustBeams',
                test: (CppRecord rec) =>
                    rec['sub'] == 'VisitRest' &&
                    rec['branch'] == 'no_overlap')
            .toList();
        final Map<String, CppRecord> byPath = <String, CppRecord>{};
        for (final CppRecord rec in records) {
          byPath.putIfAbsent(rec.path, () => rec);
        }
        if (byPath.isEmpty) return;

        int compared = 0;
        final List<String> divergences = <String>[];
        byPath.forEach((String path, CppRecord rec) {
          final List<String> segments = path.split('/');
          final String beamPath = segments.sublist(0, segments.length - 1).join('/');
          final List<CppRecord> tops = fixture
              .where(
                  fn: 'AdjustBeams',
                  path: beamPath,
                  test: (CppRecord rec) =>
                      rec['sub'] == 'VisitBeam' && rec['branch'] == 'top')
              .toList();
          if (tops.isEmpty) {
            divergences.add('$path: sem registro VisitBeam top para $beamPath');
            return;
          }

          final Doc doc = buildTree();
          final Page page = pageOf(doc);
          final Layer layer = layerOf(doc);
          final Beam beam = Beam();
          layer.addChild(beam);
          populateBeamSegment(beam, tops.first);
          final Rest rest = Rest();
          beam.addChild(rest);
          rest.drawingXRel = rec.require('x').toInt();
          rest.updateContentBBoxX(rec.require('content_left').toInt(),
              rec.require('content_right').toInt());
          rest.updateContentBBoxY(rec.require('content_bottom').toInt(),
              rec.require('content_top').toInt());

          // Direct comparison of the ported `BoundingBox::Intersects`
          // overload with the C++ return.
          final int intersects = beamIntersects(rest, beam, Accessor.self,
              rec.require('beams').toInt() * rec.require('beam_width').toInt(),
              true);
          ++compared;
          final int expectedIntersects = rec.require('intersects').toInt();
          if (expectedIntersects != intersects) {
            divergences.add('$path.intersects: C++ $expectedIntersects, '
                'Dart $intersects');
          }

          final _ProbedAdjustBeams functor = _ProbedAdjustBeams(doc);
          functor.tags[beam] = beamPath;
          functor.tags[rest] = path;
          page.process(functor);

          final Map<String, int>? margins = functor.restMargin[path];
          if (margins == null) {
            divergences.add('$path: a pausa não foi visitada no Dart');
            return;
          }
          ++compared;
          if (margins['overlap_margin_in'] !=
              margins['overlap_margin_out']) {
            divergences.add('$path: a margem mudou no Dart '
                '(${margins['overlap_margin_in']} -> '
                '${margins['overlap_margin_out']}) mas o C++ registra '
                'no_overlap');
          }
        });
        expect(compared, greaterThan(0));
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });

      test(
          'degradação em produção: nenhum deslocamento após doc.layOut() '
          '(mesmo resultado do C++, margens todas 0)', () {
        final Doc doc = loadCorpusDoc(path);
        doc.prepareData();
        doc.layOut();

        int beams = 0;
        int displaced = 0;
        final _ProbedAdjustBeams probe = _ProbedAdjustBeams(doc);
        doc.process(probe);
        void checkBeam(model.Object object) {
          if (object is Beam) {
            ++beams;
            for (final BeamElementCoord coord
                in object.beamSegment.beamElementCoordRefs) {
              if (coord.overlapMargin != 0) ++displaced;
            }
          }
          for (final model.Object child in object.children) {
            checkBeam(child);
          }
        }

        checkBeam(doc);
        expect(beams, greaterThan(0));
        expect(displaced, 0,
            reason: 'sem CalcBeam os segmentos são vazios e o functor não '
                'pode deslocar nada; os fixtures do C++ registram '
                'overlap_margin == 0 para todos os beams destes arquivos');
      });
    });
  }
}
